import ApplicationServices
import AppKit
import Foundation
import os.log

private let logger = Logger(subsystem: "com.karmafyapps.ChromeProfile", category: "BrowserProfileService")

@Observable
final class BrowserProfileService {
    private(set) var profilesByBrowser: [(browser: SupportedBrowser, profiles: [BrowserProfile])] = []
    private(set) var errorMessage: String?

    init() {
        loadAllProfiles()
    }

    func loadAllProfiles() {
        errorMessage = nil
        profilesByBrowser = []

        let activeBrowsers = SupportedBrowser.active
        guard !activeBrowsers.isEmpty else {
            errorMessage = "No browsers enabled"
            return
        }

        var results: [(browser: SupportedBrowser, profiles: [BrowserProfile])] = []
        for browser in activeBrowsers {
            let profiles = loadProfiles(for: browser)
            if !profiles.isEmpty {
                results.append((browser, profiles))
            }
        }

        profilesByBrowser = results

        if results.isEmpty {
            errorMessage = "No profiles found"
        }
    }

    private func loadProfiles(for browser: SupportedBrowser) -> [BrowserProfile] {
        let path = browser.localStatePath
        guard FileManager.default.fileExists(atPath: path) else { return [] }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let profileSection = json["profile"] as? [String: Any],
                  let infoCache = profileSection["info_cache"] as? [String: Any] else {
                return []
            }

            return infoCache.compactMap { (dirName, value) -> BrowserProfile? in
                guard let info = value as? [String: Any] else { return nil }
                let name = info["name"] as? String ?? ""
                let gaiaName = info["gaia_name"] as? String ?? ""
                return BrowserProfile(browser: browser, directoryName: dirName, name: name, gaiaName: gaiaName)
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        } catch {
            return []
        }
    }

    /// Checks whether the app has Accessibility permission and prompts if not.
    func requestAccessibilityIfNeeded() {
        let trusted = AXIsProcessTrusted()
        logger.info("Accessibility trusted: \(trusted)")
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    func openProfile(_ profile: BrowserProfile) {
        let bundleID = profile.browser.bundleIdentifier
        let profileDir = profile.directoryName

        logger.info("openProfile called — app: \(profile.browser.appName), profileDir: \(profileDir)")

        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        logger.info("Browser is running: \(!runningApps.isEmpty)")

        guard let app = runningApps.last else {
            // Browser is not running — launch with the profile.
            launchViaOpen(profile: profile)
            return
        }

        // Browser is running. If only one profile exists, just activate.
        let profileCount = profilesByBrowser
            .first(where: { $0.browser == profile.browser })?.profiles.count ?? 0

        if profileCount <= 1 {
            logger.info("Single profile — activating app")
            app.activate()
            return
        }

        // Multiple profiles — click the profile in Chrome's Profiles menu
        // via the Accessibility API. This focuses an existing window for
        // that profile or opens a new one (native Chrome behaviour).
        logger.info("Switching to profile via Accessibility: \(profile.displayName)")
        app.activate()

        if clickProfileMenuItem(pid: app.processIdentifier, profileName: profile.displayName) {
            logger.info("Profile menu click succeeded")
            return
        }

        // Accessibility approach failed — open a new window as fallback.
        logger.info("Profile menu click failed — opening new window")
        openNewWindow(for: profile)
    }

    // MARK: - Accessibility Menu Click

    /// Uses the AX API to click a profile name inside Chrome's "Profiles"
    /// (or "People") menu bar item.  Requires Accessibility permission.
    private func clickProfileMenuItem(pid: pid_t, profileName: String) -> Bool {
        guard AXIsProcessTrusted() else {
            logger.info("Accessibility not granted — prompting user")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return false
        }

        let appElement = AXUIElementCreateApplication(pid)

        // --- Get the menu bar ---
        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarRef) == .success else {
            logger.error("AX: could not get menu bar")
            return false
        }

        var itemsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(menuBarRef as! AXUIElement, kAXChildrenAttribute as CFString, &itemsRef) == .success,
              let menuBarItems = itemsRef as? [AXUIElement] else {
            logger.error("AX: could not get menu bar items")
            return false
        }

        // Log all top-level menu names for debugging.
        let menuNames = menuBarItems.compactMap { item -> String? in
            var t: CFTypeRef?
            AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &t)
            return t as? String
        }
        logger.info("AX menu bar items: \(menuNames.joined(separator: ", "))")

        // --- Find the "Profiles" or "People" menu ---
        for menuBarItem in menuBarItems {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(menuBarItem, kAXTitleAttribute as CFString, &titleRef)
            let title = titleRef as? String ?? ""

            guard title == "Profiles" || title == "People" else { continue }

            // Open the menu so its children become available.
            AXUIElementPerformAction(menuBarItem, kAXPressAction as CFString)
            usleep(150_000) // 150 ms for the menu to populate

            // The menu bar item's child is the menu itself.
            var subRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(menuBarItem, kAXChildrenAttribute as CFString, &subRef) == .success,
                  let subs = subRef as? [AXUIElement],
                  let menu = subs.first else {
                logger.error("AX: could not get submenu of \(title)")
                return false
            }

            var menuItemsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(menu, kAXChildrenAttribute as CFString, &menuItemsRef) == .success,
                  let menuItems = menuItemsRef as? [AXUIElement] else {
                logger.error("AX: could not get items inside \(title) menu")
                return false
            }

            // Log profile menu entries for debugging.
            let entryNames = menuItems.compactMap { mi -> String? in
                var t: CFTypeRef?
                AXUIElementCopyAttributeValue(mi, kAXTitleAttribute as CFString, &t)
                return t as? String
            }
            logger.info("AX \(title) menu entries: \(entryNames.joined(separator: ", "))")

            // Click the matching profile.
            for menuItem in menuItems {
                var itemTitleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(menuItem, kAXTitleAttribute as CFString, &itemTitleRef)
                let itemTitle = itemTitleRef as? String ?? ""

                if itemTitle == profileName {
                    AXUIElementPerformAction(menuItem, kAXPressAction as CFString)
                    return true
                }
            }

            // Profile not found — dismiss the menu.
            logger.info("Profile '\(profileName)' not in \(title) menu")
            AXUIElementPerformAction(menuBarItem, kAXCancelAction as CFString)
            return false
        }

        logger.info("No Profiles/People menu found in menu bar")
        return false
    }

    // MARK: - Fallback Launchers

    private func openNewWindow(for profile: BrowserProfile) {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: profile.browser.bundleIdentifier
        ) else {
            logger.error("Could not find app URL for \(profile.browser.appName)")
            launchViaOpen(profile: profile)
            return
        }
        let binaryURL = appURL.appendingPathComponent("Contents/MacOS/\(profile.browser.binaryName)")
        logger.info("Opening new window: \(binaryURL.path) --profile-directory=\(profile.directoryName)")
        let process = Process()
        process.executableURL = binaryURL
        process.arguments = ["--profile-directory=\(profile.directoryName)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            logger.error("Binary launch failed: \(error.localizedDescription)")
            launchViaOpen(profile: profile)
        }
    }

    private func launchViaOpen(profile: BrowserProfile) {
        logger.info("Launching via open -a: \(profile.browser.appName) --profile-directory=\(profile.directoryName)")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", profile.browser.appName, "--args", "--profile-directory=\(profile.directoryName)"]
        try? process.run()
    }
}
