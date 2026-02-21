import SwiftUI

@main
struct ChromeProfileApp: App {
    @State private var service = ChromeProfileService()

    var body: some Scene {
        MenuBarExtra("Chrome Profiles", systemImage: "person.2.circle") {
            if let error = service.errorMessage {
                Text(error)
                    .foregroundStyle(.secondary)
            }

            ForEach(service.profiles) { profile in
                Button(profile.displayName) {
                    service.openProfile(profile)
                }
            }

            Divider()

            Button("Refresh Profiles") {
                service.loadProfiles()
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)
    }
}
