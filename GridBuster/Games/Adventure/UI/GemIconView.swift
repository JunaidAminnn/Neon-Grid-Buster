import SwiftUI

/// A SwiftUI Shape that replicates the high-fidelity facets of GemFactory gems.
struct GemShape: Shape {
    let gem: TargetGem
    var scale: CGFloat = 1.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height) * scale
        let cx = rect.midX
        let cy = rect.midY
        let h = size * 0.5
        let q = size * 0.25
        
        switch gem {
        case .emerald, .blueSapphire:
            path.move(to: CGPoint(x: cx - q, y: cy - h))
            path.addLine(to: CGPoint(x: cx + q, y: cy - h))
            path.addLine(to: CGPoint(x: cx + h, y: cy - q))
            path.addLine(to: CGPoint(x: cx + h, y: cy + q))
            path.addLine(to: CGPoint(x: cx, y: cy + h))
            path.addLine(to: CGPoint(x: cx - h, y: cy + q))
            path.addLine(to: CGPoint(x: cx - h, y: cy - q))
            path.closeSubpath()
            
        case .star:
            let points = 5
            let innerRadius = size * 0.22
            let outerRadius = size * 0.52
            for i in 0..<points * 2 {
                let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
                let r = (i % 2 == 0) ? outerRadius : innerRadius
                let p = CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            
        case .orangePentagon:
            path.move(to: CGPoint(x: cx, y: cy - h))
            path.addLine(to: CGPoint(x: cx + h, y: cy - q))
            path.addLine(to: CGPoint(x: cx + q, y: cy + h))
            path.addLine(to: CGPoint(x: cx - q, y: cy + h))
            path.addLine(to: CGPoint(x: cx - h, y: cy - q))
            path.closeSubpath()
            
        case .redRuby:
            path.move(to: CGPoint(x: cx - q, y: cy - h))
            path.addLine(to: CGPoint(x: cx + q, y: cy - h))
            path.addLine(to: CGPoint(x: cx + h, y: cy))
            path.addLine(to: CGPoint(x: cx, y: cy + h))
            path.addLine(to: CGPoint(x: cx - h, y: cy))
            path.closeSubpath()
        }
        
        return path
    }
}

/// A composite view that renders a glowing, multi-faceted gem icon.
struct GemIconView: View {
    let gem: TargetGem
    let size: CGFloat
    let isCleared: Bool
    
    private var color: Color { Theme.neonColor(gem.neonColor) }
    
    var body: some View {
        ZStack {
            // 1. Backing Outer Glow (Bloom)
            GemShape(gem: gem)
                .fill(color.opacity(isCleared ? 0.05 : 0.45))
                .blur(radius: isCleared ? 0 : 10)
                .scaleEffect(isCleared ? 1.0 : 1.25)
            
            // 2. High-intensity Edge Stroke (Vibrant Neon)
            GemShape(gem: gem)
                .stroke(color.opacity(isCleared ? 0.20 : 1.0), lineWidth: 2.2)
                .shadow(color: color.opacity(isCleared ? 0.1 : 0.95), radius: isCleared ? 0 : 5)

            // 3. Inner White Specular Ring (Thin)
            GemShape(gem: gem)
                .stroke(Color.white.opacity(isCleared ? 0.1 : 0.6), lineWidth: 0.8)
                .scaleEffect(0.94)
            
            // 4. Main Faceted Body (Solid neon based)
            GemShape(gem: gem)
                .fill(color.opacity(isCleared ? 0.20 : 1.0))
                .scaleEffect(0.88)
            
            // 5. Brilliant Inner Core (White sparkle)
            Circle()
                .fill(.white.opacity(isCleared ? 0.15 : 0.95))
                .frame(width: size * 0.22, height: size * 0.22)
                .blur(radius: isCleared ? 0 : 2)
                .shadow(color: .white.opacity(isCleared ? 0 : 0.8), radius: 4)

            // 5. Specular Shimmer (High contrast highlights)
            GemShape(gem: gem)
                .stroke(Color.white.opacity(isCleared ? 0.05 : 0.45), lineWidth: 0.8)
                .scaleEffect(0.82)
                .blendMode(.plusLighter)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color(red: 0.1, green: 0.1, blue: 0.2).ignoresSafeArea()
        
        VStack(spacing: 30) {
            ForEach(TargetGem.allCases, id: \.self) { gem in
                HStack(spacing: 30) {
                    GemIconView(gem: gem, size: 50, isCleared: false)
                    GemIconView(gem: gem, size: 50, isCleared: true)
                    Text(gem.rawValue.capitalized)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }
}
