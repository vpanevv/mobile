import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack { // modern navigation in SwiftUI (iOS 16+)
            WelcomeView() // the first screen
        }
    }
}

#Preview {
    ContentView()
}
