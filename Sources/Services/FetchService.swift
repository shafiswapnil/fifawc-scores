import Foundation

/// Errors that can occur during API fetching.
enum FetchError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidAPIKey
    case networkError(Error)
    case rateLimited
    case serverError(Int)
    case decodingError(Error)
    case noData

    static func == (lhs: FetchError, rhs: FetchError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): true
        case (.invalidAPIKey, .invalidAPIKey): true
        case (.rateLimited, .rateLimited): true
        case (.noData, .noData): true
        case (.serverError(let a), .serverError(let b)): a == b
        case (.networkError, .networkError): true
        case (.decodingError, .decodingError): true
        default: false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .invalidAPIKey: "No API key — set one in Settings"
        case .networkError(let error): "Network error: \(error.localizedDescription)"
        case .rateLimited: "Rate limited — too many requests"
        case .serverError(let code): "Server error (\(code))"
        case .decodingError(let error): "Decoding error: \(error.localizedDescription)"
        case .noData: "No data received"
        }
    }
}

/// Lightweight API client for football-data.org v4.
/// Uses URLSession (no third-party dependencies).
/// Respects the 10 req/min free-tier limit with a simple request queue.
actor FetchService {

    // MARK: - Configuration

    private let baseURL = "https://api.football-data.org/v4"
    private let competitionCode = "WC"  // FIFA World Cup

    /// API key for football-data.org. Set via Settings.
    /// When empty, all fetch calls short-circuit with an error.
    private var apiKey: String

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Rate Limiting

    /// Tracks request timestamps to enforce the 10 req/min limit.
    private var requestTimestamps: [Date] = []
    private let maxRequestsPerMinute = 10

    /// Dynamic rate limit from API response headers.
    /// X-RequestsAvailable: remaining requests before 429.
    /// X-RequestCounter-Reset: seconds until the counter resets.
    private var remainingRequests: Int = 10
    private var resetInterval: TimeInterval = 60

    // MARK: - Init

    init(apiKey: String) {
        self.apiKey = apiKey

        // Use a non-shared session with NO disk cache.
        // URLSession.shared has a persistent on-disk cache that can serve
        // stale match data (e.g. TIMED status) even after the API reports
        // IN_PLAY. A dedicated session with .reloadIgnoringLocalCacheData
        // ensures every fetch hits the network for real-time accuracy.
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil  // No disk or memory cache
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Public API

    /// Update the API key at runtime (called when user sets it in Settings).
    func updateApiKey(_ key: String) {
        self.apiKey = key
    }

    /// Whether a valid API key is configured.
    var hasApiKey: Bool {
        !apiKey.isEmpty && apiKey != "REPLACE_WITH_YOUR_API_KEY"
    }

    /// Fetch all matches for a specific date.
    func fetchMatches(for date: Date) async throws -> [Match] {
        let dateString = formatDate(date)
        let url = try buildURL(path: "/competitions/\(competitionCode)/matches",
                               queryItems: [
                                   URLQueryItem(name: "dateFrom", value: dateString),
                                   URLQueryItem(name: "dateTo", value: dateString)
                               ])
        let response: MatchesResponse = try await fetch(url: url)
        return response.matches
    }

    /// Fetch matches for a date range (inclusive).
    func fetchMatches(from startDate: Date, to endDate: Date) async throws -> [Match] {
        let from = formatDate(startDate)
        let to = formatDate(endDate)
        let url = try buildURL(path: "/competitions/\(competitionCode)/matches",
                               queryItems: [
                                   URLQueryItem(name: "dateFrom", value: from),
                                   URLQueryItem(name: "dateTo", value: to)
                               ])
        let response: MatchesResponse = try await fetch(url: url)
        return response.matches
    }

    /// Fetch all group standings for the tournament.
    func fetchStandings() async throws -> [GroupStanding] {
        let url = try buildURL(path: "/competitions/\(competitionCode)/standings")
        let response: StandingsResponse = try await fetch(url: url)
        return response.standings
    }

    /// Fetch a single match by ID.
    func fetchMatch(id: Int) async throws -> Match {
        let url = try buildURL(path: "/matches/\(id)")
        return try await fetch(url: url)
    }

    // MARK: - Private

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw FetchError.invalidURL
        }
        return url
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        guard hasApiKey else {
            throw FetchError.invalidAPIKey
        }

        try await enforceRateLimit()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FetchError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchError.noData
        }

        // Record timestamp for rate limiting
        requestTimestamps.append(Date())

        // Read API rate-limit headers for smarter throttling.
        // See: https://docs.football-data.org/general/v4/lookup_tables.html
        if let available = httpResponse.value(forHTTPHeaderField: "X-RequestsAvailable"),
           let remaining = Int(available) {
            remainingRequests = remaining
        }
        if let reset = httpResponse.value(forHTTPHeaderField: "X-RequestCounter-Reset"),
           let seconds = Double(reset) {
            resetInterval = seconds
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw FetchError.decodingError(error)
            }
        case 429:
            throw FetchError.rateLimited
        default:
            throw FetchError.serverError(httpResponse.statusCode)
        }
    }

    /// Rate limiter: uses both local tracking and API response headers.
    /// The API returns X-RequestsAvailable and X-RequestCounter-Reset headers
    /// that tell us exactly how many requests remain and when the counter resets.
    private func enforceRateLimit() async {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        requestTimestamps = requestTimestamps.filter { $0 > oneMinuteAgo }

        // If the API told us we're low on requests, wait until reset
        if remainingRequests <= 2 {
            try? await Task.sleep(for: .seconds(resetInterval + 1))
            remainingRequests = maxRequestsPerMinute
            return
        }

        // Fallback: local sliding window check
        if requestTimestamps.count >= maxRequestsPerMinute {
            if let oldest = requestTimestamps.first {
                let waitTime = oldest.addingTimeInterval(60).timeIntervalSinceNow
                if waitTime > 0 {
                    try? await Task.sleep(for: .seconds(waitTime))
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)  // API uses UTC dates
        return formatter.string(from: date)
    }
}

// MARK: - API Response Models

/// Top-level response from the matches endpoint.
private struct MatchesResponse: Decodable {
    let matches: [Match]
}

/// Top-level response from the standings endpoint.
private struct StandingsResponse: Decodable {
    let standings: [GroupStanding]
}
