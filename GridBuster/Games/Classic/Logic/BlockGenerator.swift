//
//  BlockGenerator.swift
//  NeonGridBuster
//
//  Prompt 3.1 — Block Definitions, Grid State, and Spawning Algorithm.
//
//  ─────────────────────────────────────────────────────────────────────────
//  Architecture
//  ─────────────────────────────────────────────────────────────────────────
//  • All shapes are declared in ShapeLibrary with an explicit ShapeTier and
//    a spawnWeight integer (higher = more likely to appear).
//  • WeightedPool builds a cumulative-weight table and performs O(log N)
//    weighted random sampling (no pool-repetition hack).
//  • BlockGenerator.generateTray(score:grid:) spawns exactly 3 shapes per
//    round using the following rules:
//      – FAIRNESS CHECK ALWAYS ON: every tray is guaranteed to have at least
//        one move, and where possible, all 3 shapes will fit individually.
//      – Fallback to emergency shapes (1×1, 1×2) if the board is nearly full.
//  • Tier weights shift with score so harder shapes appear more often as
//    the game progresses.
//  ─────────────────────────────────────────────────────────────────────────

import Foundation

// MARK: - Shape Tier

/// Difficulty classification for each block shape.
enum ShapeTier: Int, CaseIterable {
    /// 1×1, 1×2 dominoes — always easy to place
    case easy   = 0
    /// 3-cell L-corners, 1×3 lines, 2×2 squares
    case medium = 1
    /// 4-cell shapes, Z/S tetrominoes, long 4-lines
    case hard   = 2
    /// 5+ cell shapes: 3×3, 1×5, T, Plus, 6-lines, complex
    case brutal = 3
}

// MARK: - Shape Entry

/// A shape + its spawn-weight used for weighted random selection.
struct ShapeEntry {
    let shape:      BlockShape
    let tier:       ShapeTier
    /// Relative likelihood of being chosen (higher = more frequent).
    let spawnWeight: Int
}

// MARK: - Weighted Pool

/// Builds a cumulative-weight table and draws random entries in O(log N).
private struct WeightedPool<T> {
    private let entries:     [T]
    private let cumulative:  [Int]   // prefix sums of weights
    private let totalWeight: Int

    init(entries: [(item: T, weight: Int)]) {
        precondition(entries.isEmpty == false, "WeightedPool requires at least one entry")
        var items: [T]   = []
        var cum:   [Int] = []
        var total  = 0
        for e in entries {
            items.append(e.item)
            total += max(1, e.weight)
            cum.append(total)
        }
        self.entries     = items
        self.cumulative  = cum
        self.totalWeight = total
    }

    /// Returns a random element respecting weights (uniform fallback when empty).
    func randomElement(using rng: inout some RandomNumberGenerator) -> T {
        let roll = Int.random(in: 0..<totalWeight, using: &rng)
        // Binary-search the cumulative array
        var lo = 0, hi = cumulative.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if cumulative[mid] <= roll { lo = mid + 1 } else { hi = mid }
        }
        return entries[lo]
    }
}

// MARK: - Shape Library

/// Central registry: every shape with its tier and spawn weight.
enum ShapeLibrary {

    // ──────────────────────────────────────────────────────────────────────
    // EASY tier  (small, always fits, very high weights early on)
    // ──────────────────────────────────────────────────────────────────────
    static let easy: [ShapeEntry] = [
        ShapeEntry(
            shape: BlockShape(id: "1x1",
                cells: [BlockCell(x: 0, y: 0)]),
            tier: .easy, spawnWeight: 18),

        ShapeEntry(
            shape: BlockShape(id: "2h",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0)]),
            tier: .easy, spawnWeight: 16),

        ShapeEntry(
            shape: BlockShape(id: "2v",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1)]),
            tier: .easy, spawnWeight: 16),

        ShapeEntry(
            shape: BlockShape(id: "Diag2",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 1)]),
            tier: .easy, spawnWeight: 10),
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MEDIUM tier  (3-cell lines, 2×2 square, small L-bends)
    // ──────────────────────────────────────────────────────────────────────
    static let medium: [ShapeEntry] = [
        ShapeEntry(
            shape: BlockShape(id: "3h",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0)]),
            tier: .medium, spawnWeight: 14),

        ShapeEntry(
            shape: BlockShape(id: "3v",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2)]),
            tier: .medium, spawnWeight: 14),

        ShapeEntry(
            shape: BlockShape(id: "2x2", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1)]),
            tier: .medium, spawnWeight: 12),

        // Small L (3 blocks) — all four rotations
        ShapeEntry(
            shape: BlockShape(id: "L3_UR",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 1, y: 1)]),
            tier: .medium, spawnWeight: 10),

        ShapeEntry(
            shape: BlockShape(id: "L3_UL",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 0, y: 1)]),
            tier: .medium, spawnWeight: 10),

        ShapeEntry(
            shape: BlockShape(id: "L3_DR",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 0)]),
            tier: .medium, spawnWeight: 10),

        ShapeEntry(
            shape: BlockShape(id: "L3_DL",
                cells: [BlockCell(x: 1, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 0, y: 0)]),
            tier: .medium, spawnWeight: 10),

        ShapeEntry(
            shape: BlockShape(id: "Diag3",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 2)]),
            tier: .medium, spawnWeight: 7),

        ShapeEntry(
            shape: BlockShape(id: "Diag3Inv",
                cells: [BlockCell(x: 2, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 0, y: 2)]),
            tier: .medium, spawnWeight: 7),
    ]

    // ──────────────────────────────────────────────────────────────────────
    // HARD tier  (4-cell shapes, long lines, Z/S)
    // ──────────────────────────────────────────────────────────────────────
    static let hard: [ShapeEntry] = [
        ShapeEntry(
            shape: BlockShape(id: "4h",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0)]),
            tier: .hard, spawnWeight: 12),

        ShapeEntry(
            shape: BlockShape(id: "4v",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2), BlockCell(x: 0, y: 3)]),
            tier: .hard, spawnWeight: 12),

        ShapeEntry(
            shape: BlockShape(id: "Z4",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1)]),
            tier: .hard, spawnWeight: 10),

        ShapeEntry(
            shape: BlockShape(id: "S4",
                cells: [BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1)]),
            tier: .hard, spawnWeight: 10),

        // L-shaped 4-block (all four rotations)
        ShapeEntry(
            shape: BlockShape(id: "L4_UR",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 2, y: 1)]),
            tier: .hard, spawnWeight: 9),

        ShapeEntry(
            shape: BlockShape(id: "L4_UL",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 0, y: 1)]),
            tier: .hard, spawnWeight: 9),

        ShapeEntry(
            shape: BlockShape(id: "L4_DR",
                cells: [BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1), BlockCell(x: 2, y: 0)]),
            tier: .hard, spawnWeight: 9),

        ShapeEntry(
            shape: BlockShape(id: "L4_DL",
                cells: [BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1), BlockCell(x: 0, y: 0)]),
            tier: .hard, spawnWeight: 9),

        ShapeEntry(
            shape: BlockShape(id: "DiagStack4",
                cells: [
                    BlockCell(x: 0, y: 0),
                    BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
                    BlockCell(x: 1, y: 2)]),
            tier: .hard, spawnWeight: 7),

        ShapeEntry(
            shape: BlockShape(id: "DiagStack4Inv",
                cells: [
                    BlockCell(x: 1, y: 0),
                    BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
                    BlockCell(x: 0, y: 2)]),
            tier: .hard, spawnWeight: 7),

        ShapeEntry(
            shape: BlockShape(id: "3x2", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1)]),
            tier: .hard, spawnWeight: 8),

        ShapeEntry(
            shape: BlockShape(id: "2x3", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
                BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2)]),
            tier: .hard, spawnWeight: 8),
    ]

    // ──────────────────────────────────────────────────────────────────────
    // BRUTAL tier  (5+ cell shapes, 1×5 lines, 3×3, T, Plus, U…)
    // ──────────────────────────────────────────────────────────────────────
    static let brutal: [ShapeEntry] = [
        ShapeEntry(
            shape: BlockShape(id: "1x5h",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0), BlockCell(x: 4, y: 0)]),
            tier: .brutal, spawnWeight: 14),

        ShapeEntry(
            shape: BlockShape(id: "1x5v",
                cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2), BlockCell(x: 0, y: 3), BlockCell(x: 0, y: 4)]),
            tier: .brutal, spawnWeight: 14),

        ShapeEntry(
            shape: BlockShape(id: "T5", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
                BlockCell(x: 1, y: 1), BlockCell(x: 1, y: 2)]),
            tier: .brutal, spawnWeight: 10),

        ShapeEntry(
            shape: BlockShape(id: "3x3", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
                BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2), BlockCell(x: 2, y: 2)]),
            tier: .brutal, spawnWeight: 7),

        ShapeEntry(
            shape: BlockShape(id: "Plus5", cells: [
                                              BlockCell(x: 1, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
                                              BlockCell(x: 1, y: 2)]),
            tier: .brutal, spawnWeight: 9),

        ShapeEntry(
            shape: BlockShape(id: "U5", cells: [
                BlockCell(x: 0, y: 0),                      BlockCell(x: 2, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1)]),
            tier: .brutal, spawnWeight: 8),

        ShapeEntry(
            shape: BlockShape(id: "P5", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
                BlockCell(x: 0, y: 2)]),
            tier: .brutal, spawnWeight: 8),

        ShapeEntry(
            shape: BlockShape(id: "L5_UR", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2),
                BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0)]),
            tier: .brutal, spawnWeight: 8),

        ShapeEntry(
            shape: BlockShape(id: "L5_UL", cells: [
                BlockCell(x: 2, y: 0), BlockCell(x: 2, y: 1), BlockCell(x: 2, y: 2),
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0)]),
            tier: .brutal, spawnWeight: 8),

        ShapeEntry(
            shape: BlockShape(id: "L5_DR", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2),
                BlockCell(x: 1, y: 2), BlockCell(x: 2, y: 2)]),
            tier: .brutal, spawnWeight: 8),

        ShapeEntry(
            shape: BlockShape(id: "L5_DL", cells: [
                BlockCell(x: 2, y: 0), BlockCell(x: 2, y: 1), BlockCell(x: 2, y: 2),
                BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2)]),
            tier: .brutal, spawnWeight: 8),

        ShapeEntry(
            shape: BlockShape(id: "Corner5", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2),
                BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0)]),
            tier: .brutal, spawnWeight: 7),

        ShapeEntry(
            shape: BlockShape(id: "6h", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
                BlockCell(x: 3, y: 0), BlockCell(x: 4, y: 0), BlockCell(x: 5, y: 0)]),
            tier: .brutal, spawnWeight: 6),

        ShapeEntry(
            shape: BlockShape(id: "6v", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2),
                BlockCell(x: 0, y: 3), BlockCell(x: 0, y: 4), BlockCell(x: 0, y: 5)]),
            tier: .brutal, spawnWeight: 6),

        ShapeEntry(
            shape: BlockShape(id: "DominoStep6", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
                BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
                BlockCell(x: 2, y: 2), BlockCell(x: 3, y: 2)]),
            tier: .brutal, spawnWeight: 6),

        ShapeEntry(
            shape: BlockShape(id: "Hollow3", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
                BlockCell(x: 0, y: 1),                         BlockCell(x: 2, y: 1),
                BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2), BlockCell(x: 2, y: 2)]),
            tier: .brutal, spawnWeight: 5),

        ShapeEntry(
            shape: BlockShape(id: "4x2", cells: [
                BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0),
                BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1), BlockCell(x: 3, y: 1)]),
            tier: .brutal, spawnWeight: 5),
    ]

    /// All shapes joined — used for full-difficulty sampling.
    static let all: [ShapeEntry] = easy + medium + hard + brutal
    
    /// Lookup a shape by its unique string identifier (used for state deserialization).
    static func shape(for id: String) -> BlockShape? {
        return all.first(where: { $0.shape.id == id })?.shape
    }
}

// MARK: - BlockGenerator

/// Spawns exactly 3 shapes per round using weighted random selection.
/// Applies a mercy check when score < mercyThreshold so that at least
/// one piece always fits on the grid, keeping the game fair for new players.
final class BlockGenerator {

    // ── Configuration ────────────────────────────────────────────────────

    /// Maximum placement-search attempts before falling back to emergency tray.
    private let maxFairnessAttempts = 300
    private let exhaustiveDepth    = 64

    // ── RNG ──────────────────────────────────────────────────────────────
    private var rng = SystemRandomNumberGenerator()

    // MARK: - Public API

    /// Generates exactly 3 shapes for the tray.
    ///
    /// - Parameters:
    ///   - score: Current player score. Controls tier weights.
    ///   - grid: Current grid state used for fairness / solvability checks.
    func generateTray(score: Int, grid: GridManager) -> [(shape: BlockShape, color: NeonColor)] {
        // ── Fairness Mode: guarantee at least one piece fits, strive for all 3 ──
        if let shapes = generateFairTray(score: score, grid: grid) {
            return colorise(shapes)
        }
        // Safety fallback (shouldn't normally be reached)
        return colorise(emergencyTray(on: grid))
    }
    func generateEasyTray() -> [BlockShape] {
        let easyShapes = ShapeLibrary.easy.map(\.shape)
        guard !easyShapes.isEmpty else { return [] }
        // Draw 3 random easy shapes
        return (0..<3).compactMap { _ in easyShapes.randomElement(using: &rng) ?? easyShapes.first }
    }

    // MARK: - Fair Tray Generation

    /// Produces a tray where blocks are guaranteed to be placeable.
    /// Ensures that there exists at least one sequence to place ALL 3 blocks.
    private func generateFairTray(score: Int, grid: GridManager) -> [BlockShape]? {
        let pool = buildPool(for: score)

        // Attempt 1: All 3 fit sequentially (The most robust check)
        for _ in 0..<maxFairnessAttempts / 2 {
            let candidate = (0..<3).map { _ in pool.randomElement(using: &rng).shape }
            if canPlaceAllSequential(candidate, on: grid) {
                return candidate
            }
        }

        // Attempt 2: Fallback to easier shapes if hard ones don't fit together
        let easyPool = WeightedPool(entries: ShapeLibrary.easy.map { ($0, $0.spawnWeight) })
        for _ in 0..<maxFairnessAttempts / 4 {
            let candidate = [
                pool.randomElement(using: &rng).shape,
                easyPool.randomElement(using: &rng).shape,
                easyPool.randomElement(using: &rng).shape
            ].shuffled(using: &rng)
            
            if canPlaceAllSequential(candidate, on: grid) {
                return candidate
            }
        }

        // Final desperation: return 1x1 dots which always fit if any cell is empty
        let dot = ShapeLibrary.easy[0].shape
        return [dot, dot, dot]
    }

    /// Backtracking solver to verify if all shapes in a set can be placed sequentially.
    private func canPlaceAllSequential(_ shapes: [BlockShape], on grid: GridManager) -> Bool {
        if shapes.isEmpty { return true }
        
        // Try each shape as the next move
        for (i, shape) in shapes.enumerated() {
            // Find all valid placements
            let placements = grid.validPlacements(for: shape)
            if placements.isEmpty { continue }
            
            // To prevent O(N!) explosion on empty boards, we only sample a few placements
            // but prioritize ones that might clear lines.
            let sampledPlacements = placements.shuffled(using: &rng).prefix(12)
            
            for point in sampledPlacements {
                let nextGrid = grid.copy()
                _ = nextGrid.place(shape: shape, color: .cyan, at: point)
                _ = nextGrid.clearFilledLines()
                
                var remaining = shapes
                remaining.remove(at: i)
                
                if canPlaceAllSequential(remaining, on: nextGrid) {
                    return true
                }
            }
        }
        
        return false
    }

    // MARK: - Weighted Pool Construction

    /// Builds a `WeightedPool` whose tier-weight ratios shift with score.
    ///
    /// Score milestones:
    ///   < 500   → Easy-heavy
    ///   500-999 → Easy + Medium balance (mercy still active up to 1 000)
    ///  1000-2499 → Hard rises, brutal begins
    ///  2500-4999 → Medium fades, brutal prominent
    ///  5000+     → Near all Hard + Brutal — maximum difficulty
    private func buildPool(for score: Int) -> WeightedPool<ShapeEntry> {
        let tierWeights: (easy: Int, medium: Int, hard: Int, brutal: Int)

        switch score {
        case ..<500:
            tierWeights = (easy: 8, medium: 4, hard: 1, brutal: 0)
        case ..<1_000:
            tierWeights = (easy: 6, medium: 5, hard: 2, brutal: 0)
        case ..<2_500:
            tierWeights = (easy: 4, medium: 5, hard: 4, brutal: 1)
        case ..<5_000:
            tierWeights = (easy: 2, medium: 4, hard: 5, brutal: 3)
        case ..<10_000:
            tierWeights = (easy: 1, medium: 2, hard: 5, brutal: 4)
        default:
            tierWeights = (easy: 0, medium: 1, hard: 4, brutal: 5)
        }

        var entries: [(item: ShapeEntry, weight: Int)] = []

        for entry in ShapeLibrary.easy {
            let w = tierWeights.easy * entry.spawnWeight
            if w > 0 { entries.append((entry, w)) }
        }
        for entry in ShapeLibrary.medium {
            let w = tierWeights.medium * entry.spawnWeight
            if w > 0 { entries.append((entry, w)) }
        }
        for entry in ShapeLibrary.hard {
            let w = tierWeights.hard * entry.spawnWeight
            if w > 0 { entries.append((entry, w)) }
        }
        for entry in ShapeLibrary.brutal {
            let w = tierWeights.brutal * entry.spawnWeight
            if w > 0 { entries.append((entry, w)) }
        }

        // Always include at least easy shapes to avoid an empty pool
        if entries.isEmpty {
            entries = ShapeLibrary.easy.map { ($0, $0.spawnWeight) }
        }

        return WeightedPool(entries: entries)
    }

    // MARK: - Emergency Tray

    /// Last-resort: always-placeable tiny shapes when the board is nearly full.
    private func emergencyTray(on grid: GridManager) -> [BlockShape] {
        let tiny = ShapeLibrary.easy.map(\.shape) + ShapeLibrary.medium.prefix(3).map(\.shape)

        for shape in tiny.shuffled(using: &rng) {
            if grid.canPlaceAnywhere(shape: shape) {
                let second = tiny.randomElement(using: &rng) ?? ShapeLibrary.easy[0].shape
                let third  = tiny.randomElement(using: &rng) ?? ShapeLibrary.easy[1].shape
                return [shape, second, third].shuffled(using: &rng)
            }
        }

        // Absolute fallback — 1×1s always fit if any cell is empty
        let dot = ShapeLibrary.easy[0].shape
        return [dot, dot, dot]
    }

    // MARK: - Colour Assignment

    /// Assigns a random neon colour to each shape, avoiding same-colour repeats.
    private func colorise(_ shapes: [BlockShape]) -> [(shape: BlockShape, color: NeonColor)] {
        var lastColor: NeonColor? = nil
        return shapes.map { shape in
            var color: NeonColor
            repeat {
                color = NeonColor.allCases.randomElement(using: &rng) ?? .cyan
            } while color == lastColor && NeonColor.allCases.count > 1
            lastColor = color
            return (shape: shape, color: color)
        }
    }
}
