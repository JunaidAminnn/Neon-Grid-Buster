//
//  BlockNode.swift
//  NeonGridBuster
//
//  Prompt 4.1 — 3D beveled block appearance replicating image_4.png.
//  Each cell now has 5 layers:
//    1. Base fill (solid neon tint, opaque)
//    2. Bevel highlight (top-left white gradient overlay — gives 3D depth)
//    3. Bevel shadow  (bottom-right dark overlay — ground shadow)
//    4. Dark border ring (thin black inner edge)
//    5. Neon glow ring (coloured outer stroke)
//

import SpriteKit

final class BlockNode: SKNode {
    let shape:    BlockShape
    let color:    NeonColor
    let cellSize: CGFloat

    private struct CellLayers {
        var fill:      SKShapeNode
        var highlight: SKShapeNode   // bevel top-left
        var shadow:    SKShapeNode   // bevel bottom-right
        var darkEdge:  SKShapeNode
        var neonRing:  SKShapeNode
    }

    private var cells: [CellLayers] = []
    private(set) var gem: TargetGem?

    init(shape: BlockShape, color: NeonColor, cellSize: CGFloat, gem: TargetGem? = nil) {
        self.shape    = shape
        self.color    = color
        self.cellSize = cellSize
        self.gem      = gem
        super.init()
        isUserInteractionEnabled = false
        build()
    }

    required init?(coder aDecoder: NSCoder) { return nil }

    // MARK: - Build

    private func build() {
        let corner   = cellSize * 0.20
        let fullSize = CGSize(width: cellSize * 0.90, height: cellSize * 0.90)
        let bevelW   = max(1.5, cellSize * 0.12)   // bevel stripe thickness

        for (idx, cell) in shape.cells.enumerated() {
            let container = SKNode()
            container.position = CGPoint(
                x: (CGFloat(cell.x) + 0.5) * cellSize,
                y: (CGFloat(cell.y) + 0.5) * cellSize
            )
            container.zPosition = 1
            addChild(container)

            // ── Layer 1: Solid base fill ──────────────────────────────────
            let fillNode = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
            fillNode.fillColor   = SKColor.neon(color).withAlphaComponent(0.82)
            fillNode.strokeColor = .clear
            fillNode.lineWidth   = 0
            fillNode.zPosition   = 1
            container.addChild(fillNode)

            // ── Layer 2: Bevel highlight (top-left strip) ─────────────────
            let hiSize = CGSize(width: fullSize.width, height: fullSize.height)
            let highlight = SKShapeNode(rectOf: hiSize, cornerRadius: corner)
            highlight.fillColor   = SKColor(white: 1.0, alpha: 0.28)
            highlight.strokeColor = .clear
            highlight.lineWidth   = 0
            highlight.zPosition   = 2
            highlight.position = CGPoint(x: -bevelW * 0.5, y: bevelW * 0.5)
            highlight.blendMode = .add
            container.addChild(highlight)

            // ── Layer 3: Bevel shadow (bottom-right strip) ────────────────
            let shadowNode = SKShapeNode(rectOf: hiSize, cornerRadius: corner)
            shadowNode.fillColor   = SKColor(white: 0.0, alpha: 0.32)
            shadowNode.strokeColor = .clear
            shadowNode.lineWidth   = 0
            shadowNode.zPosition   = 2
            shadowNode.position = CGPoint(x: bevelW * 0.5, y: -bevelW * 0.5)
            container.addChild(shadowNode)

            // ── Layer 4: Dark inner border ────────────────────────────────
            let darkEdge = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
            darkEdge.fillColor   = .clear
            darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.40)
            darkEdge.lineWidth   = max(1.0, cellSize * 0.05)
            darkEdge.glowWidth   = 0
            darkEdge.zPosition   = 3
            container.addChild(darkEdge)

            // ── Layer 5: Neon glow ring ───────────────────────────────────
            let neonRing = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
            neonRing.fillColor   = .clear
            neonRing.strokeColor = SKColor.neon(color).withAlphaComponent(0.90)
            neonRing.lineWidth   = max(1.0, cellSize * 0.065)
            neonRing.glowWidth   = max(1.0, cellSize * 0.08)    // subtle neon bloom
            neonRing.zPosition   = 4
            container.addChild(neonRing)

            // ── Layer 6: Embedded Gem (Adventure Mode) ────────────────────
            if idx == 0, let g = gem {
                let gemColor = SKColor.neon(g.neonColor)
                
                // Outer glow bloom
                let glow = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
                glow.fillColor = gemColor.withAlphaComponent(0.20)
                glow.strokeColor = .clear
                glow.glowWidth = 8
                glow.zPosition = 10
                container.addChild(glow)
                
                // Crystal shape
                let gemNode = GemFactory.makeGemShapeNode(for: g, size: cellSize * 0.72)
                gemNode.fillColor = gemColor.withAlphaComponent(1.0)
                gemNode.strokeColor = .white
                gemNode.lineWidth = 1.0
                gemNode.zPosition = 11
                container.addChild(gemNode)
                
                // Inner core sparkle
                let core = SKShapeNode(circleOfRadius: cellSize * 0.12)
                core.fillColor = .white
                core.strokeColor = .clear
                core.glowWidth = 2
                core.zPosition = 12
                container.addChild(core)
            }

            cells.append(CellLayers(
                fill:      fillNode,
                highlight: highlight,
                shadow:    shadowNode,
                darkEdge:  darkEdge,
                neonRing:  neonRing
            ))
        }
    }

    // MARK: - Style Overrides

    func setGhostStyle(isValid: Bool) {
        let base = isValid ? SKColor.systemGreen : SKColor.systemRed
        for c in cells {
            c.fill.fillColor      = base.withAlphaComponent(0.10)
            c.highlight.fillColor = SKColor.clear
            c.shadow.fillColor    = SKColor.clear
            c.darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.20)
            c.neonRing.strokeColor = base.withAlphaComponent(0.80)
            c.neonRing.glowWidth   = 0
        }
        alpha = 0.85
    }

    func setTrayStyle() {
        for c in cells {
            c.fill.fillColor      = SKColor.neon(color).withAlphaComponent(0.82)
            c.highlight.fillColor = SKColor(white: 1.0, alpha: 0.28)
            c.shadow.fillColor    = SKColor(white: 0.0, alpha: 0.32)
            c.darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.40)
            c.neonRing.strokeColor = SKColor.neon(color).withAlphaComponent(0.90)
            c.neonRing.glowWidth   = max(1.0, cellSize * 0.08)
        }
        alpha = 1.0
    }

    func setDimmed(_ dimmed: Bool) {
        run(.fadeAlpha(to: dimmed ? 0.25 : 1.0, duration: 0.10), withKey: "dim")
    }

    func pulseSelected(_ selected: Bool) {
        removeAction(forKey: "pulse")
        if selected {
            let up   = SKAction.scale(to: 1.06, duration: 0.13)
            up.timingMode = .easeOut
            let down = SKAction.scale(to: 1.00, duration: 0.16)
            down.timingMode = .easeInEaseOut
            run(.repeatForever(.sequence([up, down])), withKey: "pulse")
        } else {
            run(.scale(to: 1.0, duration: 0.10))
        }
    }

    func boundingSize() -> CGSize {
        CGSize(width: CGFloat(shape.width) * cellSize, height: CGFloat(shape.height) * cellSize)
    }
}
