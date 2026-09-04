import SwiftUI
import SwiftData

@main
struct DogCompanionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Companion.self)
        #if targetEnvironment(macCatalyst)
        .defaultSize(width: 420, height: 780)
        #endif
    }
}
