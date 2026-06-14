import SwiftUI

/// The `.window`-style panel shown when the menu bar item is clicked.
struct MenuBarPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider().opacity(0.5)
            placeholderContent
            Divider().opacity(0.5)
            footer
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(width: 340)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FIFA WORLD CUP 2026")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text("⚽ Coming Soon")
                .font(.title3.weight(.semibold))
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Placeholder

    private var placeholderContent: some View {
        VStack(spacing: 8) {
            Text("Match data will appear here")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Connect to football-data.org to see live scores")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 1) {
            Button { } label: {
                footerLabel("Sync", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)
            .menuRowHighlight()

            Button { NSApplication.shared.terminate(nil) } label: {
                footerLabel("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)
            .menuRowHighlight()
        }
        .font(.callout)
    }

    private func footerLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
    }
}

// MARK: - Menu Row Highlight

private struct MenuRowHighlight: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hovering ? Color.primary.opacity(0.1) : .clear)
            )
            .onHover { hovering = $0 }
    }
}

private extension View {
    func menuRowHighlight() -> some View { modifier(MenuRowHighlight()) }
}
