//
//  AdventureGameEngine.swift
//  NeonGridBuster
//
//  Adventure Mode — Game Engine (Prompt 1)
//  ─────────────────────────────────────────────────────────────────────────
//  A self-contained ObservableObject that drives a single Adventure level.
//
//  Responsibilities:
//   • Load a level from AdventureRegistry and initialise the grid.
//   • Manage the tray of 3 draggable block shapes (reuses BlockGenerator).
//   • Track `remainingTargets` — a live counter per gem type.
//   • Set `isLevelWon`  when all targets reach 0.
//   • Set `isGameOver` when no tray piece can fit anywhere on the grid.
//   • Expose helpers for the view layer (GameScene adapter) to call.
//

import Foundation
import Combine

// MARK: - AdventureGameEngine

@MainActor
final class AdventureGameEngine: ObservableObject {

    // ── Published State ───────────────────────────────────────────────────

    /// The level currently being played.
    @Published private(set) var currentLevel: AdventureLevel

    /// Live countdown per gem type. The level is won when every value == 0.
    @Published private(set) var remainingTargets: [TargetGem: Int]

    /// Fires when all `remainingTargets` reach 0.
    @Published private(set) var isLevelWon: Bool = false

    /// Fires when no tray piece can fit anywhere on the grid.
    @Published private(set) var isGameOver: Bool = false

    /// Current score (cell-fill + line-clear points — same formula as Classic).
    @Published private(set) var score: Int = 0

    /// Convenience: combo streak. Mirrors ScoreManager's concept.
    @Published private(set) var combo: Int = 0

    // ── Grid & Generator ──────────────────────────────────────────────────

    /// 3-state grid manager (wraps GridManager; tracks target gem cells).
    let grid = AdventureGridManager()

    /// Reuses the Classic Mode shape generator; mercy-check always active.
    private let generator = BlockGenerator()

    // ── Tray State ────────────────────────────────────────────────────────

    /// Current tray of up to 3 shapes (nil slot = consumed).
    @Published private(set) var trayData: [(shape: BlockShape, color: NeonColor)?] = [nil, nil, nil]

    // ── Private ───────────────────────────────────────────────────────────

    private var lastMoveCleared = false
    private var comboGraceMoves = 0

    // ── Init ─────────────────────────────────────────────────────────────

    init(levelID: Int = 1) {
        let level = AdventureRegistry.level(for: levelID) ?? AdventureRegistry.all[0]
        self.currentLevel     = level
        self.remainingTargets = level.targets
        // Grid is loaded after init so the view can observe changes
    }

    // MARK: - Public Setup

    /// Call this once after the engine is attached to a view / scene.
    func startLevel() {
        grid.load(level: currentLevel)
        score = 0
        combo = 0
        lastMoveCleared  = false
        comboGraceMoves  = 0
        remainingTargets = currentLevel.targets
        isLevelWon       = false
        isGameOver       = false
        refillTray()
    }

    /// Reload the same level (retry / replay).
    func restartLevel() {
        startLevel()
    }

    // MARK: - Tray Management

    /// Generates 3 new shapes and colours for the tray.
    func refillTray() {
        // Use a temporary GridManager copy for the generator's mercy-check
        let tempGrid = buildTempGrid()
        let rawItems = generator.generateTray(score: score, grid: tempGrid)
        trayData = rawItems.map { $0 }
        checkGameOverIfNeeded()
    }

    /// Marks tray slot `index` as consumed. Refills when all 3 are gone.
    func consumeTrayItem(at index: Int) {
        precondition(index >= 0 && index < 3)
        trayData[index] = nil
        if trayData.allSatisfy({ $0 == nil }) {
            refillTray()
        }
    }

    // MARK: - Move Application

    /// Called by the game scene after a successful placement + clear pass.
    ///
    /// - Parameters:
    ///   - placed:        Grid points occupied by the newly placed shape.
    ///   - placedColor:   Colour of the placed shape.
    ///   - origin:        Grid origin of the placed shape.
    ///   - trayIndex:     Slot index that was consumed.
    ///   - shape:         The block shape that was placed.
    func applyMove(
        shape:      BlockShape,
        color:      NeonColor,
        at origin:  GridPoint,
        trayIndex:  Int
    ) {
        // 1. Place on the adventure grid
        let placed = grid.place(shape: shape, color: color, at: origin)

        // 2. Clear filled lines & collect any gems that were cleared
        let cleared = grid.clearFilledLines()
        let gemsCleared = grid.lastClearedGems

        // 3. Update remaining targets
        for gem in gemsCleared {
            if let current = remainingTargets[gem] {
                remainingTargets[gem] = max(0, current - 1)
            }
        }

        // 4. Update combo counter (same grace-period logic as Classic ScoreManager)
        let totalLines = cleared.clearedRows.count + cleared.clearedCols.count
        if totalLines > 0 {
            combo = (combo > 0) ? combo + 1 : 1
            lastMoveCleared = true
            comboGraceMoves = 2
        } else {
            if comboGraceMoves > 0 {
                comboGraceMoves -= 1
                lastMoveCleared = false
            } else {
                combo = 0
                lastMoveCleared = false
            }
        }

        // 5. Score
        let cellPoints  = placed.count * 2
        let comboMult   = totalLines > 0 ? combo : 1
        let linePoints  = ScoreManager.lineScore(for: totalLines) * comboMult
        let boardBonus  = cleared.isBoardClear ? 10_000 : 0
        score += cellPoints + linePoints + boardBonus

        // 6. Consume tray item
        consumeTrayItem(at: trayIndex)

        // 7. Win check
        checkWinCondition()

        // 8. If not won, check game-over
        if !isLevelWon {
            checkGameOverIfNeeded()
        }
    }

    // MARK: - Win / Game-Over

    private func checkWinCondition() {
        let allCleared = remainingTargets.values.allSatisfy { $0 == 0 }
        if allCleared && currentLevel.hasTargets {
            isLevelWon = true
        }
    }

    private func checkGameOverIfNeeded() {
        guard !isLevelWon else { return }
        let shapes = trayData.compactMap { $0?.shape }
        guard !shapes.isEmpty else { return }
        if !grid.anyMovePossible(shapes: shapes) {
            isGameOver = true
        }
    }

    // MARK: - Helpers

    /// Builds a temporary vanilla GridManager from the current adventure grid
    /// so BlockGenerator's mercy-check works correctly.
    private func buildTempGrid() -> GridManager {
        let temp = GridManager()
        let colorPreset = grid.cellStates.map { row in
            row.map { $0.renderColor }
        }
        temp.loadPreset(colorPreset)
        return temp
    }

    // ── Progress Accessors ─────────────────────────────────────────────────

    /// Fraction of targets cleared so far (0.0 → 1.0).
    var progressFraction: Double {
        let total    = currentLevel.totalGemCount
        let cleared  = currentLevel.targets.reduce(0) { acc, pair in
            acc + pair.value - (remainingTargets[pair.key] ?? 0)
        }
        guard total > 0 else { return 1.0 }
        return Double(cleared) / Double(total)
    }
}
