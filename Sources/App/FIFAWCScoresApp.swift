import SwiftUI
import Sparkle

/// App entry point. A menu bar agent (no Dock icon, `LSUIElement` in Info.plist)
/// with a `.window`-style `MenuBarExtra`.
@main
struct FIFAWCScoresApp: App {
    @State private var store = MatchStore()
    private let updaterController: SPUStandardUpdaterController

    init() {
        // Sparkle: automatic background checks enabled by default.
        // Feed URL is set via SUFeedURL in Info.plist → GitHub Releases API.
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
                .environment(store)
                .task {
                    store.startPolling()
                }
        } label: {
            MenuBarLabel()
                .environment(store)
        }
        .menuBarExtraStyle(.window)
    }
}
