import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var companions: [Companion]
    /// `false` on launch when SwiftData already has a companion → go straight to the timer page.
    @State private var showDogPicker = false

    var body: some View {
        Group {
            if let companion = companions.first, !showDogPicker {
                HomeView(
                    companion: companion,
                    onBackToDogPicker: { showDogPicker = true }
                )
            } else {
                CreationFlowView(
                    existingCompanionName: companions.first?.name,
                    onEnterFocusSession: { showDogPicker = false }
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Companion.self, inMemory: true)
}
