//
//  BlockGenerator.swift
//  NeonGridBuster
//

import Foundation

final class BlockGenerator {
    private var rng = SystemRandomNumberGenerator()

    func generateTray(score: Int, grid: GridManager) -> [(shape: BlockShape, color: NeonColor)] {
        if let shapes = findSolvableTray(from: weightedPool(for: score), on: grid, attempts: 180, exhaustiveDepth: 24) {
            return assignColors(to: shapes)
        }

        if let shapes = findSolvableTray(from: safetyPool(for: score), on: grid, attempts: 260, exhaustiveDepth: 36) {
            return assignColors(to: shapes)
        }

        return assignColors(to: emergencyTray(on: grid))
    }

    private func assignColors(to shapes: [BlockShape]) -> [(shape: BlockShape, color: NeonColor)] {
        shapes.map { shape in
            (shape: shape, color: NeonColor.allCases.randomElement(using: &rng) ?? .cyan)
        }
    }

    private func weightedPool(for score: Int) -> [BlockShape] {
        let easyLines = Self.shapes(
            "4h", "4v", "1x5h", "1x5v", "5h", "5v"
        )
        let easyShapes = Self.shapes(
            "Diag2", "L3_UR", "L3_UL", "L3_DR", "L3_DL", "Z4", "S4", "3x2", "2x3"
        )
        let mediumShapes = Self.shapes(
            "L4_UR", "L4_UL", "L4_DR", "L4_DL",
            "L5_UR", "L5_UL", "L5_DR", "L5_DL",
            "T5", "DiagStack4", "DiagStack4Inv", "Diag3", "Diag3Inv", "3x3"
        )
        let hardShapes = Self.shapes(
            "6h", "6v", "DominoStep6", "DominoStep6Inv", "4x2", "2x4", "Corner5", "Plus5", "P5", "U5", "Hollow3"
        )

        switch score {
        case ..<1200:
            return Self.simpleShapes.repeated(6)
                + easyLines.repeated(3)
                + easyShapes.repeated(2)
                + mediumShapes.repeated(1)
        case ..<3500:
            return Self.simpleShapes.repeated(4)
                + easyLines.repeated(3)
                + easyShapes.repeated(3)
                + mediumShapes.repeated(2)
                + hardShapes.repeated(1)
        case ..<7000:
            return Self.simpleShapes.repeated(2)
                + easyLines.repeated(3)
                + easyShapes.repeated(3)
                + mediumShapes.repeated(3)
                + hardShapes.repeated(2)
        default:
            return Self.simpleShapes.repeated(2)
                + easyLines.repeated(2)
                + easyShapes.repeated(3)
                + mediumShapes.repeated(3)
                + hardShapes.repeated(3)
        }
    }

    private func safetyPool(for score: Int) -> [BlockShape] {
        let approachable = Self.simpleShapes
            + Self.shapes("4h", "4v", "1x5h", "1x5v", "5h", "5v", "3x2", "2x3", "Z4", "S4")
            + Self.shapes("L3_UR", "L3_UL", "L3_DR", "L3_DL", "Diag2", "3x3")

        if score < 3500 {
            return approachable.repeated(4)
        }

        return (approachable + Self.shapes("L4_UR", "L4_UL", "L4_DR", "L4_DL", "T5", "Diag3", "Diag3Inv"))
            .repeated(3)
    }

    private func findSolvableTray(from pool: [BlockShape], on grid: GridManager, attempts: Int, exhaustiveDepth: Int) -> [BlockShape]? {
        guard pool.isEmpty == false else { return nil }

        for _ in 0..<attempts {
            let candidate = (0..<3).compactMap { _ in pool.randomElement(using: &rng) }
            if candidate.count == 3, isSolvableTray(candidate, on: grid) {
                return candidate
            }
        }

        let uniqueShapes = Array(Set(pool)).shuffled(using: &rng)
        let sample = Array(uniqueShapes.prefix(exhaustiveDepth))

        for first in sample {
            for second in sample {
                for third in sample {
                    let candidate = [first, second, third]
                    if isSolvableTray(candidate, on: grid) {
                        return candidate
                    }
                }
            }
        }

        return nil
    }

    private func isSolvableTray(_ shapes: [BlockShape], on grid: GridManager) -> Bool {
        solve(shapes: shapes, on: grid, depth: 0)
    }

    private func solve(shapes: [BlockShape], on grid: GridManager, depth: Int) -> Bool {
        if shapes.isEmpty {
            return true
        }

        for index in shapes.indices {
            let shape = shapes[index]
            let placements = prioritizedPlacements(for: shape, on: grid, depth: depth)

            for placement in placements {
                let nextGrid = grid.copy()
                _ = nextGrid.place(shape: shape, color: .cyan, at: placement)
                _ = nextGrid.clearFilledLines()

                var remaining = shapes
                remaining.remove(at: index)

                if solve(shapes: remaining, on: nextGrid, depth: depth + 1) {
                    return true
                }
            }
        }

        return false
    }

    private func prioritizedPlacements(for shape: BlockShape, on grid: GridManager, depth: Int) -> [GridPoint] {
        let placements = grid.validPlacements(for: shape)
        guard placements.count > 10 else { return placements }

        let center = Double(GridManager.gridSize - 1) / 2.0
        let scored = placements.map { placement -> (GridPoint, Double) in
            let rowDistance = abs(Double(placement.row) - center)
            let colDistance = abs(Double(placement.col) - center)
            return (placement, rowDistance + colDistance)
        }
        .sorted { lhs, rhs in lhs.1 < rhs.1 }
        .map(\.0)

        let limit = depth == 0 ? 14 : 10
        return Array(scored.prefix(limit))
    }

    private func emergencyTray(on grid: GridManager) -> [BlockShape] {
        let emergency = Self.simpleShapes + Self.shapes("4h", "4v", "1x5h", "1x5v", "3x2", "2x3")

        if let tray = findSolvableTray(from: emergency.repeated(5), on: grid, attempts: 200, exhaustiveDepth: emergency.count) {
            return tray
        }

        return [
            Self.shape("1x1"),
            Self.shape("2h"),
            Self.shape("2v"),
        ]
    }

    private static func shapes(_ ids: String...) -> [BlockShape] {
        ids.compactMap { shapeByID[$0] }
    }

    private static func shape(_ id: String) -> BlockShape {
        shapeByID[id]!
    }

    private static let simpleShapes: [BlockShape] = [
        BlockShape(id: "1x1", cells: [BlockCell(x: 0, y: 0)]),
        BlockShape(id: "2h", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0)]),
        BlockShape(id: "2v", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1)]),
        BlockShape(id: "3h", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0)]),
        BlockShape(id: "3v", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2)]),
        BlockShape(id: "2x2", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
        ]),
    ]

    private static let mediumShapes: [BlockShape] = [
        BlockShape(id: "4h", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0)]),
        BlockShape(id: "4v", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2), BlockCell(x: 0, y: 3)]),
        BlockShape(id: "1x5h", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0), BlockCell(x: 4, y: 0)]),
        BlockShape(id: "1x5v", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2), BlockCell(x: 0, y: 3), BlockCell(x: 0, y: 4)]),
        BlockShape(id: "Diag2", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 1)]),

        // Small L (3 blocks) in all rotations
        BlockShape(id: "L3_UR", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 1, y: 1)]),
        BlockShape(id: "L3_UL", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 0, y: 1)]),
        BlockShape(id: "L3_DR", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 0)]),
        BlockShape(id: "L3_DL", cells: [BlockCell(x: 1, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 0, y: 0)]),

        // L (4 blocks) in all rotations
        BlockShape(id: "L4_UR", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 2, y: 1)]),
        BlockShape(id: "L4_UL", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 0, y: 1)]),
        BlockShape(id: "L4_DR", cells: [BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1), BlockCell(x: 2, y: 0)]),
        BlockShape(id: "L4_DL", cells: [BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1), BlockCell(x: 0, y: 0)]),

        // L (5 blocks) legs length 3 + 3 (shared corner)
        BlockShape(id: "L5_UR", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2),
            BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
        ]),
        BlockShape(id: "L5_UL", cells: [
            BlockCell(x: 2, y: 0), BlockCell(x: 2, y: 1), BlockCell(x: 2, y: 2),
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
        ]),
        BlockShape(id: "L5_DR", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2),
            BlockCell(x: 1, y: 2), BlockCell(x: 2, y: 2),
        ]),
        BlockShape(id: "L5_DL", cells: [
            BlockCell(x: 2, y: 0), BlockCell(x: 2, y: 1), BlockCell(x: 2, y: 2),
            BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2),
        ]),

        BlockShape(id: "T5", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
            BlockCell(x: 1, y: 1), BlockCell(x: 1, y: 2),
        ]),
        BlockShape(id: "Z4", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1)]),
        BlockShape(id: "S4", cells: [BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1)]),
        BlockShape(id: "3x2", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
        ]),
        BlockShape(id: "2x3", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
            BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2),
        ]),
    ]

    private static let hardShapes: [BlockShape] = [
        // Long lines
        BlockShape(id: "5h", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0), BlockCell(x: 4, y: 0)]),
        BlockShape(id: "5v", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2), BlockCell(x: 0, y: 3), BlockCell(x: 0, y: 4)]),
        BlockShape(id: "6h", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0), BlockCell(x: 4, y: 0), BlockCell(x: 5, y: 0)]),
        BlockShape(id: "6v", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2), BlockCell(x: 0, y: 3), BlockCell(x: 0, y: 4), BlockCell(x: 0, y: 5)]),

        // "Diagonal stacked" / stair patterns
        // Two 2-block dominoes stacked diagonally (bigger version of Z/S)
        BlockShape(id: "DominoStep6", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
            BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
            BlockCell(x: 2, y: 2), BlockCell(x: 3, y: 2),
        ]),
        BlockShape(id: "DominoStep6Inv", cells: [
            BlockCell(x: 3, y: 0), BlockCell(x: 2, y: 0),
            BlockCell(x: 2, y: 1), BlockCell(x: 1, y: 1),
            BlockCell(x: 1, y: 2), BlockCell(x: 0, y: 2),
        ]),

        // 1-2-1 diagonal stack (has an "empty" feel inside)
        BlockShape(id: "DiagStack4", cells: [
            BlockCell(x: 0, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
            BlockCell(x: 1, y: 2),
        ]),
        BlockShape(id: "DiagStack4Inv", cells: [
            BlockCell(x: 1, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
            BlockCell(x: 0, y: 2),
        ]),

        BlockShape(id: "Diag3", cells: [BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 2)]),
        BlockShape(id: "Diag3Inv", cells: [BlockCell(x: 2, y: 0), BlockCell(x: 1, y: 1), BlockCell(x: 0, y: 2)]),
        BlockShape(id: "3x3", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
            BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2), BlockCell(x: 2, y: 2),
        ]),

        // More chunky blocks
        BlockShape(id: "4x2", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0), BlockCell(x: 3, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1), BlockCell(x: 3, y: 1),
        ]),
        BlockShape(id: "2x4", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
            BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2),
            BlockCell(x: 0, y: 3), BlockCell(x: 1, y: 3),
        ]),
        BlockShape(id: "Corner5", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 0, y: 1), BlockCell(x: 0, y: 2),
            BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
        ]),
        BlockShape(id: "Plus5", cells: [
            BlockCell(x: 1, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
            BlockCell(x: 1, y: 2),
        ]),
        BlockShape(id: "P5", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1),
            BlockCell(x: 0, y: 2),
        ]),
        BlockShape(id: "U5", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 2, y: 0),
            BlockCell(x: 0, y: 1), BlockCell(x: 1, y: 1), BlockCell(x: 2, y: 1),
        ]),
        BlockShape(id: "Hollow3", cells: [
            BlockCell(x: 0, y: 0), BlockCell(x: 1, y: 0), BlockCell(x: 2, y: 0),
            BlockCell(x: 0, y: 1),                     BlockCell(x: 2, y: 1),
            BlockCell(x: 0, y: 2), BlockCell(x: 1, y: 2), BlockCell(x: 2, y: 2),
        ]),
    ]

    private static let shapeByID: [String: BlockShape] = Dictionary(
        uniqueKeysWithValues: (simpleShapes + mediumShapes + hardShapes).map { ($0.id, $0) }
    )
}

private extension Array {
    func repeated(_ count: Int) -> [Element] {
        guard count > 0 else { return [] }
        return (0..<count).flatMap { _ in self }
    }
}
