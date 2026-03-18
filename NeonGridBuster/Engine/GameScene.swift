//
//  GameScene.swift
//  NeonGridBuster
//

import SpriteKit
import UIKit

@MainActor
final class GameScene: SKScene {
    private let grid = GridManager()
    private let generator = BlockGenerator()
    private let scoreManager: ScoreManager

    private let gridLayer = SKNode()
    private let placedLayer = SKNode()
    private let trayLayer = SKNode()
    private let effectsLayer = SKNode()

    private var slotNodes: [[SKShapeNode]] = []
    private let trayCardNode = SKShapeNode()
    private var placedNodes: [[SKShapeNode?]] = Array(
        repeating: Array(repeating: nil, count: GridManager.gridSize),
        count: GridManager.gridSize
    )

    private var tray: [BlockNode?] = [nil, nil, nil]
    private var trayData: [(shape: BlockShape, color: NeonColor)?] = [nil, nil, nil]

    private var cellSize: CGFloat = 44
    private var gridOrigin: CGPoint = .zero
    private var gridRect: CGRect = .zero

    private var hapticsEnabled: Bool = true
    private var ghostEnabled: Bool = true

    private var activeIndex: Int?
    private var dragNode: BlockNode?
    private var ghostNode: BlockNode?
    private var grabOffset: CGPoint = .zero
    private var grabbedCell: BlockCell = .init(x: 0, y: 0)
    private var currentOrigin: GridPoint?
    private var currentValid: Bool = false

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    init(scoreManager: ScoreManager) {
        self.scoreManager = scoreManager
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.isMultipleTouchEnabled = false

        addChild(gridLayer)
        addChild(placedLayer)
        addChild(trayLayer)
        addChild(effectsLayer)

        buildTrayCard()
        layoutScene()
        buildGridSlots()
        startNewGame()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScene()
        rebuildTrayNodesForCurrentSize()
        layoutTray()
        layoutPlacedNodes()
        layoutSlotNodes()
        updateGhost(for: lastTouchLocation)
    }

    func updateSettings(hapticsEnabled: Bool, ghostEnabled: Bool) {
        self.hapticsEnabled = hapticsEnabled
        self.ghostEnabled = ghostEnabled
        if !ghostEnabled {
            ghostNode?.removeFromParent()
            ghostNode = nil
        }
    }

    func startNewGame() {
        grid.reset()
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                placedNodes[row][col]?.removeFromParent()
                placedNodes[row][col] = nil
            }
        }

        for i in 0..<3 {
            tray[i]?.removeFromParent()
            tray[i] = nil
            trayData[i] = nil
        }

        scoreManager.reset()

        refillTray()
    }

    // MARK: - Layout

    private func layoutScene() {
        let gridMaxWidth = size.width * 0.90
        let gridMaxHeight = size.height * 0.58
        cellSize = floor(min(gridMaxWidth / 8.0, gridMaxHeight / 8.0))

        let gridW = cellSize * 8
        let gridH = cellSize * 8
        let gridCenterY = size.height * 0.52
        gridOrigin = CGPoint(x: (size.width - gridW) * 0.5, y: gridCenterY - gridH * 0.5)
        gridRect = CGRect(x: gridOrigin.x, y: gridOrigin.y, width: gridW, height: gridH)

        trayLayer.position = .zero
        gridLayer.position = .zero
        placedLayer.position = .zero
        effectsLayer.position = .zero
    }

    private func buildGridSlots() {
        gridLayer.removeAllChildren()
        slotNodes = Array(repeating: [], count: GridManager.gridSize)

        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                let slot = SKShapeNode(rectOf: CGSize(width: cellSize * 0.92, height: cellSize * 0.92), cornerRadius: cellSize * 0.20)
                slot.fillColor = SKColor(white: 1.0, alpha: 0.05)
                slot.strokeColor = SKColor(white: 1.0, alpha: 0.08)
                slot.lineWidth = max(1.0, cellSize * 0.035)
                slot.position = positionForCell(row: row, col: col)
                slot.zPosition = 0
                gridLayer.addChild(slot)
                slotNodes[row].append(slot)
            }
        }
    }

    private func layoutSlotNodes() {
        guard slotNodes.count == GridManager.gridSize else { return }
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize where col < slotNodes[row].count {
                slotNodes[row][col].position = positionForCell(row: row, col: col)
                slotNodes[row][col].path = CGPath(
                    roundedRect: CGRect(
                        x: -cellSize * 0.46,
                        y: -cellSize * 0.46,
                        width: cellSize * 0.92,
                        height: cellSize * 0.92
                    ),
                    cornerWidth: cellSize * 0.20,
                    cornerHeight: cellSize * 0.20,
                    transform: nil
                )
            }
        }
    }

    private func layoutPlacedNodes() {
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                placedNodes[row][col]?.position = positionForCell(row: row, col: col)
            }
        }
    }

    private func layoutTray() {
        let trayY = size.height * 0.16
        let centers: [CGFloat] = [
            size.width * 0.22,
            size.width * 0.50,
            size.width * 0.78,
        ]

        let cardW = size.width * 0.90
        let cardH = cellSize * 3.6
        trayCardNode.position = CGPoint(x: size.width * 0.5, y: trayY)
        trayCardNode.path = CGPath(
            roundedRect: CGRect(x: -cardW * 0.5, y: -cardH * 0.5, width: cardW, height: cardH),
            cornerWidth: 22,
            cornerHeight: 22,
            transform: nil
        )

        for i in 0..<3 {
            guard let node = tray[i] else { continue }
            let pieceSize = node.boundingSize()
            node.position = CGPoint(x: centers[i] - pieceSize.width * 0.5, y: trayY - pieceSize.height * 0.5)
            node.setTrayStyle()
            node.zPosition = 20
        }
    }

    private func buildTrayCard() {
        trayCardNode.fillColor = SKColor(white: 0.0, alpha: 0.18)
        trayCardNode.strokeColor = SKColor(white: 1.0, alpha: 0.12)
        trayCardNode.lineWidth = 1.0
        trayCardNode.glowWidth = 0
        trayCardNode.zPosition = 4
        trayLayer.addChild(trayCardNode)
    }

    private func positionForCell(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + (CGFloat(col) + 0.5) * cellSize,
            y: gridOrigin.y + (CGFloat(row) + 0.5) * cellSize
        )
    }

    // MARK: - Tray

    private func refillTray() {
        let trayItems = generator.generateTray(score: currentScore, grid: grid)
        let commonCellSize = trayCellSize(for: trayItems.map(\.shape))
        for i in 0..<3 {
            let item = trayItems[i]
            trayData[i] = item
            let node = BlockNode(shape: item.shape, color: item.color, cellSize: commonCellSize)
            tray[i]?.removeFromParent()
            tray[i] = node
            trayLayer.addChild(node)
        }
        layoutTray()
        checkGameOverIfNeeded()
    }

    private func rebuildTrayNodesForCurrentSize() {
        let shapes = trayData.compactMap { $0?.shape }
        let commonCellSize = trayCellSize(for: shapes)
        for i in 0..<3 {
            guard let item = trayData[i] else { continue }
            tray[i]?.removeFromParent()
            let node = BlockNode(shape: item.shape, color: item.color, cellSize: commonCellSize)
            tray[i] = node
            trayLayer.addChild(node)
        }
    }

    private func trayCellSize(for shapes: [BlockShape]) -> CGFloat {
        let cardW = size.width * 0.90
        let cardH = cellSize * 3.6
        let slotW = cardW / 3.0
        let slotH = cardH
        let widestShape = shapes.map(\.width).max() ?? 1
        let tallestShape = shapes.map(\.height).max() ?? 1

        let maxCellByWidth = (slotW * 0.72) / CGFloat(max(1, widestShape))
        let maxCellByHeight = (slotH * 0.56) / CGFloat(max(1, tallestShape))
        let target = floor(min(maxCellByWidth, maxCellByHeight))

        return max(10, min(target, cellSize * 0.70))
    }

    private func consumeTrayItem(at index: Int) {
        tray[index]?.removeFromParent()
        tray[index] = nil
        trayData[index] = nil
        if trayData.allSatisfy({ $0 == nil }) {
            refillTray()
        }
    }

    // MARK: - Touches

    private var lastTouchLocation: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard scoreManager.isGameOver == false else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchLocation = location

        guard let (index, node) = hitTestTray(at: location) else { return }

        activeIndex = index
        node.pulseSelected(true)
        node.setDimmed(true)

        let drag = BlockNode(shape: node.shape, color: node.color, cellSize: cellSize)
        drag.zPosition = 100
        addChild(drag)
        dragNode = drag

        grabbedCell = nearestCellOffset(in: node, atScenePoint: location)
        grabOffset = CGPoint(
            x: (CGFloat(grabbedCell.x) + 0.5) * cellSize,
            y: (CGFloat(grabbedCell.y) + 0.5) * cellSize
        )

        drag.position = CGPoint(x: location.x - grabOffset.x, y: location.y - grabOffset.y)

        if ghostEnabled {
            let ghost = BlockNode(shape: node.shape, color: node.color, cellSize: cellSize)
            ghost.zPosition = 50
            ghost.alpha = 0.0
            addChild(ghost)
            ghostNode = ghost
        }

        updateGhost(for: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchLocation = location
        guard let dragNode else { return }

        dragNode.position = CGPoint(x: location.x - grabOffset.x, y: location.y - grabOffset.y)
        updateGhost(for: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchLocation = location
        finalizeDrag(at: location, cancelled: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finalizeDrag(at: lastTouchLocation, cancelled: true)
    }

    private func finalizeDrag(at location: CGPoint, cancelled: Bool) {
        guard let index = activeIndex, let trayItem = trayData[index], let trayNode = tray[index] else {
            cleanupDrag()
            return
        }
        guard let dragNode else {
            cleanupDrag()
            return
        }

        if cancelled || currentOrigin == nil || currentValid == false {
            dragNode.run(.sequence([
                .group([
                    .move(to: trayNode.position, duration: 0.16),
                    .scale(to: 0.92, duration: 0.16),
                    .fadeOut(withDuration: 0.16),
                ]),
                .removeFromParent(),
            ]))
            trayNode.setDimmed(false)
            trayNode.pulseSelected(false)
            cleanupDrag(keepTrayPulseReset: true)
            return
        }

        let origin = currentOrigin!
        let placed = grid.place(shape: trayItem.shape, color: trayItem.color, at: origin)
        consumeTrayItem(at: index)

        if hapticsEnabled {
            lightImpact.prepare()
            lightImpact.impactOccurred(intensity: 0.8)
        }

        animatePlacement(of: placed, color: trayItem.color)
        let cleared = grid.clearFilledLines()
        if !cleared.clearedPoints.isEmpty {
            if hapticsEnabled {
                heavyImpact.prepare()
                heavyImpact.impactOccurred()
            }
            animateClears(points: cleared.clearedPoints)
        }

        scoreManager.applyMove(placedCells: placed.count, linesCleared: cleared.clearedRows.count + cleared.clearedCols.count)

        dragNode.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
        trayNode.pulseSelected(false)
        trayNode.setDimmed(false)
        cleanupDrag(keepTrayPulseReset: true)

        checkGameOverIfNeeded()
    }

    private func cleanupDrag(keepTrayPulseReset: Bool = false) {
        if let index = activeIndex, let node = tray[index], keepTrayPulseReset == false {
            node.pulseSelected(false)
            node.setDimmed(false)
        }

        activeIndex = nil
        dragNode?.removeFromParent()
        dragNode = nil

        ghostNode?.removeFromParent()
        ghostNode = nil

        currentOrigin = nil
        currentValid = false
    }

    private func hitTestTray(at location: CGPoint) -> (Int, BlockNode)? {
        for i in 0..<3 {
            guard let node = tray[i] else { continue }
            if node.calculateAccumulatedFrame().insetBy(dx: -10, dy: -10).contains(location) {
                return (i, node)
            }
        }
        return nil
    }

    private func nearestCellOffset(in node: BlockNode, atScenePoint scenePoint: CGPoint) -> BlockCell {
        let local = CGPoint(x: scenePoint.x - node.position.x, y: scenePoint.y - node.position.y)
        var best: (cell: BlockCell, d2: CGFloat)?
        for cell in node.shape.cells {
            let cx = (CGFloat(cell.x) + 0.5) * node.cellSize
            let cy = (CGFloat(cell.y) + 0.5) * node.cellSize
            let dx = local.x - cx
            let dy = local.y - cy
            let d2 = dx * dx + dy * dy
            if best == nil || d2 < best!.d2 {
                best = (cell, d2)
            }
        }
        return best?.cell ?? BlockCell(x: 0, y: 0)
    }

    private func updateGhost(for touchLocation: CGPoint) {
        guard ghostEnabled, let ghostNode else { return }
        guard let index = activeIndex, let item = trayData[index] else {
            ghostNode.alpha = 0
            return
        }

        guard gridRect.contains(touchLocation) else {
            ghostNode.alpha = 0
            currentOrigin = nil
            currentValid = false
            return
        }

        let col = Int(floor((touchLocation.x - gridOrigin.x) / cellSize))
        let row = Int(floor((touchLocation.y - gridOrigin.y) / cellSize))
        let origin = GridPoint(row: row - grabbedCell.y, col: col - grabbedCell.x)

        let valid = grid.canPlace(shape: item.shape, at: origin)
        currentOrigin = origin
        currentValid = valid

        ghostNode.position = CGPoint(x: gridOrigin.x + CGFloat(origin.col) * cellSize, y: gridOrigin.y + CGFloat(origin.row) * cellSize)
        ghostNode.setGhostStyle(isValid: valid)
        ghostNode.alpha = 1.0
    }

    // MARK: - Visuals

    private func makePlacedCellNode(color: NeonColor) -> SKShapeNode {
        let container = SKShapeNode()
        container.zPosition = 10
        container.strokeColor = SKColor.neon(color)

        let rectSize = CGSize(width: cellSize * 0.90, height: cellSize * 0.90)
        let corner = cellSize * 0.22

        let fill = SKShapeNode(rectOf: rectSize, cornerRadius: corner)
        fill.fillColor = SKColor.neon(color).withAlphaComponent(0.55)
        fill.strokeColor = .clear
        fill.lineWidth = 0
        fill.zPosition = 1
        container.addChild(fill)

        let darkEdge = SKShapeNode(rectOf: rectSize, cornerRadius: corner)
        darkEdge.fillColor = .clear
        darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.35)
        darkEdge.lineWidth = max(1.0, cellSize * 0.06)
        darkEdge.glowWidth = 0
        darkEdge.zPosition = 2
        container.addChild(darkEdge)

        let ring = SKShapeNode(rectOf: rectSize, cornerRadius: corner)
        ring.fillColor = .clear
        ring.strokeColor = SKColor.neon(color).withAlphaComponent(0.95)
        ring.lineWidth = max(1.0, cellSize * 0.07)
        ring.glowWidth = 0
        ring.zPosition = 3
        container.addChild(ring)

        return container
    }

    private func animatePlacement(of points: [GridPoint], color: NeonColor) {
        for p in points {
            let node = makePlacedCellNode(color: color)
            node.position = positionForCell(row: p.row, col: p.col)
            node.setScale(0.25)
            placedLayer.addChild(node)
            placedNodes[p.row][p.col] = node

            let pop = SKAction.sequence([
                .scale(to: 1.10, duration: 0.10),
                .scale(to: 1.00, duration: 0.08),
            ])
            pop.timingMode = .easeOut
            node.run(pop)
        }
    }

    private func animateClears(points: [GridPoint]) {
        for p in points {
            guard let node = placedNodes[p.row][p.col] else { continue }
            placedNodes[p.row][p.col] = nil

            spawnSparks(at: node.position, baseColor: node.strokeColor)

            let fade = SKAction.group([
                .fadeOut(withDuration: 0.12),
                .scale(to: 0.55, duration: 0.12),
            ])
            node.run(.sequence([fade, .removeFromParent()]))
        }
    }

    private func spawnSparks(at position: CGPoint, baseColor: SKColor) {
        let count = 14
        for _ in 0..<count {
            let dot = SKShapeNode(circleOfRadius: max(1.5, cellSize * 0.05))
            dot.fillColor = baseColor.withAlphaComponent(0.9)
            dot.strokeColor = .clear
            dot.glowWidth = cellSize * 0.22
            dot.position = position
            dot.zPosition = 200
            effectsLayer.addChild(dot)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: cellSize * 0.25...cellSize * 1.10)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.22)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.22)
            let scale = SKAction.scale(to: 0.1, duration: 0.22)
            dot.run(.sequence([.group([move, fade, scale]), .removeFromParent()]))
        }
    }

    // MARK: - Game Over

    private var currentScore: Int {
        return scoreManager.score
    }

    private func checkGameOverIfNeeded() {
        let shapes: [BlockShape] = trayData.compactMap { $0?.shape }
        let hasMove = grid.anyMovePossible(shapes: shapes)
        if hasMove == false {
            scoreManager.isGameOver = true
        }
    }
}
