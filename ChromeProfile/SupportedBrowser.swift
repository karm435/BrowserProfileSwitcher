import Foundation

enum SupportedBrowser: String, CaseIterable, Identifiable {
    case chrome, brave, edge, vivaldi, arc, opera, chromium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chrome:   "Google Chrome"
        case .brave:    "Brave Browser"
        case .edge:     "Microsoft Edge"
        case .vivaldi:  "Vivaldi"
        case .arc:      "Arc"
        case .opera:    "Opera"
        case .chromium: "Chromium"
        }
    }

    var appName: String { displayName }

    var binaryName: String {
        switch self {
        case .chrome:   "Google Chrome"
        case .brave:    "Brave Browser"
        case .edge:     "Microsoft Edge"
        case .vivaldi:  "Vivaldi"
        case .arc:      "Arc"
        case .opera:    "Opera"
        case .chromium: "Chromium"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .chrome:   "com.google.Chrome"
        case .brave:    "com.brave.Browser"
        case .edge:     "com.microsoft.edgemac"
        case .vivaldi:  "com.vivaldi.Vivaldi"
        case .arc:      "company.thebrowser.Browser"
        case .opera:    "com.operasoftware.Opera"
        case .chromium: "org.chromium.Chromium"
        }
    }

    var localStatePath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let relative: String = switch self {
        case .chrome:   "Google/Chrome/Local State"
        case .brave:    "BraveSoftware/Brave-Browser/Local State"
        case .edge:     "Microsoft Edge/Local State"
        case .vivaldi:  "Vivaldi/Local State"
        case .arc:      "company.thebrowser.Browser/Local State"
        case .opera:    "com.operasoftware.Opera/Local State"
        case .chromium: "Chromium/Local State"
        }
        return "\(home)/Library/Application Support/\(relative)"
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: localStatePath)
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: defaultsKey) as? Bool ?? true }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    var isActive: Bool { isInstalled && isEnabled }

    private var defaultsKey: String { "browserEnabled_\(rawValue)" }

    static var installed: [SupportedBrowser] { allCases.filter(\.isInstalled) }
    static var active: [SupportedBrowser] { allCases.filter(\.isActive) }
}
