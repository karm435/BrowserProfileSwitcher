import Foundation

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

    func openProfile(_ profile: BrowserProfile) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", profile.browser.appName, "--args", "--profile-directory=\(profile.directoryName)"]
        try? process.run()
    }
}
