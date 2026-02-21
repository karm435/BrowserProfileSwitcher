import SwiftUI
import KeyboardShortcuts

// MARK: - KeyboardShortcuts name

extension KeyboardShortcuts.Name {
    static let toggleMenu = Self("toggleMenu", default: .init(.p, modifiers: [.command, .shift]))
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
    private let service = ChromeProfileService()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "person.2.circle", accessibilityDescription: "Chrome Profiles")
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        KeyboardShortcuts.onKeyUp(for: .toggleMenu) { [weak self] in
            self?.statusItem.button?.performClick(nil)
        }
    }

    // MARK: NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        service.loadProfiles()

        if let error = service.errorMessage {
            let item = NSMenuItem(title: error, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        for profile in service.profiles {
            let item = NSMenuItem(title: profile.displayName, action: #selector(openProfile(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = profile
            menu.addItem(item)
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
        guard let profile = sender.representedObject as? ChromeProfile else { return }
        service.openProfile(profile)
    }

    @objc private func refreshProfiles() {
        service.loadProfiles()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
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
