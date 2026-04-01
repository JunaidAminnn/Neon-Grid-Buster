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
    private let gameStateManager: GameStateManager

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

    /// Vertical distance the dragged block is shifted above the user's finger (for visibility)
    private let dragVerticalOffset: CGFloat = 100

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    // ── Camera (Prompt 4.2 — screen shake) ───────────────────────────────
    private let gameCamera = SKCameraNode()

    // ── Dynamic Palette System (Prompt 4.2) ──────────────────────────────
    /// 5 curated palettes; cycles on Combo 5+ or board clear.
    private let palettes: [[NeonColor]] = [
        [.cyan,   .pink,   .purple, .ice,   .blue  ],   // 0 Neon Midnight (default)
        [.red,    .yellow, .orange, .pink,  .red   ],   // 1 Fire Sunset
        [.purple, .blue,   .pink,  .ice,   .cyan   ],   // 2 Deep Space
        [.lime,   .orange, .yellow, .pink,  .lime  ],   // 3 Acid Rave
        [.ice,    .blue,   .cyan,   .purple,.ice   ],   // 4 Arctic Dream
    ]
    private var currentPaletteIndex = 0
    private var paletteColorCursor  = 0
    private var activePalette: [NeonColor] { palettes[currentPaletteIndex % palettes.count] }

    /// Optional adventure-level pre-fill (nil = normal free-play).
    private var adventurePreset: [[NeonColor?]]?

    init(scoreManager: ScoreManager, gameStateManager: GameStateManager, adventurePreset: [[NeonColor?]]? = nil) {
        self.scoreManager    = scoreManager
        self.gameStateManager = gameStateManager
        self.adventurePreset = adventurePreset
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode        = .resizeFill
        backgroundColor  = .black   // Prompt 4.1 — solid #000000 game canvas
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.isMultipleTouchEnabled = false

        // Camera for screen shake
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
        startNewGame()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        gameCamera.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
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
        
        if adventurePreset == nil, let saved = gameStateManager.savedState {
            // Restore from saved state
            scoreManager.restoreState(score: saved.score, combo: saved.combo)
            currentPaletteIndex = saved.currentPaletteIndex
            paletteColorCursor = saved.paletteColorCursor

            var loadedGrid: [[NeonColor?]] = Array(repeating: Array(repeating: nil, count: GridManager.gridSize), count: GridManager.gridSize)
            for r in 0..<GridManager.gridSize {
                for c in 0..<GridManager.gridSize {
                    if let raw = saved.gridCells[r][c] {
                        loadedGrid[r][c] = NeonColor(rawValue: raw)
                    }
                }
            }
            grid.loadPreset(loadedGrid)
            renderPreset()

            // Restore tray
            for i in 0..<3 {
                if let shapeID = saved.trayShapeIDs[i], let colorRaw = saved.trayColors[i], let shape = ShapeLibrary.shape(for: shapeID), let color = NeonColor(rawValue: colorRaw) {
                    trayData[i] = (shape: shape, color: color)
                } else {
                    trayData[i] = nil
                }
            }
            rebuildTrayNodesForCurrentSize()
            layoutTray()
            checkGameOverIfNeeded()
        } else {
            scoreManager.reset()
            currentPaletteIndex = 0
            paletteColorCursor  = 0
            if let preset = adventurePreset {
                grid.loadPreset(preset)
                renderPreset()
                refillTray()
            } else {
                // Classic mode: put a few random shapes so the grid isn't empty
                placeRandomStartingBlocks()
                refillTray()
            }
            saveCurrentState()
        }
    }

    /// Resumes the current session after a rewarded ad by clearing Game Over and giving easy blocks.
    func continueAfterAd() {
        scoreManager.isGameOver = false
        refillEasyTray()
        saveCurrentState()
    }

    private func refillEasyTray() {
        let shapes = generator.generateEasyTray()
        // Use active palette colours
        let trayItems = shapes.map { (shape: $0, color: nextPaletteColor()) }
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

    // MARK: - Starting Blocks (Classic Mode)

    /// Spawns a randomized alphabet letter (A, B, C, D) out of grid blocks as the starting puzzle.
    private func placeRandomStartingBlocks() {
        let patterns: [[String]] = [
            // Letter A
            [
                "        ",
                "  XXXX  ",
                " XX  XX ",
                " XX  XX ",
                " XXXXXX ",
                " XX  XX ",
                " XX  XX ",
                "        "
            ],
            // Letter B
            [
                "        ",
                " XXXXX  ",
                " XX  XX ",
                " XXXXX  ",
                " XX  XX ",
                " XX  XX ",
                " XXXXX  ",
                "        "
            ],
            // Letter C
            [
                "        ",
                "  XXXXX ",
                " XX     ",
                " XX     ",
                " XX     ",
                " XX     ",
                "  XXXXX ",
                "        "
            ],
            // Letter D
            [
                "        ",
                " XXXXX  ",
                " XX  XX ",
                " XX  XX ",
                " XX  XX ",
                " XX  XX ",
                " XXXXX  ",
                "        "
            ]
        ]
        
        guard let chosen = patterns.randomElement() else { return }
        
        var presetGrid: [[NeonColor?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        let colorPool = activePalette
        
        for (r, rowStr) in chosen.enumerated() {
            let chars = Array(rowStr)
            for (c, char) in chars.enumerated() {
                if char == "X" {
                    presetGrid[r][c] = colorPool.randomElement() ?? .cyan
                }
            }
        }
        
        grid.loadPreset(presetGrid)
        renderPreset()
    }

    /// Renders pre-filled grid cells after a grid is populated manually.
    private func renderPreset() {
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                guard let color = grid.cells[row][col] else { continue }
                let node = makePlacedCellNode(color: color)
                node.position = positionForCell(row: row, col: col)
                placedLayer.addChild(node)
                placedNodes[row][col] = node
            }
        }
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

        // ── Grid background panel (#121212) ──────────────────────────────
        let bgPad: CGFloat = cellSize * 0.06
        let bgW = cellSize * CGFloat(GridManager.gridSize) + bgPad * 2
        let bgH = cellSize * CGFloat(GridManager.gridSize) + bgPad * 2
        let bgNode = SKShapeNode(
            rectOf: CGSize(width: bgW, height: bgH),
            cornerRadius: cellSize * 0.20
        )
        bgNode.fillColor   = SKColor(red: 0x12/255, green: 0x12/255, blue: 0x12/255, alpha: 1.0)
        bgNode.strokeColor = SKColor(red: 0x1F/255, green: 0x1F/255, blue: 0x1F/255, alpha: 0.70)
        bgNode.lineWidth   = max(1.0, cellSize * 0.06)
        bgNode.position    = CGPoint(
            x: gridOrigin.x + cellSize * CGFloat(GridManager.gridSize) * 0.5,
            y: gridOrigin.y + cellSize * CGFloat(GridManager.gridSize) * 0.5
        )
        bgNode.zPosition   = -1
        gridLayer.addChild(bgNode)

        // ── Individual cell slots ────────────────────────────────────────
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                let slot = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.90, height: cellSize * 0.90),
                    cornerRadius: cellSize * 0.18
                )
                // #121212 dark cell fill
                slot.fillColor   = SKColor(red: 0x12/255, green: 0x12/255, blue: 0x12/255, alpha: 1.0)
                // #1F1F1F subtle neon grid-line stroke
                slot.strokeColor = SKColor(red: 0x1F/255, green: 0x1F/255, blue: 0x1F/255, alpha: 0.90)
                slot.lineWidth   = max(1.0, cellSize * 0.04)
                slot.position    = positionForCell(row: row, col: col)
                slot.zPosition   = 0
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
                        x: -cellSize * 0.45,
                        y: -cellSize * 0.45,
                        width: cellSize * 0.90,
                        height: cellSize * 0.90
                    ),
                    cornerWidth: cellSize * 0.18,
                    cornerHeight: cellSize * 0.18,
                    transform: nil
                )
            }
        }
        // Rebuild grid-layer (refreshes bg panel + all slots on resize)
        buildGridSlots()
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
        let rawItems = generator.generateTray(score: currentScore, grid: grid)
        // Apply active palette colours so new pieces match the current skin
        let trayItems = rawItems.map { (shape: $0.shape, color: nextPaletteColor()) }
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

        drag.position = CGPoint(x: location.x - grabOffset.x, y: location.y - grabOffset.y + dragVerticalOffset)

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

        dragNode.position = CGPoint(x: location.x - grabOffset.x, y: location.y - grabOffset.y + dragVerticalOffset)
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
        let totalLines = cleared.clearedRows.count + cleared.clearedCols.count

        if !cleared.clearedPoints.isEmpty {
            if hapticsEnabled {
                heavyImpact.prepare()
                heavyImpact.impactOccurred()
            }
            animateClears(points: cleared.clearedPoints)

            // ── Board-clear celebration flash ──────────────────────────
            if cleared.isBoardClear {
                animateBoardClearFlash()
            }
        }

        // Prompt 3.3 — tiered scoring with isBoardClear flag
        scoreManager.applyMove(
            placedCells:       placed.count,
            totalLinesCleared: totalLines,
            isBoardClear:      cleared.isBoardClear
        )

        // ── Prompt 4.2: audio cue + screen shake + palette shift ────────
        let currentCombo = scoreManager.combo
        if totalLines > 0 {
            SoundManager.shared.playLineClear(comboLevel: max(1, currentCombo))
            screenShake(intensity: currentCombo >= 5 ? 10.0 : 5.0)
        }
        if currentCombo >= 5 || cleared.isBoardClear {
            triggerPaletteShift()
        }

        dragNode.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
        trayNode.pulseSelected(false)
        trayNode.setDimmed(false)
        cleanupDrag(keepTrayPulseReset: true)

        checkGameOverIfNeeded()
        saveCurrentState()
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
        let row = Int(floor((touchLocation.y + dragVerticalOffset - gridOrigin.y) / cellSize))
        let origin = GridPoint(row: row - grabbedCell.y, col: col - grabbedCell.x)

        let valid = grid.canPlace(shape: item.shape, at: origin)
        currentOrigin = origin
        currentValid = valid

        ghostNode.position = CGPoint(x: gridOrigin.x + CGFloat(origin.col) * cellSize, y: gridOrigin.y + CGFloat(origin.row) * cellSize)
        ghostNode.setGhostStyle(isValid: valid)
        ghostNode.alpha = 1.0
    }

    // MARK: - Visuals

    /// Builds a placed-cell node with the same 5-layer 3D bevel used in BlockNode.
    private func makePlacedCellNode(color: NeonColor) -> SKShapeNode {
        let container = SKShapeNode()
        container.zPosition   = 10
        container.strokeColor = SKColor.neon(color)   // used by spawnSparks as colour hint
        container.fillColor   = .clear

        let fullSize = CGSize(width: cellSize * 0.90, height: cellSize * 0.90)
        let corner   = cellSize * 0.20
        let bevelW   = max(1.5, cellSize * 0.12)

        // 1 — base fill
        let fill = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        fill.fillColor   = SKColor.neon(color).withAlphaComponent(0.82)
        fill.strokeColor = .clear
        fill.lineWidth   = 0
        fill.zPosition   = 1
        container.addChild(fill)

        // 2 — bevel highlight (top-left)
        let hi = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        hi.fillColor   = SKColor(white: 1.0, alpha: 0.28)
        hi.strokeColor = .clear
        hi.lineWidth   = 0
        hi.position    = CGPoint(x: -bevelW * 0.5, y: bevelW * 0.5)
        hi.blendMode   = .add
        hi.zPosition   = 2
        container.addChild(hi)

        // 3 — bevel shadow (bottom-right)
        let shad = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        shad.fillColor   = SKColor(white: 0.0, alpha: 0.32)
        shad.strokeColor = .clear
        shad.lineWidth   = 0
        shad.position    = CGPoint(x: bevelW * 0.5, y: -bevelW * 0.5)
        shad.zPosition   = 2
        container.addChild(shad)

        // 4 — dark inner border
        let darkEdge = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        darkEdge.fillColor    = .clear
        darkEdge.strokeColor  = SKColor(white: 0.0, alpha: 0.40)
        darkEdge.lineWidth    = max(1.0, cellSize * 0.05)
        darkEdge.glowWidth    = 0
        darkEdge.zPosition    = 3
        container.addChild(darkEdge)

        // 5 — neon glow ring
        let ring = SKShapeNode(rectOf: fullSize, cornerRadius: corner)
        ring.fillColor   = .clear
        ring.strokeColor = SKColor.neon(color).withAlphaComponent(0.90)
        ring.lineWidth   = max(1.0, cellSize * 0.065)
        ring.glowWidth   = max(1.0, cellSize * 0.08)
        ring.zPosition   = 4
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
        for (i, p) in points.enumerated() {
            guard let node = placedNodes[p.row][p.col] else { continue }
            placedNodes[p.row][p.col] = nil

            spawnNeonShards(at: node.position, baseColor: node.strokeColor)

            // Staggered pop-out — each cell slightly delayed for wave effect
            let delay = Double(i) * 0.007
            let burst = SKAction.group([
                .fadeOut(withDuration: 0.13),
                .scale(to: 0.35, duration: 0.13),
            ])
            node.run(.sequence([.wait(forDuration: delay), burst, .removeFromParent()]))
        }
    }

    /// Dramatic neon shard burst — mix of dots and elongated rectangles.
    private func spawnNeonShards(at position: CGPoint, baseColor: SKColor, count: Int = 10) {
        let accents: [SKColor] = [
            baseColor,
            baseColor.withAlphaComponent(0.65),
            SKColor(white: 1.0, alpha: 0.88),
        ]
        for i in 0..<count {
            let useRect = (i % 3 == 0)
            let particle: SKShapeNode
            if useRect {
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

    // MARK: - Prompt 4.2: Palette, Shake, and New Methods

    /// Returns the next colour from the active palette in round-robin order.
    private func nextPaletteColor() -> NeonColor {
        let c = activePalette[paletteColorCursor % activePalette.count]
        paletteColorCursor += 1
        return c
    }

    /// Screen shake via camera oscillation.
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

    /// Cycles to the next palette and flashes the grid to signal the change.
    private func triggerPaletteShift() {
        currentPaletteIndex += 1
        paletteColorCursor   = 0
        let newPrimary = SKColor.neon(activePalette[0])
        animatePaletteFlash(primarySKColor: newPrimary)
        // Immediately rebuild tray with new palette colours
        for i in 0..<3 {
            guard let item = trayData[i], let node = tray[i] else { continue }
            let newColor = nextPaletteColor()
            trayData[i]  = (shape: item.shape, color: newColor)
            // Rebuild tray node in new colour
            tray[i]?.removeFromParent()
            let newNode = BlockNode(shape: item.shape, color: newColor, cellSize: node.cellSize)
            tray[i] = newNode
            trayLayer.addChild(newNode)
        }
        layoutTray()
    }

    /// Full-grid coloured flash signalling a palette switch.
    private func animatePaletteFlash(primarySKColor: SKColor) {
        // Screen-wide colour screen overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor   = primarySKColor.withAlphaComponent(0.22)
        overlay.strokeColor = .clear
        overlay.blendMode   = .screen
        overlay.position    = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        overlay.zPosition   = 500
        effectsLayer.addChild(overlay)
        overlay.run(.sequence([.fadeOut(withDuration: 0.50), .removeFromParent()]))

        // Pulse all placed blocks
        for row in 0..<GridManager.gridSize {
            for col in 0..<GridManager.gridSize {
                placedNodes[row][col]?.run(.sequence([
                    .fadeAlpha(to: 0.35, duration: 0.06),
                    .fadeAlpha(to: 1.00, duration: 0.18)
                ]))
            }
        }
    }

    /// Full-grid white flash + radial burst fired when a board-clear is scored (+10 000).
    private func animateBoardClearFlash() {
        // Spawn a dense ring of extra-bright sparks from grid centre
        let centre = CGPoint(
            x: gridOrigin.x + cellSize * CGFloat(GridManager.gridSize) * 0.5,
            y: gridOrigin.y + cellSize * CGFloat(GridManager.gridSize) * 0.5
        )
        let neonColors: [SKColor] = [
            SKColor(red: 0, green: 1, blue: 1, alpha: 1),     // cyan
            SKColor(red: 1, green: 0, blue: 1, alpha: 1),     // magenta
            SKColor(red: 0.2, green: 1, blue: 0.2, alpha: 1), // lime
            SKColor(red: 1, green: 0.95, blue: 0, alpha: 1),  // yellow
        ]
        for i in 0..<48 {
            let dot = SKShapeNode(circleOfRadius: max(2, cellSize * 0.07))
            dot.fillColor   = neonColors[i % neonColors.count].withAlphaComponent(0.95)
            dot.strokeColor = .clear
            dot.glowWidth   = cellSize * 0.35
            dot.position    = centre
            dot.zPosition   = 250
            effectsLayer.addChild(dot)

            let angle = CGFloat(i) / 48.0 * 2.0 * .pi + CGFloat.random(in: -0.2...0.2)
            let dist  = CGFloat.random(in: cellSize * 1.5...cellSize * 5.0)
            let move  = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.45)
            move.timingMode = .easeOut
            dot.run(.sequence([
                .group([move, .fadeOut(withDuration: 0.45), .scale(to: 0.05, duration: 0.45)]),
                .removeFromParent()
            ]))
        }

        // Full-screen white flash overlay
        let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        flash.fillColor   = SKColor.white.withAlphaComponent(0.18)
        flash.strokeColor = .clear
        flash.position    = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        flash.zPosition   = 300
        effectsLayer.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
    }

    // MARK: - Game Over

    private var currentScore: Int {
        return scoreManager.score
    }

    /// Prompt 3.3 — after clearing is finished, assess all three tray shapes.
    /// Sets isGameOver to TRUE  when no shape can fit anywhere.
    /// Sets isGameOver to FALSE when at least one shape CAN fit (un-does any
    /// premature game-over set by the pre-clear check inside consumeTrayItem).
    private func checkGameOverIfNeeded() {
        let shapes: [BlockShape] = trayData.compactMap { $0?.shape }
        guard shapes.isEmpty == false else { return }   // tray still being filled
        let hasMove = grid.anyMovePossible(shapes: shapes)
        // Bidirectional assignment: also clears a false-positive from pre-clear check
        scoreManager.isGameOver = !hasMove
    }

    private func saveCurrentState() {
        if adventurePreset != nil { return }
        
        if scoreManager.isGameOver {
            gameStateManager.clearState()
            return
        }
        
        gameStateManager.saveState(
            score: scoreManager.score,
            combo: scoreManager.combo,
            paletteIndex: currentPaletteIndex,
            paletteCursor: paletteColorCursor,
            grid: grid.cells,
            tray: trayData
        )
    }
}
