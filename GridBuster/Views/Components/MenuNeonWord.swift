import SwiftUI

/// A reusable neon-glowing text component with a premium shimmer effect.
struct MenuNeonWord: View {
    let text:         String
    let color:        Color
    let fontSize:     CGFloat
    let shimmerPhase: CGFloat

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer bloom
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .blur(radius: 30)
                .opacity(pulse ? 0.80 : 0.42)

            // Mid glow
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .blur(radius: 12)
                .opacity(0.65)

            // Tight inner glow
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color.opacity(0.55))
                .blur(radius: 4)

            // Crisp core
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: color, radius: 10, x: 0, y: 0)
                .overlay(
                    // Signature Neon Lime Shimmer (Top Layer)
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Theme.Palette.neonLime.opacity(0.85), location: 0.42),
                            .init(color: .white.opacity(0.95), location: 0.5),
                            .init(color: Theme.Palette.neonLime.opacity(0.85), location: 0.58),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .init(x: shimmerPhase - 0.45, y: 0),
                        endPoint: .init(x: shimmerPhase + 0.45, y: 1)
                    )
                    .mask(
                        Text(text)
                            .font(.system(size: fontSize, weight: .black, design: .rounded))
                    )
                )
        }
        .fixedSize(horizontal: true, vertical: false)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
