//
//  BlockNode.swift
//  NeonGridBuster
//

import SpriteKit

final class BlockNode: SKNode {
    let shape: BlockShape
    let color: NeonColor
    let cellSize: CGFloat

    private struct CellLayers {
        var fill: SKShapeNode
        var darkEdge: SKShapeNode
        var neonRing: SKShapeNode
    }

    private var cells: [CellLayers] = []

    init(shape: BlockShape, color: NeonColor, cellSize: CGFloat) {
        self.shape = shape
        self.color = color
        self.cellSize = cellSize
        super.init()
        isUserInteractionEnabled = false
        build()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    private func build() {
        let corner = cellSize * 0.22
        let rectSize = CGSize(width: cellSize * 0.90, height: cellSize * 0.90)

        for cell in shape.cells {
            let container = SKNode()
            container.position = CGPoint(x: (CGFloat(cell.x) + 0.5) * cellSize, y: (CGFloat(cell.y) + 0.5) * cellSize)
            container.zPosition = 1
            addChild(container)

            let fillNode = SKShapeNode(rectOf: rectSize, cornerRadius: corner)
            fillNode.fillColor = SKColor.neon(color).withAlphaComponent(0.55)
            fillNode.strokeColor = .clear
            fillNode.lineWidth = 0
            fillNode.zPosition = 1
            container.addChild(fillNode)

            let darkEdge = SKShapeNode(rectOf: rectSize, cornerRadius: corner)
            darkEdge.fillColor = .clear
            darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.35)
            darkEdge.lineWidth = max(1.0, cellSize * 0.06)
            darkEdge.glowWidth = 0
            darkEdge.zPosition = 2
            container.addChild(darkEdge)

            let neonRing = SKShapeNode(rectOf: rectSize, cornerRadius: corner)
            neonRing.fillColor = .clear
            neonRing.strokeColor = SKColor.neon(color).withAlphaComponent(0.95)
            neonRing.lineWidth = max(1.0, cellSize * 0.07)
            neonRing.glowWidth = 0
            neonRing.zPosition = 3
            container.addChild(neonRing)

            cells.append(CellLayers(fill: fillNode, darkEdge: darkEdge, neonRing: neonRing))
        }
    }

    func setGhostStyle(isValid: Bool) {
        let base = isValid ? SKColor.systemGreen : SKColor.systemRed
        for c in cells {
            c.fill.fillColor = base.withAlphaComponent(0.08)
            c.darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.30)
            c.neonRing.strokeColor = base.withAlphaComponent(0.85)
        }
        alpha = 0.85
    }

    func setTrayStyle() {
        for c in cells {
            c.fill.fillColor = SKColor.neon(color).withAlphaComponent(0.55)
            c.darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.35)
            c.neonRing.strokeColor = SKColor.neon(color).withAlphaComponent(0.95)
        }
        alpha = 1.0
    }

    func setDimmed(_ dimmed: Bool) {
        run(.fadeAlpha(to: dimmed ? 0.25 : 1.0, duration: 0.10), withKey: "dim")
    }

    func pulseSelected(_ selected: Bool) {
        removeAction(forKey: "pulse")
        if selected {
            let up = SKAction.scale(to: 1.06, duration: 0.13)
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
