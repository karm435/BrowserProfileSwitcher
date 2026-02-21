import SwiftUI
import KeyboardShortcuts

// MARK: - KeyboardShortcuts name

extension KeyboardShortcuts.Name {
    static let toggleMenu = Self("toggleMenu", default: .init(.p, modifiers: [.command, .shift]))

    // Cmd+Shift+1…9 for quick-launching profiles
    static let profile1 = Self("profile1", default: .init(.one, modifiers: [.command, .shift]))
    static let profile2 = Self("profile2", default: .init(.two, modifiers: [.command, .shift]))
    static let profile3 = Self("profile3", default: .init(.three, modifiers: [.command, .shift]))
    static let profile4 = Self("profile4", default: .init(.four, modifiers: [.command, .shift]))
    static let profile5 = Self("profile5", default: .init(.five, modifiers: [.command, .shift]))
    static let profile6 = Self("profile6", default: .init(.six, modifiers: [.command, .shift]))
    static let profile7 = Self("profile7", default: .init(.seven, modifiers: [.command, .shift]))
    static let profile8 = Self("profile8", default: .init(.eight, modifiers: [.command, .shift]))
    static let profile9 = Self("profile9", default: .init(.nine, modifiers: [.command, .shift]))

    static let profileShortcuts: [KeyboardShortcuts.Name] = [
        .profile1, .profile2, .profile3, .profile4, .profile5,
        .profile6, .profile7, .profile8, .profile9,
    ]
}

// MARK: - App

@main
struct ChromeProfileApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let service = BrowserProfileService()
    private var settingsWindow: NSWindow?
    private var flatProfiles: [BrowserProfile] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "person.2.circle", accessibilityDescription: "Browser Profiles")
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        KeyboardShortcuts.onKeyUp(for: .toggleMenu) { [weak self] in
            self?.statusItem.button?.performClick(nil)
        }

        registerProfileShortcuts()
    }

    private func registerProfileShortcuts() {
        for (index, name) in KeyboardShortcuts.Name.profileShortcuts.enumerated() {
            KeyboardShortcuts.onKeyUp(for: name) { [weak self] in
                self?.launchProfile(at: index)
            }
        }
    }

    private func launchProfile(at index: Int) {
        service.loadAllProfiles()
        let allProfiles = service.profilesByBrowser.flatMap(\.profiles)
        guard index < allProfiles.count else { return }
        service.openProfile(allProfiles[index])
    }

    // MARK: NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        flatProfiles = []

        service.loadAllProfiles()

        if let error = service.errorMessage {
            let item = NSMenuItem(title: error, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        for (index, group) in service.profilesByBrowser.enumerated() {
            if index > 0 || service.errorMessage != nil {
                menu.addItem(.separator())
            }

            // Browser header
            let header = NSMenuItem(title: group.browser.displayName, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            // Profiles
            for profile in group.profiles {
                let tag = flatProfiles.count
                flatProfiles.append(profile)

                let keyEquiv = tag < 9 ? "\(tag + 1)" : ""
                let item = NSMenuItem(title: "  \(profile.displayName)", action: #selector(openProfile(_:)), keyEquivalent: keyEquiv)
                if !keyEquiv.isEmpty {
                    item.keyEquivalentModifierMask = [.command, .shift]
                }
                item.target = self
                item.tag = tag
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "Refresh Profiles", action: #selector(refreshProfiles), keyEquivalent: "r")
        refreshItem.keyEquivalentModifierMask = .command
        refreshItem.target = self
        menu.addItem(refreshItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
    }

    // MARK: Actions

    @objc private func openProfile(_ sender: NSMenuItem) {
        let tag = sender.tag
        guard tag >= 0, tag < flatProfiles.count else { return }
        service.openProfile(flatProfiles[tag])
    }

    @objc private func refreshProfiles() {
        service.loadAllProfiles()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.contentViewController = NSHostingController(rootView: SettingsView())
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
