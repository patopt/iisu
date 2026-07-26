import SwiftUI

/// The dark, saturated backdrop the whole frontend sits on.
struct BackgroundGradient: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            Color(hex: 0x0B0914)
            RadialGradient(
                colors: [settings.accent.color.opacity(0.35), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 620
            )
            RadialGradient(
                colors: [Color(hex: 0xFF00BF).opacity(0.22), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Frosted card used for tiles and rows.
struct GlassCard<Content: View>: View {
    var isHighlighted: Bool = false
    var cornerRadius: CGFloat = 18
    @ViewBuilder var content: Content

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? settings.accent.color : Color.white.opacity(0.10),
                        lineWidth: isHighlighted ? 2.5 : 1
                    )
            )
            .shadow(
                color: isHighlighted ? settings.accent.color.opacity(0.45) : .clear,
                radius: 14
            )
    }
}
