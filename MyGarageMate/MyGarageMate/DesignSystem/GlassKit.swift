import SwiftUI

// MARK: - Glass card

/// The canonical Liquid Glass surface for grouped content.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Theme.Radius.card
    var tint: Color? = nil
    var padding: CGFloat = Theme.Spacing.l
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                glass,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }

    private var glass: Glass {
        if let tint {
            return .regular.tint(tint.opacity(0.22))
        }
        return .regular
    }
}

// MARK: - Glass chip / pill

/// A compact glass pill used for inline facts (mileage, engine, status, etc.).
struct GlassChip: View {
    var systemImage: String?
    var text: String
    var tint: Color = .primary
    var prominent: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.bold))
            }
            Text(text)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(tint))
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s)
        .glassEffect(
            prominent ? .regular.tint(tint) : .regular,
            in: Capsule()
        )
    }
}

// MARK: - Glass icon button

/// A circular Liquid Glass button for compact actions (photo edit, dismiss, etc.).
struct GlassIconButton: View {
    var systemImage: String
    var tint: Color = .primary
    var size: CGFloat = 44
    var action: () -> Void

    var body: some View {
        Button {
            HapticsManager.soft()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
        }
        .buttonStyle(.glass)
        .clipShape(Circle())
    }
}

// MARK: - Status badge

/// A glowing glass badge expressing a car's health status.
struct StatusBadge: View {
    let status: CarHealthStatus
    var compact: Bool = false

    var body: some View {
        Label(compact ? status.shortTitle : status.title, systemImage: status.symbolName)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(status.gradientTint, in: Capsule())
            .shadow(color: status.tint.opacity(0.4), radius: 10, y: 4)
    }
}

// MARK: - Section header

/// A consistent header for content sections, with an optional trailing accessory.
struct SectionHeader<Accessory: View>: View {
    let title: String
    var systemImage: String?
    var subtitle: String?
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Label {
                    Text(title)
                } icon: {
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                }
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: Theme.Spacing.s)

            accessory
        }
    }
}

extension SectionHeader where Accessory == EmptyView {
    init(_ title: String, systemImage: String? = nil, subtitle: String? = nil) {
        self.init(title: title, systemImage: systemImage, subtitle: subtitle) { EmptyView() }
    }
}

// MARK: - Glass segmented control

/// A Liquid Glass segmented control with a spring-animated selection pill.
struct GlassSegmentedControl<T: Hashable>: View {
    let items: [T]
    let title: (T) -> String
    @Binding var selection: T
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = item == selection
                Button {
                    HapticsManager.selection()
                    withAnimation(Motion.spring) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(Color.secondary))
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Theme.accent.gradient)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Backwards-compatible shim

/// Legacy wrapper kept so existing call sites adopt Liquid Glass automatically.
/// New code should use `GlassCard` directly.
struct GlassCardView<Content: View>: View {
    var cornerRadius: CGFloat = Theme.Radius.card
    @ViewBuilder var content: Content

    var body: some View {
        GlassCard(cornerRadius: cornerRadius) { content }
    }
}
