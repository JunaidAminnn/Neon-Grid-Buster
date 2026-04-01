//
//  GemFactory.swift
//  NeonGridBuster
//
//  A central factory for generating high-fidelity, multi-faceted gem shapes.
//

import SpriteKit

struct GemFactory {
    
    /// Creates a high-fidelity gem shape node with a multi-faceted appearance.
    static func makeGemShapeNode(for gem: TargetGem, size: CGFloat) -> SKShapeNode {
        let node = SKShapeNode()
        let h = size * 0.5
        let q = size * 0.25 // quarter
        
        switch gem {
        case .emerald, .blueSapphire: // Diamond/Hexagon Hybrid (Ruby style)
            let path = CGMutablePath()
            // Top facet
            path.move(to: CGPoint(x: -q, y: h))
            path.addLine(to: CGPoint(x: q, y: h))
            // Sides
            path.addLine(to: CGPoint(x: h, y: q))
            path.addLine(to: CGPoint(x: h, y: -q))
            // Bottom point
            path.addLine(to: CGPoint(x: 0, y: -h))
            // Left sides
            path.addLine(to: CGPoint(x: -h, y: -q))
            path.addLine(to: CGPoint(x: -h, y: q))
            path.closeSubpath()
            node.path = path
            
        case .star: // Sharp 5-pointed star
            let path = CGMutablePath()
            let points = 5
            let innerRadius = size * 0.22
            let outerRadius = size * 0.52
            
            for i in 0..<points * 2 {
                let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
                let r = (i % 2 == 0) ? outerRadius : innerRadius
                let p = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            node.path = path
            
        case .orangePentagon: // Shield/Pentagon shape
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: h, y: q))
            path.addLine(to: CGPoint(x: q, y: -h))
            path.addLine(to: CGPoint(x: -q, y: -h))
            path.addLine(to: CGPoint(x: -h, y: q))
            path.closeSubpath()
            node.path = path
            
        case .redRuby: // Classic Heart/Ruby cut
            let path = CGMutablePath()
            // Flat top with slight taper
            path.move(to: CGPoint(x: -q, y: h))
            path.addLine(to: CGPoint(x: q, y: h))
            // Wide middle
            path.addLine(to: CGPoint(x: h, y: 0))
            // Pointy bottom
            path.addLine(to: CGPoint(x: 0, y: -h))
            // Wide middle left
            path.addLine(to: CGPoint(x: -h, y: 0))
            path.closeSubpath()
            node.path = path
        }
        
        return node
    }
}
