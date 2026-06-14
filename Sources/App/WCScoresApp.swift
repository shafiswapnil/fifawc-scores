import SwiftUI

/// App entry point. A menu bar agent (no Dock icon, `LSUIElement` in Info.plist)
/// with a `.window`-style `MenuBarExtra`.
@main
struct WCScoresApp: App {
    @State private var store = MatchStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
        .environment(store)
        .task {
            store.startPolling()
        }
    }
}
