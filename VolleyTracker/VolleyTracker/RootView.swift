import SwiftUI
import SwiftData

struct RootView: View {

    @Query(sort: \Coach.createdAt)
    private var coaches: [Coach]

    var body: some View {

        ZStack {
            if let coach = coaches.first {

                DashboardView(coach: coach)
                    .transition(
                        AnyTransition.opacity.combined(
                            with: .move(edge: .trailing)
                        )
                    )

            } else {

                ContentView()
                    .transition(
                        AnyTransition.opacity.combined(
                            with: .move(edge: .leading)
                        )
                    )
            }
        }
        .animation(
            Animation.easeInOut(duration: 0.35),
            value: coaches.count
        )
    }
}
