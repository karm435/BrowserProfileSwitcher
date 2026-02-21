import Foundation

struct ChromeProfile: Identifiable {
    let id: String       // directory name, e.g. "Default", "Profile 1"
    let name: String     // user-set profile name
    let gaiaName: String // Google account name

    var displayName: String {
        if !gaiaName.isEmpty { return gaiaName }
        if !name.isEmpty { return name }
        return "Profile (\(id))"
    }
}
