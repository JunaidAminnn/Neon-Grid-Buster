//
//  GridManager.swift
//  NeonGridBuster
//

import Foundation

struct GridPoint: Hashable {
    var row: Int
    var col: Int
}

struct BlockCell: Hashable {
    var x: Int
    var y: Int
}

struct BlockShape: Hashable, Identifiable {
    let id: String
    let cells: [BlockCell] // offsets from origin (0,0) in grid cells

    var width: Int { (cells.map(\.x).max() ?? 0) + 1 }
    var height: Int { (cells.map(\.y).max() ?? 0) + 1 }
}

final class GridManager {
    static let gridSize = 8

    private(set) var cells: [[NeonColor?]] = Array(
        repeating: Array(repeating: nil, count: gridSize),
        count: gridSize
    )

    func copy() -> GridManager {
        let clone = GridManager()
        clone.cells = cells
        return clone
    }

    func reset() {
        for row in 0..<Self.gridSize {
            for col in 0..<Self.gridSize {
                cells[row][col] = nil
            }
        }
    }

    func isOccupied(row: Int, col: Int) -> Bool {
        cells[row][col] != nil
    }

    func canPlace(shape: BlockShape, at origin: GridPoint) -> Bool {
        for cell in shape.cells {
            let row = origin.row + cell.y
            let col = origin.col + cell.x
            if row < 0 || row >= Self.gridSize || col < 0 || col >= Self.gridSize { return false }
            if isOccupied(row: row, col: col) { return false }
        }
        return true
    }

    func place(shape: BlockShape, color: NeonColor, at origin: GridPoint) -> [GridPoint] {
        precondition(canPlace(shape: shape, at: origin))
        var placed: [GridPoint] = []
        placed.reserveCapacity(shape.cells.count)

        for cell in shape.cells {
            let row = origin.row + cell.y
            let col = origin.col + cell.x
            cells[row][col] = color
            placed.append(GridPoint(row: row, col: col))
        }
        return placed
    }

    func filledRows() -> [Int] {
        var rows: [Int] = []
        rows.reserveCapacity(Self.gridSize)
        for row in 0..<Self.gridSize {
            if cells[row].allSatisfy({ $0 != nil }) {
                rows.append(row)
            }
        }
        return rows
    }

    func filledCols() -> [Int] {
        var cols: [Int] = []
        cols.reserveCapacity(Self.gridSize)
        for col in 0..<Self.gridSize {
            var full = true
            for row in 0..<Self.gridSize {
                if cells[row][col] == nil { full = false; break }
            }
            if full { cols.append(col) }
        }
        return cols
    }

    struct ClearResult: Hashable {
        var clearedRows: [Int]
        var clearedCols: [Int]
        var clearedPoints: [GridPoint]
    }

    func clearFilledLines() -> ClearResult {
        let rows = filledRows()
        let cols = filledCols()
        guard !rows.isEmpty || !cols.isEmpty else {
            return ClearResult(clearedRows: [], clearedCols: [], clearedPoints: [])
        }

        var cleared: Set<GridPoint> = []
        for row in rows {
            for col in 0..<Self.gridSize {
                cleared.insert(GridPoint(row: row, col: col))
            }
        }
        for col in cols {
            for row in 0..<Self.gridSize {
                cleared.insert(GridPoint(row: row, col: col))
            }
        }

        for point in cleared {
            cells[point.row][point.col] = nil
        }

        return ClearResult(clearedRows: rows, clearedCols: cols, clearedPoints: Array(cleared))
    }

    func canPlaceAnywhere(shape: BlockShape) -> Bool {
        for row in 0..<Self.gridSize {
            for col in 0..<Self.gridSize {
                if canPlace(shape: shape, at: GridPoint(row: row, col: col)) {
                    return true
                }
            }
        }
        return false
    }

    func validPlacements(for shape: BlockShape) -> [GridPoint] {
        var placements: [GridPoint] = []
        placements.reserveCapacity(Self.gridSize * Self.gridSize)

        for row in 0..<Self.gridSize {
            for col in 0..<Self.gridSize {
                let point = GridPoint(row: row, col: col)
                if canPlace(shape: shape, at: point) {
                    placements.append(point)
                }
            }
        }

        return placements
    }

    func anyMovePossible(shapes: [BlockShape]) -> Bool {
        for shape in shapes {
            if canPlaceAnywhere(shape: shape) { return true }
        }
        return false
    }
}
