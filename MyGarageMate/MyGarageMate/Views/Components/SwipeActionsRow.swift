import SwiftUI

/// A row that hides edit/delete actions until the user swipes left to reveal
/// them — mirroring the standard iOS list swipe affordance, but usable inside
/// a plain ScrollView/VStack (where `.swipeActions` does nothing).
struct SwipeActionsRow<Content: View>: View {
    var onEdit: () -> Void
    var onDelete: () -> Void
    @ViewBuilder var content: Content

    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0

    private let buttonWidth: CGFloat = 60
    private let spacing: CGFloat = Theme.Spacing.s
    private var revealWidth: CGFloat { buttonWidth * 2 + spacing * 2 }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: spacing) {
                actionButton(systemName: "pencil", tint: .blue, label: "Edit") {
                    close()
                    onEdit()
                }
                actionButton(systemName: "trash", tint: .red, label: "Delete") {
                    close()
                    onDelete()
                }
            }
            .frame(maxHeight: .infinity)
            .opacity(offset < -4 ? 1 : 0)

            content
                .contentShape(Rectangle())
                .onTapGesture {
                    if offset != 0 { close() }
                }
                .highPriorityGesture(dragGesture)
                // Offset must be outermost so the gesture/tap hit regions move
                // with the visual; otherwise the content keeps intercepting
                // taps over the revealed buttons.
                .offset(x: offset)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .animation(Motion.snappy, value: offset)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                // Only react to predominantly-horizontal drags so vertical
                // scrolling still works.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let proposed = lastOffset + value.translation.width
                offset = min(0, max(-revealWidth, proposed))
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) || offset != 0 else { return }
                if offset < -revealWidth * 0.5 {
                    offset = -revealWidth
                    HapticsManager.soft()
                } else {
                    offset = 0
                }
                lastOffset = offset
            }
    }

    private func close() {
        offset = 0
        lastOffset = 0
    }

    private func actionButton(systemName: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.soft()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: buttonWidth)
                .frame(maxHeight: .infinity)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
