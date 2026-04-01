//
//  AdventureModels.swift
//  NeonGridBuster
//
//  Adventure Mode — Data Models (Prompt 1)
//  ─────────────────────────────────────────────────────────────────────────
//  Defines:
//   • TargetGem        — the collectible gem types (emerald, star, pentagon)
//   • GridCellState    — 3-state grid cell (empty / normal / target)
//   • AdventureLevel   — a complete level with its initial grid and targets
//   • AdventureRegistry — all authored levels, accessible by ID
//

import Foundation
import SwiftUI
import Combine

// MARK: - TargetGem

/// Distinguishes the different collectible gem types shown in the level HUD.
/// Each gem type is a separate counter that must reach 0 to win.
///
/// Visual reference:
///   • .emerald     — green diamond icon  (Level 1 screenshot)
///   • .star        — yellow star icon    (Level 3 screenshot)
///   • .orangePentagon — orange pentagon  (Level 3 screenshot)
enum TargetGem: String, CaseIterable, Codable, Hashable {
    case emerald        // 💎 green diamond  – neon lime/cyan colour
    case star           // ⭐ yellow star
    case orangePentagon // 🔶 orange pentagon
    case blueSapphire   // 🔷 blue hexagon / sapphire
    case redRuby        // 🔴 red ruby / heart

    /// SF Symbol name used in the HUD counter badge.
    var systemImage: String {
        switch self {
        case .emerald:        return "diamond.fill"
        case .star:           return "star.fill"
        case .orangePentagon: return "pentagon.fill"
        case .blueSapphire:   return "hexagon.fill"
        case .redRuby:        return "suit.heart.fill"
        }
    }

    /// Associated neon colour used to tint the gem's grid cell.
    var neonColor: NeonColor {
        switch self {
        case .emerald:        return .lime
        case .star:           return .yellow
        case .orangePentagon: return .orange
        case .blueSapphire:   return .blue
        case .redRuby:        return .red
        }
    }
}

// MARK: - GridCellState

/// The three possible states of a single grid cell in Adventure Mode.
///
/// Classic Mode only knows empty vs. filled (NeonColor?).
/// Adventure Mode adds a third state: a **target gem** that must be
/// cleared by completing a full row or column through it.
enum GridCellState: Equatable {
    /// The cell is completely empty.
    case empty

    /// The cell is occupied by a normal placed block (carries the colour
    /// of the piece the player dropped there).
    case normal(NeonColor)

    /// The cell is a pre-placed **target gem** that the player must clear.
    case target(TargetGem)

    // MARK: Convenience

    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }

    var isOccupied: Bool { !isEmpty }

    /// Returns the NeonColor to render for this cell (nil = empty).
    var renderColor: NeonColor? {
        switch self {
        case .empty:             return nil
        case .normal(let c):     return c
        case .target(let gem):   return gem.neonColor
        }
    }

    /// If this is a target cell, returns the gem; otherwise nil.
    var gem: TargetGem? {
        if case .target(let g) = self { return g }
        return nil
    }
}

// MARK: - AdventureLevel

/// A complete, authored Adventure Mode level.
///
/// The `initialGrid` is an 8×8 matrix of `GridCellState`. Most cells are
/// `.empty`. Some are `.target(gem)` (pre-placed gems the player must clear).
/// No cells should be `.normal` in the initial grid; that state is only used
/// at runtime after the player drops blocks.
///
/// `targets` maps each required gem type to how many must be cleared
/// (i.e. how many times a full line must pass through that gem type).
struct AdventureLevel: Identifiable {
    let id:          Int                    // level number (1-indexed)
    let title:       String
    let subtitle:    String

    /// 8×8 initial grid (row-major, row 0 = top).
    let initialGrid: [[GridCellState]]

    /// Win condition: every entry must reach 0 to trigger level-complete.
    let targets:     [TargetGem: Int]

    /// Whether the player has already beaten this level.
    var isCompleted: Bool = false

    // ── Convenience ──────────────────────────────────────────────────────

    /// Total number of gems that must be cleared across all types.
    var totalGemCount: Int {
        targets.values.reduce(0, +)
    }

    /// Returns true when the level has at least one target.
    var hasTargets: Bool { !targets.isEmpty }
}

// MARK: - AdventureRegistry

/// Central catalogue of all authored Adventure Mode levels.
///
/// Levels are identified by their `.id` (1-indexed).
/// Use `level(for:)` to fetch a specific level safely.
enum AdventureRegistry {

    // ── Helpers ───────────────────────────────────────────────────────────

    private static func emptyGrid() -> [[GridCellState]] {
        Array(repeating: Array(repeating: .empty, count: 8), count: 8)
    }

    private static func buildGrid(
        targets: [(row: Int, col: Int, gem: TargetGem)]
    ) -> [[GridCellState]] {
        var grid = emptyGrid()
        for t in targets {
            grid[t.row][t.col] = .target(t.gem)
        }
        return grid
    }

    // ── Level Definitions ─────────────────────────────────────────────────

    /// Level 1 — "Emerald Hunt"
    /// 6 emeralds scattered across the grid.
    /// Reference: first screenshot — green diamonds on a sparse board.
    static let level1 = AdventureLevel(
        id: 1,
        title: "Emerald Hunt",
        subtitle: "Clear 6 emeralds",
        initialGrid: buildGrid(targets: [
            (row: 2, col: 0, gem: .emerald),   // left-centre
            (row: 2, col: 7, gem: .emerald),   // right-centre
            (row: 4, col: 3, gem: .emerald),   // middle pair
            (row: 4, col: 4, gem: .emerald),
            (row: 6, col: 1, gem: .emerald),   // lower left-of-centre
            (row: 6, col: 5, gem: .emerald),   // lower right-of-centre
        ]),
        targets: [.emerald: 6]
    )

    /// Level 2 — "Star & Pentagon"
    /// 4 stars + 4 orange pentagons alternating around the border.
    /// Reference: fourth screenshot — stars (top/corners) and pentagons (middle rows).
    static let level2 = AdventureLevel(
        id: 2,
        title: "Neon Mix",
        subtitle: "Clear 4 stars and 4 rubies",
        initialGrid: buildGrid(targets: [
            // Stars — along the top and vertical axis
            (row: 0, col: 2, gem: .star),
            (row: 0, col: 5, gem: .star),
            (row: 2, col: 0, gem: .star),
            (row: 2, col: 7, gem: .star),
            // Rubies — mid-grid
            (row: 4, col: 2, gem: .redRuby),
            (row: 4, col: 5, gem: .redRuby),
            (row: 6, col: 0, gem: .redRuby),
            (row: 6, col: 7, gem: .redRuby),
        ]),
        targets: [.star: 4, .redRuby: 4]
    )

    /// Level 3 — "Jewel Collection"
    /// 3 sapphires + 3 pentagons + 3 emeralds.
    static let level3 = AdventureLevel(
        id: 3,
        title: "Jewel Collection",
        subtitle: "9 gems to collect",
        initialGrid: buildGrid(targets: [
            (row: 1, col: 1, gem: .blueSapphire),
            (row: 1, col: 6, gem: .blueSapphire),
            (row: 3, col: 3, gem: .blueSapphire),
            (row: 5, col: 1, gem: .orangePentagon),
            (row: 5, col: 3, gem: .orangePentagon),
            (row: 5, col: 6, gem: .orangePentagon),
            (row: 7, col: 2, gem: .emerald),
            (row: 7, col: 4, gem: .emerald),
            (row: 7, col: 6, gem: .emerald),
        ]),
        targets: [.blueSapphire: 3, .orangePentagon: 3, .emerald: 3]
    )

    // ── Registry ──────────────────────────────────────────────────────────

    /// Ordered list of all available levels.
    static let all: [AdventureLevel] = [level1, level2, level3]

    /// Returns the level with the given 1-indexed ID, or nil if out of range.
    static func level(for id: Int) -> AdventureLevel? {
        all.first { $0.id == id }
    }

    /// Converts an `AdventureLevel`'s `initialGrid` into the `[[NeonColor?]]`
    /// format required by the existing `GridManager.loadPreset(_:)`.
    ///
    /// Target gem cells are represented by their associated `NeonColor`.
    /// The caller should use `AdventureGridManager` (not this) for runtime play.
    static func colorPreset(for level: AdventureLevel) -> [[NeonColor?]] {
        level.initialGrid.map { row in
            row.map { $0.renderColor }
        }
    }
}

// MARK: - AdventureGridManager

/// A drop-in companion to `GridManager` that tracks the 3-state grid
/// required by Adventure Mode.
///
/// • Wraps `GridManager` for placement / line-clearing logic.
/// • Maintains a parallel `[[GridCellState]]` matrix so the view layer
///   can distinguish target cells from normal fills.
/// • `consumedGems` accumulates which gems were cleared in the last move,
///   consumed by `AdventureGameEngine` to update `remainingTargets`.
final class AdventureGridManager: ObservableObject {

    // ── State ─────────────────────────────────────────────────────────────

    /// Full 3-state cell matrix. Row-major; (0,0) = top-left.
    @Published private(set) var cellStates: [[GridCellState]] =
        Array(repeating: Array(repeating: .empty, count: GridManager.gridSize),
              count: GridManager.gridSize)

    /// Gems cleared in the most recent `clearFilledLines()` call.
    @Published private(set) var lastClearedGems: [TargetGem] = []

    // ── Private backing grid ──────────────────────────────────────────────

    private let core = GridManager()

    // ── Init ─────────────────────────────────────────────────────────────

    /// Loads an authored level's initial grid into both the state matrix
    /// and the backing `GridManager` (for collision detection).
    func load(level: AdventureLevel) {
        cellStates = level.initialGrid
        // Sync backing grid — target cells count as "occupied"
        let colorPreset = AdventureRegistry.colorPreset(for: level)
        core.reset()
        core.loadPreset(colorPreset)
    }

    func reset() {
        core.reset()
        cellStates = Array(
            repeating: Array(repeating: .empty, count: GridManager.gridSize),
            count: GridManager.gridSize
        )
        lastClearedGems = []
    }

    // ── Placement ─────────────────────────────────────────────────────────

    func canPlace(shape: BlockShape, at origin: GridPoint) -> Bool {
        core.canPlace(shape: shape, at: origin)
    }

    /// Places `shape` on the grid and returns the list of placed `GridPoint`s.
    /// In Adventure Mode, a tray block can optionally carry a `TargetGem`.
    @discardableResult
    func place(shape: BlockShape, color: NeonColor, at origin: GridPoint, gem: TargetGem? = nil) -> [GridPoint] {
        let placed = core.place(shape: shape, color: color, at: origin)
        for (idx, p) in placed.enumerated() {
            if idx == 0, let g = gem {
                // This cell becomes a target gem pre-placed inside the block
                cellStates[p.row][p.col] = .target(g)
            } else {
                cellStates[p.row][p.col] = .normal(color)
            }
        }
        return placed
    }

    // ── Line Clearing ─────────────────────────────────────────────────────

    /// Mirrors `GridManager.clearFilledLines()` while additionally:
    ///  - collecting any `.target` gems in cleared cells → `lastClearedGems`
    ///  - updating `cellStates` to `.empty` for every cleared point
    ///
    /// Returns the same `ClearResult` as the underlying `GridManager`.
    @discardableResult
    func clearFilledLines() -> GridManager.ClearResult {
        let result = core.clearFilledLines()

        var gems: [TargetGem] = []
        for p in result.clearedPoints {
            if case .target(let gem) = cellStates[p.row][p.col] {
                gems.append(gem)
            }
            cellStates[p.row][p.col] = .empty
        }
        lastClearedGems = gems
        return result
    }

    // ── Game-over check ───────────────────────────────────────────────────

    func anyMovePossible(shapes: [BlockShape]) -> Bool {
        core.anyMovePossible(shapes: shapes)
    }

    func canPlaceAnywhere(shape: BlockShape) -> Bool {
        core.canPlaceAnywhere(shape: shape)
    }
}
