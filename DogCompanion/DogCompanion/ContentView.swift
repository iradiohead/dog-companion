import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var companions: [Companion]

    var body: some View {
        Group {
            if let companion = companions.first {
                HomeView(companion: companion)
            } else {
                CreationFlowView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Companion.self, inMemory: true)
}
