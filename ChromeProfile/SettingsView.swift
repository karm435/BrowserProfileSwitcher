import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Hotkey:", name: .toggleMenu)
        }
        .padding()
        .frame(width: 300)
    }
}
