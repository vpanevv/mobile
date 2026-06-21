import ActivityKit
import SwiftUI
import WidgetKit

struct ServiceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ServiceActivityAttributes.self) { context in
            lockScreen(context: context)
                .activityBackgroundTint(Color.black.opacity(0.35))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let tint = Color(sharedStatus: context.state.statusRawValue)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.carName)
                            .font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: context.state.symbolName)
                            .foregroundStyle(tint)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.remainingText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.title)
                        .font(.headline)
                }
            } compactLeading: {
                Image(systemName: context.state.symbolName)
                    .foregroundStyle(tint)
            } compactTrailing: {
                Text(context.state.remainingText)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(tint)
            } minimal: {
                Image(systemName: context.state.symbolName)
                    .foregroundStyle(tint)
            }
        }
    }

    private func lockScreen(context: ActivityViewContext<ServiceActivityAttributes>) -> some View {
        let tint = Color(sharedStatus: context.state.statusRawValue)
        return HStack(spacing: 14) {
            Image(systemName: context.state.symbolName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.title)
                    .font(.headline)
                Text(context.attributes.carName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.remainingText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(tint)
                Text("until due")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
