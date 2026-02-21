import Foundation

struct BrowserProfile: Identifiable {
    let browser: SupportedBrowser
    let directoryName: String  // e.g. "Default", "Profile 1"
    let name: String           // user-set profile name
    let gaiaName: String       // Google account name

    var id: String { "\(browser.rawValue)_\(directoryName)" }

    var displayName: String {
        if !gaiaName.isEmpty { return gaiaName }
        if !name.isEmpty { return name }
        return "Profile (\(directoryName))"
    }
}
