//
//  AdventureGameScene.swift
//  NeonGridBuster
//
//  Prompt 2 — Adventure Mode SpriteKit Scene
//  ─────────────────────────────────────────────────────────────────────────
//  • Renders the 8×8 grid distinguishing target gem cells from normal fills.
//  • Bridges every drag/drop → AdventureGameEngine.applyMove(...)
//  • Reuses the same visual building blocks as GameScene (bevel, shards, shake).
//  • Target gem cells render with a pulsing inner gem icon overlay.
//

import SpriteKit
import UIKit

@MainActor
final class AdventureGameScene: SKScene {

    // ── Engine ──────────────────────────────────────────────────────────────
    private let engine: AdventureGameEngine

    // ── Layers ──────────────────────────────────────────────────────────────
    private let gridLayer    = SKNode()
    private let placedLayer  = SKNode()
    private let trayLayer    = SKNode()
    private let effectsLayer = SKNode()

    // ── Grid ─────────────────────────────────────────────────────────────────
    private var slotNodes:    [[SKShapeNode]] = []
    private let trayCardNode  = SKShapeNode()
    private var placedNodes:  [[SKShapeNode?]] = Array(
        repeating: Array(repeating: nil, count: GridManager.gridSize),
        count: GridManager.gridSize
    )

    // ── Tray ─────────────────────────────────────────────────────────────────
    private var tray:     [BlockNode?] = [nil, nil, nil]

    // ── Layout ───────────────────────────────────────────────────────────────
    private var cellSize:   CGFloat = 44
    private var gridOrigin: CGPoint = .zero
    private var gridRect:   CGRect  = .zero

    // ── Settings ─────────────────────────────────────────────────────────────
    private var hapticsEnabled = true
    private var ghostEnabled   = true

    // ── Drag state ───────────────────────────────────────────────────────────
    private var activeIndex:   Int?
    private var dragNode:      BlockNode?
    private var ghostNode:     BlockNode?
    private var grabOffset:    CGPoint = .zero
    private var grabbedCell:   BlockCell = .init(x: 0, y: 0)
    private var currentOrigin: GridPoint?
    private var currentValid:  Bool = false
    private var lastTouchLocation: CGPoint = .zero

    /// Vertical distance the dragged block is shifted above the user's finger (for visibility)
    private let dragVerticalOffset: CGFloat = 120

    // ── Camera ───────────────────────────────────────────────────────────────
    private let gameCamera = SKCameraNode()

    // ── Haptics ──────────────────────────────────────────────────────────────
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Init

    init(engine: AdventureGameEngine) {
        self.engine = engine
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode       = .resizeFill
        backgroundColor = .clear // Transparent to show SwiftUI Arcade Blue
    }

    required init?(coder: NSCoder) { return nil }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.isMultipleTouchEnabled = false

        gameCamera.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        addChild(gameCamera)
        camera = gameCamera

        addChild(gridLayer)
        addChild(placedLayer)
        addChild(trayLayer)
        addChild(effectsLayer)

        buildTrayCard()
        layoutScene()
        buildGridSlots()
        renderGrid()
        buildTrayNodes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        gameCamera.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        layoutScene()
        buildGridSlots()
        renderGrid()
        buildTrayNodes()
        layoutTray()
    }

    // MARK: - Settings

    func updateSettings(hapticsEnabled: Bool, ghostEnabled: Bool) {
        self.hapticsEnabled = hapticsEnabled
        self.ghostEnabled   = ghostEnabled
        if !ghostEnabled {
            ghostNode?.removeFromParent()
            ghostNode = nil
        }
    }

    func restartLevel() {
        // Clear placed nodes
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                placedNodes[row][col]?.removeFromParent()
                placedNodes[row][col] = nil
            }
        }
        // Clear tray
        for i in 0..<3 {
            tray[i]?.removeFromParent()
            tray[i] = nil
        }
        renderGrid()
        buildTrayNodes()
    }

    // MARK: - Layout

    private func layoutScene() {
        let gridMaxWidth  = size.width  * 0.90
        let gridMaxHeight = size.height * 0.58
        cellSize = floor(min(gridMaxWidth / 8.0, gridMaxHeight / 8.0))

        let gridW = cellSize * 8
        let gridH = cellSize * 8
        let gridCenterY = size.height * 0.52
        gridOrigin = CGPoint(x: (size.width - gridW) * 0.5,
                             y: gridCenterY - gridH * 0.5)
        gridRect = CGRect(x: gridOrigin.x, y: gridOrigin.y, width: gridW, height: gridH)

        gridLayer.position    = .zero
        placedLayer.position  = .zero
        trayLayer.position    = .zero
        effectsLayer.position = .zero
    }

    private func positionForCell(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + (CGFloat(col) + 0.5) * cellSize,
            y: gridOrigin.y + (CGFloat(row) + 0.5) * cellSize
        )
    }

    // MARK: - Grid Slots

    private func buildGridSlots() {
        gridLayer.removeAllChildren()
        slotNodes = Array(repeating: [], count: GridManager.gridSize)

        // Background panel
        let bgPad: CGFloat = cellSize * 0.06
        let bgW = cellSize * CGFloat(GridManager.gridSize) + bgPad * 2
        let bgH = cellSize * CGFloat(GridManager.gridSize) + bgPad * 2
        let bg  = SKShapeNode(rectOf: CGSize(width: bgW, height: bgH),
                              cornerRadius: cellSize * 0.20)
        bg.fillColor   = SKColor(red: 0x05 / 255, green: 0x0A / 255, blue: 0x14 / 255, alpha: 0.60)
        bg.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        bg.lineWidth   = max(1.0, cellSize * 0.06)
        bg.position    = CGPoint(
            x: gridOrigin.x + cellSize * CGFloat(GridManager.gridSize) * 0.5,
            y: gridOrigin.y + cellSize * CGFloat(GridManager.gridSize) * 0.5
        )
        bg.zPosition   = -1
        gridLayer.addChild(bg)

        // Individual slots
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                let slot = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.90, height: cellSize * 0.90),
                    cornerRadius: cellSize * 0.18
                )
                slot.fillColor   = SKColor(red: 0x0B / 255, green: 0x0E / 255, blue: 0x1A / 255, alpha: 0.50)
                slot.strokeColor = SKColor(white: 1.0, alpha: 0.08)
                slot.lineWidth   = max(1.0, cellSize * 0.04)
                slot.position    = positionForCell(row: row, col: col)
                slot.zPosition   = 0
                gridLayer.addChild(slot)
                slotNodes[row].append(slot)
            }
        }
    }

    // MARK: - Grid Rendering (Adventure-aware)

    /// Renders the full grid from engine.grid.cellStates.
    /// Called on load / restart. Placed nodes are built cell by cell.
    private func renderGrid() {
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                placedNodes[row][col]?.removeFromParent()
                placedNodes[row][col] = nil

                let state = engine.grid.cellStates[row][col]
                switch state {
                case .empty:
                    break
                case .normal(let color):
                    let node = makePlacedCellNode(color: color, isTarget: false)
                    node.position = positionForCell(row: row, col: col)
                    placedLayer.addChild(node)
                    placedNodes[row][col] = node

                case .target(let gem):
                    let node = makeTargetGemNode(gem: gem)
                    node.position = positionForCell(row: row, col: col)
                    placedLayer.addChild(node)
                    placedNodes[row][col] = node
                }
            }
        }
    }

    // MARK: - Cell Node Factories

    /// Standard 5-layer bevel block — same as Classic Mode.
    /// Standard 5-layer bevel block — same as Classic Mode.
    private func makePlacedCellNode(color: NeonColor, isTarget: Bool) -> SKShapeNode {
        let container = SKShapeNode()
        container.zPosition   = 10
        container.strokeColor = SKColor.neon(color)
        container.fillColor   = .clear

        let fullSize = CGSize(width: cellSize * 0.90, height: cellSize * 0.90)
        let corner   = cellSize * 0.20
        let bevelW   = max(1.5, cellSize * 0.12)

        if isTarget {
            // ── Target Gem Rendering ──
            let gem = TargetGem.allCases.first { $0.neonColor == color } ?? .emerald
            
            // 1. Large Outer Glow Bloom
            let glow = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
            glow.fillColor = SKColor.neon(color).withAlphaComponent(0.25)
            glow.strokeColor = .clear
            glow.glowWidth = 12
            glow.zPosition = 1
            container.addChild(glow)
            
            // 2. High-intensity Neon Ring
            let ring = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
            ring.fillColor = .clear
            ring.strokeColor = SKColor.neon(color)
            ring.lineWidth = 2.5
            ring.glowWidth = 2
            ring.zPosition = 2
            container.addChild(ring)
            
            // 3. Gem Shape (Crystal cut)
            let gemNode = GemFactory.makeGemShapeNode(for: gem, size: cellSize * 0.72)
            gemNode.fillColor = SKColor.neon(color).withAlphaComponent(1.0)
            gemNode.strokeColor = .white
            gemNode.lineWidth = 1.0
            gemNode.zPosition = 5
            container.addChild(gemNode)
            
            // 4. Brilliant Inner Core (Point of Light)
            let core = SKShapeNode(circleOfRadius: cellSize * 0.12)
            core.fillColor = .white
            core.strokeColor = .clear
            core.glowWidth = 3
            core.zPosition = 6
            container.addChild(core)
            
            return container
        }

        // 1 — base fill (Normal block)
        let fill = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        fill.fillColor   = SKColor.neon(color).withAlphaComponent(0.82)
        fill.strokeColor = .clear
        fill.lineWidth   = 0
        fill.zPosition   = 1
        container.addChild(fill)

        // 2 — bevel highlight
        let hi = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        hi.fillColor  = SKColor(white: 1.0, alpha: 0.24)
        hi.strokeColor = .clear
        hi.position   = CGPoint(x: -bevelW * 0.5, y: bevelW * 0.5)
        hi.blendMode  = .add
        hi.zPosition  = 2
        container.addChild(hi)

        // 3 — bevel shadow
        let shad = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        shad.fillColor   = SKColor(white: 0.0, alpha: 0.30)
        shad.strokeColor = .clear
        shad.position    = CGPoint(x: bevelW * 0.5, y: -bevelW * 0.5)
        shad.zPosition   = 2
        container.addChild(shad)

        // 4 — dark inner border
        let darkEdge = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        darkEdge.fillColor   = .clear
        darkEdge.strokeColor = SKColor(white: 0.0, alpha: 0.38)
        darkEdge.lineWidth   = max(1.0, cellSize * 0.05)
        darkEdge.glowWidth   = 0
        darkEdge.zPosition   = 3
        container.addChild(darkEdge)

        // 5 — neon glow ring
        let ring = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        ring.fillColor   = .clear
        ring.strokeColor = SKColor.neon(color).withAlphaComponent(isTarget ? 0.40 : 0.90)
        ring.lineWidth   = max(1.0, cellSize * 0.065)
        ring.glowWidth   = max(1.0, cellSize * 0.08)
        ring.zPosition   = 4
        container.addChild(ring)

        return container
    }

    private func makeTargetGemNode(gem: TargetGem) -> SKShapeNode {
        let color    = gem.neonColor
        
        let container = makePlacedCellNode(color: color, isTarget: true)
        let icon = makeTargetGemIcon(gem: gem)
        container.addChild(icon)

        return container
    }

    /// Helper for adding a pulsing gem icon to any node
    private func makeTargetGemIcon(gem: TargetGem) -> SKShapeNode {
        let color    = gem.neonColor
        let gemColor = SKColor.neon(color)
        let iconRadius = cellSize * 0.20
        let icon = SKShapeNode(circleOfRadius: iconRadius)
        icon.fillColor   = gemColor.withAlphaComponent(0.90)
        icon.strokeColor = SKColor.white.withAlphaComponent(0.55)
        icon.lineWidth   = max(1.0, cellSize * 0.04)
        icon.glowWidth   = cellSize * 0.20
        icon.zPosition   = 6
        icon.name        = "gemIcon"
        animateGemPulse(icon)
        return icon
    }

    private func animateGemPulse(_ node: SKNode) {
        let pulse = SKAction.sequence([
            .scale(to: 1.18, duration: 0.70),
            .scale(to: 1.00, duration: 0.70),
        ])
        node.run(.repeatForever(pulse))
    }

    // MARK: - Tray

    private func buildTrayCard() {
        trayCardNode.fillColor   = SKColor(white: 0.0, alpha: 0.18)
        trayCardNode.strokeColor = SKColor(white: 1.0, alpha: 0.12)
        trayCardNode.lineWidth   = 1.0
        trayCardNode.zPosition   = 4
        trayLayer.addChild(trayCardNode)
    }

    private func buildTrayNodes() {
        for i in 0..<3 {
            tray[i]?.removeFromParent()
            tray[i] = nil
        }

        // Build from engine trayData
        let shapes = engine.trayData.compactMap { $0?.shape }
        let commonCS = trayCellSize(for: shapes)

        for i in 0..<3 {
            guard let item = engine.trayData[i] else { continue }
            let node = BlockNode(shape: item.shape, color: item.color, cellSize: commonCS)
            tray[i] = node
            trayLayer.addChild(node)
        }
        layoutTray()
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
            cornerWidth: 22, cornerHeight: 22, transform: nil
        )

        let shapes = engine.trayData.compactMap { $0?.shape }
        _ = trayCellSize(for: shapes)

        for i in 0..<3 {
            guard let node = tray[i] else { continue }
            let pieceSize = node.boundingSize()
            node.position = CGPoint(
                x: centers[i] - pieceSize.width * 0.5,
                y: trayY - pieceSize.height * 0.5
            )
            node.setTrayStyle()
            node.zPosition = 20
        }
    }

    private func trayCellSize(for shapes: [BlockShape]) -> CGFloat {
        let cardW = size.width * 0.90
        let cardH = cellSize * 3.6
        let slotW = cardW / 3.0
        let slotH = cardH
        let widest  = shapes.map(\.width).max()  ?? 1
        let tallest = shapes.map(\.height).max() ?? 1
        let maxW = (slotW * 0.72) / CGFloat(max(1, widest))
        let maxH = (slotH * 0.56) / CGFloat(max(1, tallest))
        return max(10, min(floor(min(maxW, maxH)), cellSize * 0.70))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !engine.isLevelWon && !engine.isGameOver else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchLocation = location

        guard let (index, node) = hitTestTray(at: location) else { return }

        activeIndex = index
        node.pulseSelected(true)
        node.setDimmed(true)

        guard let item = engine.trayData[index] else { return }
        let gem = engine.trayGems[index]
        let drag = BlockNode(shape: item.shape, color: item.color, cellSize: cellSize, gem: gem)
        drag.zPosition = 100
        addChild(drag)
        dragNode = drag

        grabbedCell = nearestCellOffset(in: node, atScenePoint: location)
        grabOffset  = CGPoint(
            x: (CGFloat(grabbedCell.x) + 0.5) * cellSize,
            y: (CGFloat(grabbedCell.y) + 0.5) * cellSize
        )
        drag.position = CGPoint(x: location.x - grabOffset.x,
                                y: location.y - grabOffset.y + dragVerticalOffset)

        if ghostEnabled {
            let ghost = BlockNode(shape: item.shape, color: item.color, cellSize: cellSize, gem: gem)
            ghost.zPosition = 50
            ghost.alpha     = 0.0
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
        dragNode.position = CGPoint(x: location.x - grabOffset.x,
                                    y: location.y - grabOffset.y + dragVerticalOffset)
        updateGhost(for: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        finalizeDrag(at: touch.location(in: self), cancelled: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finalizeDrag(at: lastTouchLocation, cancelled: true)
    }

    // MARK: - Drag Finalisation

    private func finalizeDrag(at location: CGPoint, cancelled: Bool) {
        guard let index = activeIndex,
              let item  = engine.trayData[index],
              let trayNode = tray[index] else {
            cleanupDrag(); return
        }
        guard let dragNode else { cleanupDrag(); return }

        if cancelled || currentOrigin == nil || !currentValid {
            dragNode.run(.sequence([
                .group([.move(to: trayNode.position, duration: 0.16),
                        .scale(to: 0.92, duration: 0.16),
                        .fadeOut(withDuration: 0.16)]),
                .removeFromParent(),
            ]))
            trayNode.setDimmed(false)
            trayNode.pulseSelected(false)
            cleanupDrag(keepTrayReset: true)
            return
        }

        let origin = currentOrigin!

        // ── 1. Haptic ─────────────────────────────────────────────────────
        if hapticsEnabled {
            lightImpact.prepare()
            lightImpact.impactOccurred(intensity: 0.8)
        }

        // ── 2. Animate placement visuals (before engine mutates state) ────
        _ = engine.grid.cellStates   // snapshot for coordinate reference
        // We drive placement animation from engine's applyMove result via grid sync
        let tempShape = item.shape
        let tempColor = item.color

        // ── 3. Apply move through engine ──────────────────────────────────
        engine.applyMove(shape: tempShape, color: tempColor, at: origin, trayIndex: index)

        // ── 4. Animate new placed cells ───────────────────────────────────
        animatePlacement(shape: tempShape, color: tempColor, at: origin)

        // ── 5. Animate clears ─────────────────────────────────────────────
        let clearedGems = engine.grid.lastClearedGems
        // Gather all cleared grid points from the changed cell states
        // (cells that went from non-empty to .empty since our move)
        animateClearsFromEngine()

        if !clearedGems.isEmpty && hapticsEnabled {
            heavyImpact.prepare()
            heavyImpact.impactOccurred()
        }

        // ── 6. Screen shake on clear ──────────────────────────────────────
        if !clearedGems.isEmpty {
            screenShake(intensity: 5.0)
        }

        // ── 7. Sync tray nodes ────────────────────────────────────────────
        syncTrayNodes()

        dragNode.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
        trayNode.pulseSelected(false)
        trayNode.setDimmed(false)
        cleanupDrag(keepTrayReset: true)
    }

    private func cleanupDrag(keepTrayReset: Bool = false) {
        if let index = activeIndex, let node = tray[index], !keepTrayReset {
            node.pulseSelected(false)
            node.setDimmed(false)
        }
        activeIndex = nil
        dragNode?.removeFromParent()
        dragNode = nil
        ghostNode?.removeFromParent()
        ghostNode = nil
        currentOrigin = nil
        currentValid  = false
    }

    // MARK: - Tray Sync

    /// After engine updates trayData, rebuild any nil/changed slots.
    private func syncTrayNodes() {
        let shapes   = engine.trayData.compactMap { $0?.shape }
        let commonCS = trayCellSize(for: shapes)

        for i in 0..<3 {
            let data = engine.trayData[i]
            let currentNode = tray[i]
            
            let gem = engine.trayGems[i]
            if data == nil {
                currentNode?.removeFromParent()
                tray[i] = nil
            } else if let item = data {
                // If shape, color, or gem changed, replace it
                if let node = currentNode, (node.shape.id != item.shape.id || node.color != item.color || node.gem != gem) {
                    node.removeFromParent()
                    tray[i] = nil
                }
                
                // Recreate if nil (either was nil or just cleared above)
                if tray[i] == nil {
                    let newNode = BlockNode(shape: item.shape, color: item.color, cellSize: commonCS, gem: gem)
                    tray[i] = newNode
                    trayLayer.addChild(newNode)
                }
            }
        }
        layoutTray()
    }

    // MARK: - Animation Helpers

    private func animatePlacement(shape: BlockShape, color: NeonColor, at origin: GridPoint) {
        for cell in shape.cells {
            let row = origin.row + cell.y
            let col = origin.col + cell.x
            guard row >= 0 && row < GridManager.gridSize &&
                  col >= 0 && col < GridManager.gridSize else { continue }

            // Remove old node if present
            placedNodes[row][col]?.removeFromParent()

            // Detect if this cell should have a gem (from the piece we just dropped)
            let cellState = engine.grid.cellStates[row][col]
            let isTarget = cellState.gem != nil
            
            let node = makePlacedCellNode(color: color, isTarget: isTarget)
            if isTarget, let gem = cellState.gem {
                 // Add the pulsing neon gem icon to the grid cell
                 let icon = makeTargetGemIcon(gem: gem)
                 node.addChild(icon)
            }
            
            node.position = positionForCell(row: row, col: col)
            node.setScale(0.25)
            placedLayer.addChild(node)
            placedNodes[row][col] = node

            let pop = SKAction.sequence([
                .scale(to: 1.10, duration: 0.10),
                .scale(to: 1.00, duration: 0.08),
            ])
            pop.timingMode = .easeOut
            node.run(pop)
        }
    }

    /// Detect cells that should now be empty (cleared by engine) and animate them out.
    private func animateClearsFromEngine() {
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                let engineState = engine.grid.cellStates[row][col]
                if case .empty = engineState, let node = placedNodes[row][col] {
                    placedNodes[row][col] = nil
                    spawnNeonShards(at: node.position, baseColor: node.strokeColor)

                    let burst = SKAction.group([
                        .fadeOut(withDuration: 0.13),
                        .scale(to: 0.35, duration: 0.13),
                    ])
                    node.run(.sequence([burst, .removeFromParent()]))
                }
            }
        }
    }

    private func spawnNeonShards(at position: CGPoint, baseColor: SKColor, count: Int = 10) {
        let accents: [SKColor] = [baseColor,
                                  baseColor.withAlphaComponent(0.65),
                                  SKColor(white: 1.0, alpha: 0.88)]
        for i in 0..<count {
            let particle: SKShapeNode
            if i % 3 == 0 {
                let w = CGFloat.random(in: cellSize * 0.04...cellSize * 0.10)
                let h = CGFloat.random(in: cellSize * 0.22...cellSize * 0.52)
                particle = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: w * 0.25)
                particle.zRotation = CGFloat.random(in: 0...(2 * .pi))
            } else {
                particle = SKShapeNode(circleOfRadius: CGFloat.random(in: cellSize * 0.04...cellSize * 0.09))
            }
            particle.fillColor   = accents[i % accents.count]
            particle.strokeColor = .clear
            // Removed glowWidth from individual shards as it creates significant main-thread lag when multiple cells clear.
            particle.position    = position
            particle.zPosition   = 210
            effectsLayer.addChild(particle)

            let angle = CGFloat(i) / CGFloat(count) * 2.0 * .pi + CGFloat.random(in: -0.4...0.4)
            let dist  = CGFloat.random(in: cellSize * 0.6...cellSize * 2.2)
            let move  = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.28)
            move.timingMode = .easeOut
            particle.run(.sequence([
                .group([move, .fadeOut(withDuration: 0.28), .scale(to: 0.05, duration: 0.28)]),
                .removeFromParent()
            ]))
        }
    }

    private func screenShake(intensity: CGFloat = 6.0) {
        gameCamera.removeAction(forKey: "shake")
        let origin = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        var actions: [SKAction] = []
        var amp = intensity
        for _ in 0..<10 {
            let dx = CGFloat.random(in: -amp...amp)
            let dy = CGFloat.random(in: -amp...amp)
            actions.append(.move(to: CGPoint(x: origin.x + dx, y: origin.y + dy), duration: 0.028))
            amp *= 0.72
        }
        actions.append(.move(to: origin, duration: 0.025))
        gameCamera.run(.sequence(actions), withKey: "shake")
    }

    // MARK: - Ghost & Hit Test

    private func updateGhost(for touchLocation: CGPoint) {
        guard ghostEnabled, let ghostNode else { return }
        guard let index = activeIndex, let item = engine.trayData[index] else {
            ghostNode.alpha = 0; return
        }
        let offsetLocation = CGPoint(x: touchLocation.x, y: touchLocation.y + dragVerticalOffset)

        guard gridRect.contains(offsetLocation) else {
            ghostNode.alpha = 0
            currentOrigin = nil
            currentValid  = false
            return
        }

        let col    = Int(floor((offsetLocation.x - gridOrigin.x) / cellSize))
        let row    = Int(floor((offsetLocation.y - gridOrigin.y) / cellSize))
        let origin = GridPoint(row: row - grabbedCell.y, col: col - grabbedCell.x)
        let valid  = engine.grid.canPlace(shape: item.shape, at: origin)
        currentOrigin = origin
        currentValid  = valid

        ghostNode.position = CGPoint(
            x: gridOrigin.x + CGFloat(origin.col) * cellSize,
            y: gridOrigin.y + CGFloat(origin.row) * cellSize
        )
        ghostNode.setGhostStyle(isValid: valid)
        ghostNode.alpha = 1.0
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
        let local = CGPoint(x: scenePoint.x - node.position.x,
                            y: scenePoint.y - node.position.y)
        var best: (cell: BlockCell, d2: CGFloat)?
        for cell in node.shape.cells {
            let cx = (CGFloat(cell.x) + 0.5) * node.cellSize
            let cy = (CGFloat(cell.y) + 0.5) * node.cellSize
            let d2 = (local.x - cx) * (local.x - cx) + (local.y - cy) * (local.y - cy)
            if best == nil || d2 < best!.d2 { best = (cell, d2) }
        }
        return best?.cell ?? BlockCell(x: 0, y: 0)
    }
}
