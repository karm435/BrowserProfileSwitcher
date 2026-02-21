import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Browsers") {
                ForEach(SupportedBrowser.allCases) { browser in
                    BrowserToggleRow(browser: browser)
                }
            }
            Section("Shortcut") {
                KeyboardShortcuts.Recorder("Hotkey:", name: .toggleMenu)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

private struct BrowserToggleRow: View {
    let browser: SupportedBrowser
    @State private var isEnabled: Bool

    init(browser: SupportedBrowser) {
        self.browser = browser
        self._isEnabled = State(initialValue: browser.isEnabled)
    }

    var body: some View {
        HStack {
            Toggle(browser.displayName, isOn: $isEnabled)
                .disabled(!browser.isInstalled)
                .onChange(of: isEnabled) { _, newValue in
                    browser.isEnabled = newValue
                }
            if !browser.isInstalled {
                Text("Not installed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
