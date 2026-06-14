import SwiftUI

/// The compact menu bar label. Shows the match status in the menu bar area.
struct MenuBarLabel: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("⚽")
                .font(.system(size: 13))
            Text("WC")
        }
    }
}
