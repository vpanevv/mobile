import SwiftUI

extension View {
    /// Applies Liquid Glass, but falls back to a solid, high-contrast surface
    /// when Reduce Transparency or Increased Contrast is enabled — keeping
    /// content legible for those accessibility settings.
    ///
    /// - Parameters:
    ///   - shape: the clipping shape for the surface.
    ///   - tint: optional tint blended into the glass / fallback.
    ///   - overImagery: pass `true` for surfaces drawn over photos with light
    ///     text, so the fallback uses a dark scrim instead of a light fill.
    func adaptiveGlass<S: InsettableShape>(
        in shape: S = Capsule(),
        tint: Color? = nil,
        overImagery: Bool = false
    ) -> some View {
        modifier(AdaptiveGlassModifier(shape: shape, tint: tint, overImagery: overImagery))
    }
}

private struct AdaptiveGlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color?
    let overImagery: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private var usesFallback: Bool {
        reduceTransparency || contrast == .increased
    }

    func body(content: Content) -> some View {
        if usesFallback {
            content
                .background(solidFill, in: shape)
                .overlay(shape.strokeBorder(borderColor, lineWidth: contrast == .increased ? 1.5 : 1))
        } else {
            content.glassEffect(glass, in: shape)
        }
    }

    private var glass: Glass {
        if let tint {
            return .regular.tint(tint.opacity(0.22))
        }
        return .regular
    }

    private var solidFill: AnyShapeStyle {
        if overImagery {
            return AnyShapeStyle(Color.black.opacity(contrast == .increased ? 0.72 : 0.55))
        }
        if let tint {
            return AnyShapeStyle(tint.opacity(contrast == .increased ? 0.32 : 0.22))
        }
        return AnyShapeStyle(Color(.secondarySystemBackground))
    }

    private var borderColor: Color {
        if overImagery {
            return Color.white.opacity(contrast == .increased ? 0.5 : 0.25)
        }
        return Color.primary.opacity(contrast == .increased ? 0.55 : 0.16)
    }
}
