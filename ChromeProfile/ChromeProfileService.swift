import Foundation

@Observable
final class ChromeProfileService {
    private(set) var profiles: [ChromeProfile] = []
    private(set) var errorMessage: String?

    private let localStatePath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/Google/Chrome/Local State"
    }()

    init() {
        loadProfiles()
    }

    func loadProfiles() {
        errorMessage = nil
        profiles = []

        guard FileManager.default.fileExists(atPath: localStatePath) else {
            errorMessage = "Chrome Local State file not found"
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: localStatePath))
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let profileSection = json["profile"] as? [String: Any],
                  let infoCache = profileSection["info_cache"] as? [String: Any] else {
                errorMessage = "Could not parse Local State JSON"
                return
            }

            profiles = infoCache.compactMap { (dirName, value) -> ChromeProfile? in
                guard let info = value as? [String: Any] else { return nil }
                let name = info["name"] as? String ?? ""
                let gaiaName = info["gaia_name"] as? String ?? ""
                return ChromeProfile(id: dirName, name: name, gaiaName: gaiaName)
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

        } catch {
            errorMessage = "Failed to read Local State: \(error.localizedDescription)"
        }
    }

    func openProfile(_ profile: ChromeProfile) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", "Google Chrome", "--args", "--profile-directory=\(profile.id)"]
        try? process.run()
    }
}
