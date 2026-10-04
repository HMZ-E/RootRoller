import SwiftUI

@main
struct RootRollerApp: App {
    @AppStorage("appAppearance") private var appearance = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            JackpotHubView()
                .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
        }
    }
}
