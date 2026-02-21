import SwiftUI
import ServiceManagement
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }
            KeyboardTab()
                .tabItem { Label("Keyboard", systemImage: "keyboard") }
            BrowsersTab()
                .tabItem { Label("Browsers", systemImage: "globe") }
        }
        .frame(width: 400, height: 380)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var updateChecker = UpdateChecker()

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }

            Divider()

            HStack {
                Button("Check for Updates") {
                    Task { await updateChecker.checkForUpdate() }
                }
                .disabled(updateChecker.status == .checking)

                switch updateChecker.status {
                case .idle:
                    EmptyView()
                case .checking:
                    ProgressView()
                        .controlSize(.small)
                case .upToDate:
                    Text("You're up to date!")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                case .available(let version, let url):
                    Text("v\(version) available —")
                        .font(.callout)
                    Link("Download", destination: url)
                        .font(.callout)
                case .error(let message):
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .checkForUpdates)) { _ in
            Task { await updateChecker.checkForUpdate() }
        }
    }
}

// MARK: - Keyboard

private struct KeyboardTab: View {
    var body: some View {
        Form {
            Section("Menu") {
                KeyboardShortcuts.Recorder("Toggle Menu:", name: .toggleMenu)
            }
            Section("Profiles") {
                ForEach(Array(KeyboardShortcuts.Name.profileShortcuts.enumerated()), id: \.offset) { index, name in
                    KeyboardShortcuts.Recorder("Profile \(index + 1):", name: name)
                }
            }
        }
        .padding()
    }
}

// MARK: - Browsers

private struct BrowsersTab: View {
    var body: some View {
        Form {
            ForEach(SupportedBrowser.allCases) { browser in
                BrowserToggleRow(browser: browser)
            }
        }
        .padding()
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
