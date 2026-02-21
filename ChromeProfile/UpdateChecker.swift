import Foundation

extension Notification.Name {
    static let checkForUpdates = Notification.Name("checkForUpdates")
}

@Observable
final class UpdateChecker {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, url: URL)
        case error(String)
    }

    private(set) var status: Status = .idle

    private static let repo = "karm435/BrowserProfileSwitcher"

    func checkForUpdate() async {
        status = .checking

        let urlString = "https://api.github.com/repos/\(Self.repo)/releases/latest"
        guard let url = URL(string: urlString) else {
            status = .error("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                status = .error("Could not reach GitHub (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))")
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            if compareVersions(remoteVersion, isNewerThan: currentVersion) {
                let downloadURL = release.assets.first(where: { $0.name.hasSuffix(".dmg") })?.browserDownloadURL
                    ?? release.htmlURL
                status = .available(version: remoteVersion, url: downloadURL)
            } else {
                status = .upToDate
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// Simple semantic version comparison (major.minor.patch).
    private func compareVersions(_ remote: String, isNewerThan local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}

// MARK: - GitHub API models

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL
    let assets: [Asset]

    struct Asset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }
}
