import SwiftUI

/// The frosted surface every iiSU control sits on.
///
/// mizu builds this from a translucent wash plus a bright inset rim; the rim is
/// what makes it read as glass rather than as a flat grey card, so it is drawn
/// as a gradient stroke rather than a plain border.
struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat = Theme.Radius.lg
    var strong: Bool = false
    var highlighted: Bool = false
    var accent: Color = Theme.gradient3

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: shape)
            .background(strong ? Theme.glassFillStrong : Theme.glassFill, in: shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .overlay {
                if highlighted {
                    shape.strokeBorder(accent, lineWidth: 2.5)
                }
            }
            .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
            .shadow(color: highlighted ? accent.opacity(0.55) : .clear, radius: 14)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

extension View {
    func glass(
        cornerRadius: CGFloat = Theme.Radius.lg,
        strong: Bool = false,
        highlighted: Bool = false,
        accent: Color = Theme.gradient3
    ) -> some View {
        modifier(
            GlassSurface(
                cornerRadius: cornerRadius,
                strong: strong,
                highlighted: highlighted,
                accent: accent
            )
        )
    }
}

/// Rounded capsule used for the status bar, the dock and the button hints.
struct GlassPill<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glass(cornerRadius: Theme.Radius.full)
    }
}

/// `Ⓐ Select`-style controller hint, as used along the bottom of the app.
struct ButtonHint: View, Identifiable {
    let glyph: String
    let label: String

    var id: String { glyph + label }

    var body: some View {
        HStack(spacing: 6) {
            Text(glyph)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().strokeBorder(Color.white.opacity(0.75), lineWidth: 1.5))
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

/// Row of hints wrapped in a single pill, matching the app's corner clusters.
struct ButtonHintBar: View {
    let hints: [ButtonHint]

    init(_ hints: [ButtonHint]) {
        self.hints = hints
    }

    var body: some View {
        GlassPill {
            HStack(spacing: 14) {
                ForEach(hints) { hint in
                    hint
                }
            }
        }
    }
}

/// Small shoulder-button tag (LB / RB / LT / RT) pinned above a pill.
struct ShoulderTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundColor(Theme.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .glass(cornerRadius: Theme.Radius.xxs)
    }
}
