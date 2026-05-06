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

enum GridCellState: Equatable {
    case empty
    case normal(NeonColor)
    case target(TargetGem)

    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }

    var isOccupied: Bool { !isEmpty }

    var renderColor: NeonColor? {
        switch self {
        case .empty:             return nil
        case .normal(let c):     return c
        case .target(let gem):   return gem.neonColor
        }
    }

    var gem: TargetGem? {
        if case .target(let g) = self { return g }
        return nil
    }
}

// MARK: - AdventureLevel

struct AdventureLevel: Identifiable {
    let id:          Int
    let title:       String
    let subtitle:    String
    let initialGrid: [[GridCellState]]
    let targets:     [TargetGem: Int]
    var isCompleted: Bool = false

    var totalGemCount: Int {
        targets.values.reduce(0, +)
    }

    var hasTargets: Bool { !targets.isEmpty }
}

// MARK: - AdventureRegistry

enum AdventureRegistry {

    private static func emptyGrid() -> [[GridCellState]] {
        Array(repeating: Array(repeating: .empty, count: 8), count: 8)
    }

    private static func buildGrid(gemPlacements: [GridPoint: TargetGem]) -> [[GridCellState]] {
        var grid = emptyGrid()
        for (p, gem) in gemPlacements {
            grid[p.row][p.col] = .target(gem)
        }
        return grid
    }

    static let all: [AdventureLevel] = [
        AdventureLevel(
            id: 1,
            title: "Level 1",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 6, col: 7): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 5, col: 1): .emerald, GridPoint(row: 0, col: 0): .emerald, GridPoint(row: 6, col: 2): .emerald]),
            targets: [.emerald: 5]
        ),
        AdventureLevel(
            id: 2,
            title: "Level 2",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 3, col: 7): .emerald, GridPoint(row: 1, col: 1): .emerald, GridPoint(row: 4, col: 6): .emerald, GridPoint(row: 4, col: 4): .emerald, GridPoint(row: 0, col: 0): .emerald, GridPoint(row: 1, col: 6): .emerald]),
            targets: [.emerald: 6]
        ),
        AdventureLevel(
            id: 3,
            title: "Level 3",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 7, col: 6): .emerald, GridPoint(row: 0, col: 2): .emerald, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 2, col: 5): .emerald, GridPoint(row: 5, col: 1): .emerald, GridPoint(row: 5, col: 2): .emerald]),
            targets: [.emerald: 6]
        ),
        AdventureLevel(
            id: 4,
            title: "Level 4",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 6, col: 4): .emerald, GridPoint(row: 0, col: 6): .emerald, GridPoint(row: 5, col: 1): .emerald, GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 3, col: 4): .emerald, GridPoint(row: 4, col: 6): .emerald, GridPoint(row: 6, col: 0): .emerald]),
            targets: [.emerald: 7]
        ),
        AdventureLevel(
            id: 5,
            title: "Level 5",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 5, col: 6): .emerald, GridPoint(row: 2, col: 4): .emerald, GridPoint(row: 4, col: 4): .emerald, GridPoint(row: 4, col: 3): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 0, col: 4): .emerald, GridPoint(row: 1, col: 2): .emerald]),
            targets: [.emerald: 7]
        ),
        AdventureLevel(
            id: 6,
            title: "Level 6",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 7, col: 2): .emerald, GridPoint(row: 5, col: 1): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 7, col: 4): .emerald, GridPoint(row: 4, col: 7): .emerald, GridPoint(row: 6, col: 4): .emerald, GridPoint(row: 1, col: 5): .emerald]),
            targets: [.emerald: 8]
        ),
        AdventureLevel(
            id: 7,
            title: "Level 7",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 1, col: 2): .emerald, GridPoint(row: 5, col: 2): .emerald, GridPoint(row: 4, col: 3): .emerald, GridPoint(row: 5, col: 4): .emerald, GridPoint(row: 4, col: 0): .emerald, GridPoint(row: 0, col: 6): .emerald, GridPoint(row: 6, col: 7): .emerald, GridPoint(row: 5, col: 1): .emerald]),
            targets: [.emerald: 8]
        ),
        AdventureLevel(
            id: 8,
            title: "Level 8",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 6): .emerald, GridPoint(row: 6, col: 4): .emerald, GridPoint(row: 2, col: 5): .emerald, GridPoint(row: 1, col: 4): .emerald, GridPoint(row: 2, col: 3): .emerald, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 1, col: 5): .emerald, GridPoint(row: 2, col: 1): .emerald, GridPoint(row: 0, col: 5): .emerald]),
            targets: [.emerald: 9]
        ),
        AdventureLevel(
            id: 9,
            title: "Level 9",
            subtitle: "Difficulty 1",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 6, col: 5): .emerald, GridPoint(row: 0, col: 0): .emerald, GridPoint(row: 7, col: 2): .emerald, GridPoint(row: 2, col: 7): .emerald, GridPoint(row: 5, col: 7): .emerald, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 4, col: 2): .emerald, GridPoint(row: 5, col: 1): .emerald]),
            targets: [.emerald: 9]
        ),
        AdventureLevel(
            id: 10,
            title: "Level 10",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 2, col: 0): .emerald, GridPoint(row: 0, col: 4): .emerald, GridPoint(row: 1, col: 4): .emerald, GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 5, col: 6): .star, GridPoint(row: 0, col: 1): .star, GridPoint(row: 3, col: 6): .star, GridPoint(row: 3, col: 0): .star, GridPoint(row: 4, col: 0): .star]),
            targets: [.emerald: 5, .star: 5]
        ),
        AdventureLevel(
            id: 11,
            title: "Level 11",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 3): .emerald, GridPoint(row: 2, col: 6): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 1, col: 4): .emerald, GridPoint(row: 5, col: 3): .emerald, GridPoint(row: 6, col: 4): .star, GridPoint(row: 0, col: 0): .star, GridPoint(row: 1, col: 1): .star, GridPoint(row: 5, col: 4): .star, GridPoint(row: 0, col: 4): .star]),
            targets: [.emerald: 5, .star: 5]
        ),
        AdventureLevel(
            id: 12,
            title: "Level 12",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 1): .emerald, GridPoint(row: 3, col: 3): .emerald, GridPoint(row: 4, col: 0): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 3, col: 0): .emerald, GridPoint(row: 0, col: 2): .star, GridPoint(row: 6, col: 3): .star, GridPoint(row: 1, col: 7): .star, GridPoint(row: 5, col: 6): .star, GridPoint(row: 2, col: 1): .star, GridPoint(row: 7, col: 6): .star]),
            targets: [.emerald: 5, .star: 6]
        ),
        AdventureLevel(
            id: 13,
            title: "Level 13",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 5, col: 7): .emerald, GridPoint(row: 7, col: 3): .emerald, GridPoint(row: 2, col: 5): .emerald, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 2, col: 2): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 3, col: 2): .star, GridPoint(row: 1, col: 7): .star, GridPoint(row: 5, col: 2): .star, GridPoint(row: 3, col: 0): .star, GridPoint(row: 6, col: 6): .star]),
            targets: [.emerald: 6, .star: 5]
        ),
        AdventureLevel(
            id: 14,
            title: "Level 14",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 5): .emerald, GridPoint(row: 1, col: 5): .emerald, GridPoint(row: 6, col: 5): .emerald, GridPoint(row: 6, col: 7): .emerald, GridPoint(row: 3, col: 4): .emerald, GridPoint(row: 4, col: 3): .emerald, GridPoint(row: 6, col: 4): .star, GridPoint(row: 7, col: 3): .star, GridPoint(row: 5, col: 0): .star, GridPoint(row: 0, col: 4): .star, GridPoint(row: 1, col: 2): .star, GridPoint(row: 5, col: 2): .star]),
            targets: [.emerald: 6, .star: 6]
        ),
        AdventureLevel(
            id: 15,
            title: "Level 15",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 1, col: 5): .emerald, GridPoint(row: 2, col: 2): .emerald, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 7, col: 6): .emerald, GridPoint(row: 0, col: 1): .emerald, GridPoint(row: 7, col: 1): .emerald, GridPoint(row: 6, col: 6): .star, GridPoint(row: 5, col: 7): .star, GridPoint(row: 2, col: 3): .star, GridPoint(row: 6, col: 4): .star, GridPoint(row: 7, col: 4): .star, GridPoint(row: 6, col: 1): .star]),
            targets: [.emerald: 6, .star: 6]
        ),
        AdventureLevel(
            id: 16,
            title: "Level 16",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 1, col: 4): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 5, col: 7): .emerald, GridPoint(row: 0, col: 1): .emerald, GridPoint(row: 5, col: 4): .emerald, GridPoint(row: 2, col: 4): .star, GridPoint(row: 5, col: 0): .star, GridPoint(row: 6, col: 5): .star, GridPoint(row: 2, col: 0): .star, GridPoint(row: 3, col: 7): .star, GridPoint(row: 0, col: 2): .star, GridPoint(row: 0, col: 6): .star]),
            targets: [.emerald: 6, .star: 7]
        ),
        AdventureLevel(
            id: 17,
            title: "Level 17",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 2, col: 7): .emerald, GridPoint(row: 3, col: 3): .emerald, GridPoint(row: 3, col: 6): .emerald, GridPoint(row: 1, col: 5): .emerald, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 1, col: 1): .emerald, GridPoint(row: 2, col: 2): .emerald, GridPoint(row: 7, col: 3): .star, GridPoint(row: 7, col: 6): .star, GridPoint(row: 2, col: 0): .star, GridPoint(row: 4, col: 4): .star, GridPoint(row: 0, col: 6): .star, GridPoint(row: 7, col: 4): .star]),
            targets: [.emerald: 7, .star: 6]
        ),
        AdventureLevel(
            id: 18,
            title: "Level 18",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 1): .emerald, GridPoint(row: 3, col: 5): .emerald, GridPoint(row: 0, col: 2): .emerald, GridPoint(row: 4, col: 3): .emerald, GridPoint(row: 4, col: 6): .emerald, GridPoint(row: 6, col: 5): .emerald, GridPoint(row: 4, col: 1): .emerald, GridPoint(row: 6, col: 1): .star, GridPoint(row: 7, col: 5): .star, GridPoint(row: 0, col: 4): .star, GridPoint(row: 1, col: 2): .star, GridPoint(row: 0, col: 0): .star, GridPoint(row: 6, col: 6): .star, GridPoint(row: 6, col: 2): .star]),
            targets: [.emerald: 7, .star: 7]
        ),
        AdventureLevel(
            id: 19,
            title: "Level 19",
            subtitle: "Difficulty 2",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 3): .emerald, GridPoint(row: 3, col: 3): .emerald, GridPoint(row: 4, col: 1): .emerald, GridPoint(row: 5, col: 7): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 4, col: 6): .emerald, GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 5, col: 3): .star, GridPoint(row: 4, col: 3): .star, GridPoint(row: 2, col: 5): .star, GridPoint(row: 1, col: 5): .star, GridPoint(row: 0, col: 1): .star, GridPoint(row: 4, col: 7): .star, GridPoint(row: 6, col: 2): .star]),
            targets: [.emerald: 7, .star: 7]
        ),
        AdventureLevel(
            id: 20,
            title: "Level 20",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 3, col: 3): .emerald, GridPoint(row: 4, col: 5): .emerald, GridPoint(row: 2, col: 4): .emerald, GridPoint(row: 6, col: 1): .emerald, GridPoint(row: 1, col: 3): .star, GridPoint(row: 3, col: 4): .star, GridPoint(row: 7, col: 3): .star, GridPoint(row: 0, col: 4): .star, GridPoint(row: 3, col: 0): .orangePentagon, GridPoint(row: 1, col: 1): .orangePentagon, GridPoint(row: 5, col: 3): .orangePentagon, GridPoint(row: 3, col: 1): .orangePentagon, GridPoint(row: 2, col: 1): .orangePentagon]),
            targets: [.emerald: 4, .star: 4, .orangePentagon: 5]
        ),
        AdventureLevel(
            id: 21,
            title: "Level 21",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 6, col: 5): .emerald, GridPoint(row: 7, col: 3): .emerald, GridPoint(row: 5, col: 2): .emerald, GridPoint(row: 6, col: 3): .star, GridPoint(row: 6, col: 6): .star, GridPoint(row: 3, col: 6): .star, GridPoint(row: 1, col: 6): .star, GridPoint(row: 5, col: 7): .star, GridPoint(row: 7, col: 7): .orangePentagon, GridPoint(row: 2, col: 6): .orangePentagon, GridPoint(row: 7, col: 1): .orangePentagon, GridPoint(row: 0, col: 0): .orangePentagon, GridPoint(row: 2, col: 3): .orangePentagon]),
            targets: [.emerald: 4, .star: 5, .orangePentagon: 5]
        ),
        AdventureLevel(
            id: 22,
            title: "Level 22",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 6, col: 2): .emerald, GridPoint(row: 3, col: 3): .emerald, GridPoint(row: 7, col: 0): .emerald, GridPoint(row: 2, col: 6): .emerald, GridPoint(row: 3, col: 5): .emerald, GridPoint(row: 5, col: 0): .star, GridPoint(row: 5, col: 4): .star, GridPoint(row: 5, col: 3): .star, GridPoint(row: 5, col: 2): .star, GridPoint(row: 7, col: 2): .star, GridPoint(row: 1, col: 7): .orangePentagon, GridPoint(row: 3, col: 7): .orangePentagon, GridPoint(row: 7, col: 4): .orangePentagon, GridPoint(row: 1, col: 6): .orangePentagon, GridPoint(row: 7, col: 5): .orangePentagon]),
            targets: [.emerald: 5, .star: 5, .orangePentagon: 5]
        ),
        AdventureLevel(
            id: 23,
            title: "Level 23",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 1, col: 2): .emerald, GridPoint(row: 5, col: 5): .emerald, GridPoint(row: 3, col: 5): .emerald, GridPoint(row: 2, col: 5): .emerald, GridPoint(row: 6, col: 6): .emerald, GridPoint(row: 5, col: 4): .star, GridPoint(row: 6, col: 1): .star, GridPoint(row: 7, col: 7): .star, GridPoint(row: 7, col: 5): .star, GridPoint(row: 3, col: 6): .star, GridPoint(row: 2, col: 4): .orangePentagon, GridPoint(row: 4, col: 7): .orangePentagon, GridPoint(row: 2, col: 2): .orangePentagon, GridPoint(row: 0, col: 6): .orangePentagon, GridPoint(row: 7, col: 4): .orangePentagon, GridPoint(row: 3, col: 0): .orangePentagon]),
            targets: [.emerald: 5, .star: 5, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 24,
            title: "Level 24",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 7, col: 0): .emerald, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 0, col: 3): .emerald, GridPoint(row: 6, col: 6): .emerald, GridPoint(row: 6, col: 7): .emerald, GridPoint(row: 2, col: 1): .star, GridPoint(row: 3, col: 2): .star, GridPoint(row: 1, col: 2): .star, GridPoint(row: 5, col: 5): .star, GridPoint(row: 7, col: 3): .star, GridPoint(row: 5, col: 0): .star, GridPoint(row: 0, col: 0): .orangePentagon, GridPoint(row: 7, col: 5): .orangePentagon, GridPoint(row: 4, col: 6): .orangePentagon, GridPoint(row: 6, col: 5): .orangePentagon, GridPoint(row: 1, col: 5): .orangePentagon, GridPoint(row: 3, col: 6): .orangePentagon]),
            targets: [.emerald: 5, .star: 6, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 25,
            title: "Level 25",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 3, col: 0): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 3, col: 6): .emerald, GridPoint(row: 5, col: 4): .emerald, GridPoint(row: 6, col: 4): .emerald, GridPoint(row: 7, col: 2): .emerald, GridPoint(row: 6, col: 3): .star, GridPoint(row: 6, col: 7): .star, GridPoint(row: 5, col: 0): .star, GridPoint(row: 0, col: 6): .star, GridPoint(row: 1, col: 5): .star, GridPoint(row: 3, col: 2): .star, GridPoint(row: 2, col: 5): .orangePentagon, GridPoint(row: 0, col: 5): .orangePentagon, GridPoint(row: 5, col: 1): .orangePentagon, GridPoint(row: 7, col: 1): .orangePentagon, GridPoint(row: 2, col: 1): .orangePentagon, GridPoint(row: 1, col: 0): .orangePentagon]),
            targets: [.emerald: 6, .star: 6, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 26,
            title: "Level 26",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 3, col: 0): .emerald, GridPoint(row: 1, col: 1): .emerald, GridPoint(row: 7, col: 2): .emerald, GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 3, col: 4): .emerald, GridPoint(row: 3, col: 6): .emerald, GridPoint(row: 6, col: 1): .star, GridPoint(row: 6, col: 7): .star, GridPoint(row: 1, col: 5): .star, GridPoint(row: 3, col: 3): .star, GridPoint(row: 2, col: 3): .star, GridPoint(row: 6, col: 2): .star, GridPoint(row: 7, col: 4): .orangePentagon, GridPoint(row: 4, col: 6): .orangePentagon, GridPoint(row: 1, col: 2): .orangePentagon, GridPoint(row: 1, col: 0): .orangePentagon, GridPoint(row: 1, col: 7): .orangePentagon, GridPoint(row: 3, col: 7): .orangePentagon]),
            targets: [.emerald: 6, .star: 6, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 27,
            title: "Level 27",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 6, col: 4): .emerald, GridPoint(row: 1, col: 0): .emerald, GridPoint(row: 0, col: 2): .emerald, GridPoint(row: 1, col: 7): .emerald, GridPoint(row: 5, col: 3): .emerald, GridPoint(row: 5, col: 4): .star, GridPoint(row: 0, col: 4): .star, GridPoint(row: 1, col: 3): .star, GridPoint(row: 0, col: 6): .star, GridPoint(row: 3, col: 6): .star, GridPoint(row: 2, col: 7): .star, GridPoint(row: 3, col: 4): .star, GridPoint(row: 2, col: 5): .orangePentagon, GridPoint(row: 4, col: 2): .orangePentagon, GridPoint(row: 6, col: 6): .orangePentagon, GridPoint(row: 5, col: 5): .orangePentagon, GridPoint(row: 0, col: 1): .orangePentagon, GridPoint(row: 3, col: 5): .orangePentagon]),
            targets: [.emerald: 6, .star: 7, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 28,
            title: "Level 28",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 2, col: 6): .emerald, GridPoint(row: 3, col: 5): .emerald, GridPoint(row: 4, col: 7): .emerald, GridPoint(row: 3, col: 3): .emerald, GridPoint(row: 4, col: 3): .emerald, GridPoint(row: 0, col: 6): .emerald, GridPoint(row: 3, col: 7): .star, GridPoint(row: 6, col: 0): .star, GridPoint(row: 6, col: 2): .star, GridPoint(row: 4, col: 1): .star, GridPoint(row: 7, col: 5): .star, GridPoint(row: 5, col: 2): .star, GridPoint(row: 2, col: 0): .star, GridPoint(row: 0, col: 1): .orangePentagon, GridPoint(row: 3, col: 4): .orangePentagon, GridPoint(row: 5, col: 6): .orangePentagon, GridPoint(row: 6, col: 3): .orangePentagon, GridPoint(row: 5, col: 3): .orangePentagon, GridPoint(row: 6, col: 6): .orangePentagon]),
            targets: [.emerald: 6, .star: 7, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 29,
            title: "Level 29",
            subtitle: "Difficulty 3",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 0): .emerald, GridPoint(row: 2, col: 1): .emerald, GridPoint(row: 5, col: 6): .emerald, GridPoint(row: 4, col: 2): .emerald, GridPoint(row: 6, col: 6): .emerald, GridPoint(row: 0, col: 1): .emerald, GridPoint(row: 4, col: 7): .emerald, GridPoint(row: 7, col: 5): .star, GridPoint(row: 0, col: 7): .star, GridPoint(row: 6, col: 7): .star, GridPoint(row: 5, col: 3): .star, GridPoint(row: 5, col: 1): .star, GridPoint(row: 3, col: 0): .star, GridPoint(row: 2, col: 0): .orangePentagon, GridPoint(row: 7, col: 2): .orangePentagon, GridPoint(row: 1, col: 4): .orangePentagon, GridPoint(row: 2, col: 7): .orangePentagon, GridPoint(row: 4, col: 3): .orangePentagon, GridPoint(row: 0, col: 5): .orangePentagon]),
            targets: [.emerald: 7, .star: 6, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 30,
            title: "Level 30",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 7): .emerald, GridPoint(row: 4, col: 0): .emerald, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 1, col: 5): .emerald, GridPoint(row: 1, col: 0): .star, GridPoint(row: 1, col: 2): .star, GridPoint(row: 5, col: 0): .star, GridPoint(row: 0, col: 6): .star, GridPoint(row: 1, col: 3): .orangePentagon, GridPoint(row: 3, col: 3): .orangePentagon, GridPoint(row: 6, col: 5): .orangePentagon, GridPoint(row: 6, col: 1): .orangePentagon, GridPoint(row: 1, col: 7): .blueSapphire, GridPoint(row: 6, col: 6): .blueSapphire, GridPoint(row: 6, col: 2): .blueSapphire, GridPoint(row: 0, col: 1): .blueSapphire]),
            targets: [.emerald: 4, .star: 4, .orangePentagon: 4, .blueSapphire: 4]
        ),
        AdventureLevel(
            id: 31,
            title: "Level 31",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 5, col: 3): .emerald, GridPoint(row: 0, col: 4): .emerald, GridPoint(row: 6, col: 2): .emerald, GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 2, col: 4): .star, GridPoint(row: 6, col: 6): .star, GridPoint(row: 1, col: 1): .star, GridPoint(row: 7, col: 4): .star, GridPoint(row: 1, col: 5): .orangePentagon, GridPoint(row: 5, col: 7): .orangePentagon, GridPoint(row: 2, col: 3): .orangePentagon, GridPoint(row: 7, col: 3): .orangePentagon, GridPoint(row: 1, col: 3): .blueSapphire, GridPoint(row: 4, col: 5): .blueSapphire, GridPoint(row: 6, col: 1): .blueSapphire, GridPoint(row: 0, col: 1): .blueSapphire, GridPoint(row: 0, col: 7): .blueSapphire]),
            targets: [.emerald: 4, .star: 4, .orangePentagon: 4, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 32,
            title: "Level 32",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 7, col: 5): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 6, col: 7): .emerald, GridPoint(row: 5, col: 7): .star, GridPoint(row: 2, col: 1): .star, GridPoint(row: 7, col: 4): .star, GridPoint(row: 3, col: 2): .star, GridPoint(row: 1, col: 7): .orangePentagon, GridPoint(row: 5, col: 4): .orangePentagon, GridPoint(row: 1, col: 4): .orangePentagon, GridPoint(row: 0, col: 5): .orangePentagon, GridPoint(row: 3, col: 1): .orangePentagon, GridPoint(row: 7, col: 2): .blueSapphire, GridPoint(row: 2, col: 6): .blueSapphire, GridPoint(row: 3, col: 6): .blueSapphire, GridPoint(row: 0, col: 2): .blueSapphire]),
            targets: [.emerald: 4, .star: 4, .orangePentagon: 5, .blueSapphire: 4]
        ),
        AdventureLevel(
            id: 33,
            title: "Level 33",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 6, col: 6): .emerald, GridPoint(row: 0, col: 1): .emerald, GridPoint(row: 1, col: 0): .emerald, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 7, col: 6): .emerald, GridPoint(row: 1, col: 7): .star, GridPoint(row: 2, col: 6): .star, GridPoint(row: 4, col: 0): .star, GridPoint(row: 5, col: 6): .star, GridPoint(row: 6, col: 4): .orangePentagon, GridPoint(row: 7, col: 4): .orangePentagon, GridPoint(row: 6, col: 2): .orangePentagon, GridPoint(row: 7, col: 5): .orangePentagon, GridPoint(row: 6, col: 3): .blueSapphire, GridPoint(row: 1, col: 3): .blueSapphire, GridPoint(row: 4, col: 2): .blueSapphire, GridPoint(row: 7, col: 2): .blueSapphire, GridPoint(row: 0, col: 3): .blueSapphire]),
            targets: [.emerald: 5, .star: 4, .orangePentagon: 4, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 34,
            title: "Level 34",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 4): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 1, col: 7): .emerald, GridPoint(row: 3, col: 1): .emerald, GridPoint(row: 7, col: 6): .emerald, GridPoint(row: 3, col: 2): .star, GridPoint(row: 5, col: 5): .star, GridPoint(row: 5, col: 6): .star, GridPoint(row: 7, col: 3): .star, GridPoint(row: 1, col: 3): .star, GridPoint(row: 3, col: 4): .orangePentagon, GridPoint(row: 1, col: 5): .orangePentagon, GridPoint(row: 2, col: 6): .orangePentagon, GridPoint(row: 0, col: 2): .orangePentagon, GridPoint(row: 5, col: 1): .blueSapphire, GridPoint(row: 7, col: 2): .blueSapphire, GridPoint(row: 4, col: 5): .blueSapphire, GridPoint(row: 7, col: 1): .blueSapphire, GridPoint(row: 3, col: 7): .blueSapphire]),
            targets: [.emerald: 5, .star: 5, .orangePentagon: 4, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 35,
            title: "Level 35",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 3): .emerald, GridPoint(row: 1, col: 0): .emerald, GridPoint(row: 7, col: 6): .emerald, GridPoint(row: 2, col: 0): .emerald, GridPoint(row: 4, col: 2): .emerald, GridPoint(row: 7, col: 3): .star, GridPoint(row: 5, col: 3): .star, GridPoint(row: 0, col: 5): .star, GridPoint(row: 3, col: 0): .star, GridPoint(row: 1, col: 7): .star, GridPoint(row: 6, col: 1): .orangePentagon, GridPoint(row: 2, col: 3): .orangePentagon, GridPoint(row: 7, col: 5): .orangePentagon, GridPoint(row: 4, col: 4): .orangePentagon, GridPoint(row: 6, col: 3): .orangePentagon, GridPoint(row: 7, col: 2): .blueSapphire, GridPoint(row: 6, col: 5): .blueSapphire, GridPoint(row: 2, col: 4): .blueSapphire, GridPoint(row: 2, col: 1): .blueSapphire, GridPoint(row: 2, col: 7): .blueSapphire]),
            targets: [.emerald: 5, .star: 5, .orangePentagon: 5, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 36,
            title: "Level 36",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 7): .emerald, GridPoint(row: 7, col: 6): .emerald, GridPoint(row: 4, col: 3): .emerald, GridPoint(row: 5, col: 7): .emerald, GridPoint(row: 3, col: 4): .emerald, GridPoint(row: 6, col: 2): .star, GridPoint(row: 2, col: 2): .star, GridPoint(row: 5, col: 3): .star, GridPoint(row: 2, col: 7): .star, GridPoint(row: 3, col: 2): .star, GridPoint(row: 7, col: 4): .orangePentagon, GridPoint(row: 0, col: 6): .orangePentagon, GridPoint(row: 1, col: 1): .orangePentagon, GridPoint(row: 0, col: 4): .orangePentagon, GridPoint(row: 4, col: 0): .orangePentagon, GridPoint(row: 7, col: 5): .blueSapphire, GridPoint(row: 3, col: 6): .blueSapphire, GridPoint(row: 0, col: 1): .blueSapphire, GridPoint(row: 0, col: 5): .blueSapphire, GridPoint(row: 6, col: 6): .blueSapphire, GridPoint(row: 1, col: 3): .blueSapphire]),
            targets: [.emerald: 5, .star: 5, .orangePentagon: 5, .blueSapphire: 6]
        ),
        AdventureLevel(
            id: 37,
            title: "Level 37",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 2, col: 5): .emerald, GridPoint(row: 4, col: 5): .emerald, GridPoint(row: 0, col: 6): .emerald, GridPoint(row: 4, col: 6): .emerald, GridPoint(row: 5, col: 1): .emerald, GridPoint(row: 2, col: 1): .star, GridPoint(row: 1, col: 2): .star, GridPoint(row: 6, col: 0): .star, GridPoint(row: 2, col: 7): .star, GridPoint(row: 2, col: 6): .star, GridPoint(row: 6, col: 2): .star, GridPoint(row: 5, col: 2): .orangePentagon, GridPoint(row: 1, col: 0): .orangePentagon, GridPoint(row: 4, col: 7): .orangePentagon, GridPoint(row: 6, col: 6): .orangePentagon, GridPoint(row: 3, col: 0): .orangePentagon, GridPoint(row: 2, col: 4): .blueSapphire, GridPoint(row: 0, col: 1): .blueSapphire, GridPoint(row: 7, col: 6): .blueSapphire, GridPoint(row: 6, col: 5): .blueSapphire, GridPoint(row: 6, col: 7): .blueSapphire, GridPoint(row: 1, col: 3): .blueSapphire, GridPoint(row: 3, col: 6): .blueSapphire]),
            targets: [.emerald: 5, .star: 6, .orangePentagon: 5, .blueSapphire: 7]
        ),
        AdventureLevel(
            id: 38,
            title: "Level 38",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 3, col: 1): .emerald, GridPoint(row: 0, col: 4): .emerald, GridPoint(row: 7, col: 6): .emerald, GridPoint(row: 4, col: 5): .emerald, GridPoint(row: 2, col: 3): .emerald, GridPoint(row: 2, col: 5): .emerald, GridPoint(row: 1, col: 4): .star, GridPoint(row: 5, col: 5): .star, GridPoint(row: 3, col: 7): .star, GridPoint(row: 5, col: 4): .star, GridPoint(row: 6, col: 2): .star, GridPoint(row: 1, col: 0): .star, GridPoint(row: 2, col: 2): .orangePentagon, GridPoint(row: 0, col: 0): .orangePentagon, GridPoint(row: 3, col: 6): .orangePentagon, GridPoint(row: 7, col: 1): .orangePentagon, GridPoint(row: 4, col: 7): .orangePentagon, GridPoint(row: 0, col: 6): .orangePentagon, GridPoint(row: 7, col: 0): .blueSapphire, GridPoint(row: 0, col: 7): .blueSapphire, GridPoint(row: 3, col: 0): .blueSapphire, GridPoint(row: 5, col: 6): .blueSapphire, GridPoint(row: 2, col: 4): .blueSapphire, GridPoint(row: 5, col: 2): .blueSapphire, GridPoint(row: 7, col: 5): .blueSapphire]),
            targets: [.emerald: 6, .star: 6, .orangePentagon: 6, .blueSapphire: 7]
        ),
        AdventureLevel(
            id: 39,
            title: "Level 39",
            subtitle: "Difficulty 4",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 4, col: 4): .emerald, GridPoint(row: 0, col: 1): .emerald, GridPoint(row: 1, col: 4): .emerald, GridPoint(row: 0, col: 6): .emerald, GridPoint(row: 2, col: 1): .emerald, GridPoint(row: 5, col: 4): .emerald, GridPoint(row: 3, col: 0): .star, GridPoint(row: 3, col: 5): .star, GridPoint(row: 3, col: 1): .star, GridPoint(row: 0, col: 3): .star, GridPoint(row: 7, col: 2): .star, GridPoint(row: 2, col: 6): .star, GridPoint(row: 3, col: 7): .orangePentagon, GridPoint(row: 5, col: 6): .orangePentagon, GridPoint(row: 0, col: 4): .orangePentagon, GridPoint(row: 3, col: 2): .orangePentagon, GridPoint(row: 1, col: 2): .orangePentagon, GridPoint(row: 6, col: 6): .orangePentagon, GridPoint(row: 4, col: 0): .orangePentagon, GridPoint(row: 1, col: 7): .blueSapphire, GridPoint(row: 1, col: 5): .blueSapphire, GridPoint(row: 2, col: 5): .blueSapphire, GridPoint(row: 7, col: 3): .blueSapphire, GridPoint(row: 5, col: 2): .blueSapphire, GridPoint(row: 1, col: 6): .blueSapphire, GridPoint(row: 7, col: 4): .blueSapphire]),
            targets: [.emerald: 6, .star: 6, .orangePentagon: 7, .blueSapphire: 6]
        ),
        AdventureLevel(
            id: 40,
            title: "Level 40",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 3): .redRuby, GridPoint(row: 0, col: 2): .redRuby, GridPoint(row: 6, col: 4): .redRuby, GridPoint(row: 7, col: 1): .redRuby, GridPoint(row: 3, col: 6): .redRuby, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 4, col: 0): .emerald, GridPoint(row: 5, col: 1): .emerald, GridPoint(row: 2, col: 1): .emerald, GridPoint(row: 0, col: 5): .emerald, GridPoint(row: 7, col: 2): .star, GridPoint(row: 7, col: 0): .star, GridPoint(row: 3, col: 7): .star, GridPoint(row: 1, col: 2): .star, GridPoint(row: 3, col: 5): .star, GridPoint(row: 7, col: 6): .orangePentagon, GridPoint(row: 1, col: 3): .orangePentagon, GridPoint(row: 1, col: 0): .orangePentagon, GridPoint(row: 0, col: 6): .orangePentagon, GridPoint(row: 1, col: 5): .orangePentagon, GridPoint(row: 5, col: 2): .blueSapphire, GridPoint(row: 4, col: 4): .blueSapphire, GridPoint(row: 2, col: 3): .blueSapphire, GridPoint(row: 4, col: 5): .blueSapphire, GridPoint(row: 5, col: 0): .blueSapphire]),
            targets: [.redRuby: 5, .emerald: 5, .star: 5, .orangePentagon: 5, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 41,
            title: "Level 41",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 2, col: 7): .redRuby, GridPoint(row: 6, col: 7): .redRuby, GridPoint(row: 1, col: 3): .redRuby, GridPoint(row: 5, col: 1): .redRuby, GridPoint(row: 2, col: 3): .redRuby, GridPoint(row: 3, col: 2): .emerald, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 1, col: 4): .emerald, GridPoint(row: 3, col: 7): .emerald, GridPoint(row: 2, col: 5): .emerald, GridPoint(row: 0, col: 6): .star, GridPoint(row: 0, col: 7): .star, GridPoint(row: 3, col: 1): .star, GridPoint(row: 0, col: 3): .star, GridPoint(row: 7, col: 4): .star, GridPoint(row: 7, col: 5): .orangePentagon, GridPoint(row: 6, col: 0): .orangePentagon, GridPoint(row: 4, col: 3): .orangePentagon, GridPoint(row: 3, col: 6): .orangePentagon, GridPoint(row: 2, col: 1): .orangePentagon, GridPoint(row: 4, col: 1): .blueSapphire, GridPoint(row: 4, col: 7): .blueSapphire, GridPoint(row: 7, col: 2): .blueSapphire, GridPoint(row: 5, col: 2): .blueSapphire, GridPoint(row: 0, col: 1): .blueSapphire]),
            targets: [.redRuby: 5, .emerald: 5, .star: 5, .orangePentagon: 5, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 42,
            title: "Level 42",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 6, col: 4): .redRuby, GridPoint(row: 1, col: 2): .redRuby, GridPoint(row: 1, col: 5): .redRuby, GridPoint(row: 5, col: 1): .redRuby, GridPoint(row: 0, col: 7): .redRuby, GridPoint(row: 0, col: 4): .emerald, GridPoint(row: 4, col: 7): .emerald, GridPoint(row: 6, col: 5): .emerald, GridPoint(row: 3, col: 7): .emerald, GridPoint(row: 7, col: 5): .emerald, GridPoint(row: 7, col: 2): .star, GridPoint(row: 0, col: 3): .star, GridPoint(row: 4, col: 5): .star, GridPoint(row: 6, col: 7): .star, GridPoint(row: 6, col: 2): .star, GridPoint(row: 1, col: 0): .star, GridPoint(row: 1, col: 4): .orangePentagon, GridPoint(row: 5, col: 6): .orangePentagon, GridPoint(row: 1, col: 7): .orangePentagon, GridPoint(row: 3, col: 0): .orangePentagon, GridPoint(row: 3, col: 2): .orangePentagon, GridPoint(row: 4, col: 3): .blueSapphire, GridPoint(row: 2, col: 4): .blueSapphire, GridPoint(row: 3, col: 6): .blueSapphire, GridPoint(row: 3, col: 1): .blueSapphire, GridPoint(row: 7, col: 1): .blueSapphire]),
            targets: [.redRuby: 5, .emerald: 5, .star: 6, .orangePentagon: 5, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 43,
            title: "Level 43",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 4): .redRuby, GridPoint(row: 3, col: 4): .redRuby, GridPoint(row: 2, col: 2): .redRuby, GridPoint(row: 6, col: 2): .redRuby, GridPoint(row: 5, col: 0): .redRuby, GridPoint(row: 1, col: 5): .emerald, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 3, col: 3): .emerald, GridPoint(row: 2, col: 0): .emerald, GridPoint(row: 4, col: 4): .emerald, GridPoint(row: 4, col: 7): .emerald, GridPoint(row: 4, col: 5): .star, GridPoint(row: 1, col: 1): .star, GridPoint(row: 0, col: 5): .star, GridPoint(row: 7, col: 3): .star, GridPoint(row: 4, col: 0): .star, GridPoint(row: 7, col: 1): .orangePentagon, GridPoint(row: 0, col: 3): .orangePentagon, GridPoint(row: 3, col: 5): .orangePentagon, GridPoint(row: 5, col: 1): .orangePentagon, GridPoint(row: 1, col: 7): .orangePentagon, GridPoint(row: 2, col: 5): .blueSapphire, GridPoint(row: 3, col: 0): .blueSapphire, GridPoint(row: 6, col: 6): .blueSapphire, GridPoint(row: 7, col: 4): .blueSapphire, GridPoint(row: 1, col: 3): .blueSapphire]),
            targets: [.redRuby: 5, .emerald: 6, .star: 5, .orangePentagon: 5, .blueSapphire: 5]
        ),
        AdventureLevel(
            id: 44,
            title: "Level 44",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 2, col: 7): .redRuby, GridPoint(row: 4, col: 5): .redRuby, GridPoint(row: 4, col: 3): .redRuby, GridPoint(row: 6, col: 7): .redRuby, GridPoint(row: 6, col: 3): .redRuby, GridPoint(row: 1, col: 3): .emerald, GridPoint(row: 3, col: 7): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 2, col: 6): .emerald, GridPoint(row: 7, col: 3): .emerald, GridPoint(row: 0, col: 0): .star, GridPoint(row: 1, col: 0): .star, GridPoint(row: 1, col: 4): .star, GridPoint(row: 2, col: 0): .star, GridPoint(row: 1, col: 5): .star, GridPoint(row: 7, col: 6): .star, GridPoint(row: 4, col: 1): .orangePentagon, GridPoint(row: 1, col: 7): .orangePentagon, GridPoint(row: 0, col: 4): .orangePentagon, GridPoint(row: 5, col: 6): .orangePentagon, GridPoint(row: 7, col: 5): .orangePentagon, GridPoint(row: 6, col: 6): .blueSapphire, GridPoint(row: 5, col: 2): .blueSapphire, GridPoint(row: 2, col: 2): .blueSapphire, GridPoint(row: 3, col: 6): .blueSapphire, GridPoint(row: 0, col: 6): .blueSapphire, GridPoint(row: 0, col: 5): .blueSapphire]),
            targets: [.redRuby: 5, .emerald: 5, .star: 6, .orangePentagon: 5, .blueSapphire: 6]
        ),
        AdventureLevel(
            id: 45,
            title: "Level 45",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 3, col: 4): .blueSapphire, GridPoint(row: 5, col: 2): .blueSapphire, GridPoint(row: 5, col: 6): .blueSapphire, GridPoint(row: 2, col: 4): .blueSapphire, GridPoint(row: 4, col: 7): .blueSapphire, GridPoint(row: 0, col: 5): .star, GridPoint(row: 2, col: 6): .star, GridPoint(row: 3, col: 2): .star, GridPoint(row: 0, col: 0): .star, GridPoint(row: 4, col: 0): .star, GridPoint(row: 1, col: 7): .redRuby, GridPoint(row: 2, col: 5): .redRuby, GridPoint(row: 6, col: 0): .redRuby, GridPoint(row: 1, col: 4): .redRuby, GridPoint(row: 2, col: 7): .redRuby, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 3, col: 7): .emerald, GridPoint(row: 1, col: 3): .emerald, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 5, col: 1): .emerald, GridPoint(row: 7, col: 5): .emerald, GridPoint(row: 1, col: 5): .emerald, GridPoint(row: 3, col: 3): .orangePentagon, GridPoint(row: 2, col: 0): .orangePentagon, GridPoint(row: 6, col: 3): .orangePentagon, GridPoint(row: 6, col: 5): .orangePentagon, GridPoint(row: 7, col: 3): .orangePentagon]),
            targets: [.blueSapphire: 5, .star: 5, .redRuby: 5, .emerald: 7, .orangePentagon: 5]
        ),
        AdventureLevel(
            id: 46,
            title: "Level 46",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 0, col: 3): .blueSapphire, GridPoint(row: 1, col: 0): .blueSapphire, GridPoint(row: 7, col: 3): .blueSapphire, GridPoint(row: 7, col: 2): .blueSapphire, GridPoint(row: 2, col: 0): .blueSapphire, GridPoint(row: 7, col: 4): .blueSapphire, GridPoint(row: 6, col: 0): .star, GridPoint(row: 3, col: 4): .star, GridPoint(row: 3, col: 7): .star, GridPoint(row: 6, col: 2): .star, GridPoint(row: 4, col: 6): .star, GridPoint(row: 3, col: 6): .star, GridPoint(row: 4, col: 3): .redRuby, GridPoint(row: 0, col: 5): .redRuby, GridPoint(row: 1, col: 1): .redRuby, GridPoint(row: 3, col: 5): .redRuby, GridPoint(row: 3, col: 3): .redRuby, GridPoint(row: 3, col: 0): .emerald, GridPoint(row: 2, col: 2): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 7, col: 0): .emerald, GridPoint(row: 0, col: 1): .emerald, GridPoint(row: 2, col: 5): .orangePentagon, GridPoint(row: 5, col: 2): .orangePentagon, GridPoint(row: 5, col: 1): .orangePentagon, GridPoint(row: 0, col: 7): .orangePentagon, GridPoint(row: 7, col: 6): .orangePentagon, GridPoint(row: 7, col: 1): .orangePentagon]),
            targets: [.blueSapphire: 6, .star: 6, .redRuby: 5, .emerald: 5, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 47,
            title: "Level 47",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 2, col: 1): .blueSapphire, GridPoint(row: 7, col: 5): .blueSapphire, GridPoint(row: 3, col: 5): .blueSapphire, GridPoint(row: 3, col: 3): .blueSapphire, GridPoint(row: 7, col: 6): .blueSapphire, GridPoint(row: 0, col: 2): .star, GridPoint(row: 6, col: 6): .star, GridPoint(row: 1, col: 3): .star, GridPoint(row: 1, col: 4): .star, GridPoint(row: 0, col: 1): .star, GridPoint(row: 1, col: 6): .redRuby, GridPoint(row: 0, col: 5): .redRuby, GridPoint(row: 1, col: 7): .redRuby, GridPoint(row: 5, col: 6): .redRuby, GridPoint(row: 4, col: 2): .redRuby, GridPoint(row: 5, col: 1): .redRuby, GridPoint(row: 6, col: 3): .redRuby, GridPoint(row: 4, col: 1): .emerald, GridPoint(row: 2, col: 0): .emerald, GridPoint(row: 5, col: 3): .emerald, GridPoint(row: 0, col: 3): .emerald, GridPoint(row: 3, col: 2): .emerald, GridPoint(row: 2, col: 4): .orangePentagon, GridPoint(row: 1, col: 5): .orangePentagon, GridPoint(row: 2, col: 3): .orangePentagon, GridPoint(row: 7, col: 2): .orangePentagon, GridPoint(row: 5, col: 5): .orangePentagon, GridPoint(row: 1, col: 1): .orangePentagon]),
            targets: [.blueSapphire: 5, .star: 5, .redRuby: 7, .emerald: 5, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 48,
            title: "Level 48",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 3, col: 7): .blueSapphire, GridPoint(row: 0, col: 4): .blueSapphire, GridPoint(row: 1, col: 5): .blueSapphire, GridPoint(row: 0, col: 3): .blueSapphire, GridPoint(row: 1, col: 2): .blueSapphire, GridPoint(row: 5, col: 5): .blueSapphire, GridPoint(row: 2, col: 7): .star, GridPoint(row: 1, col: 7): .star, GridPoint(row: 5, col: 0): .star, GridPoint(row: 0, col: 5): .star, GridPoint(row: 3, col: 2): .star, GridPoint(row: 2, col: 0): .redRuby, GridPoint(row: 4, col: 3): .redRuby, GridPoint(row: 7, col: 7): .redRuby, GridPoint(row: 7, col: 3): .redRuby, GridPoint(row: 5, col: 2): .redRuby, GridPoint(row: 3, col: 5): .redRuby, GridPoint(row: 1, col: 1): .emerald, GridPoint(row: 5, col: 7): .emerald, GridPoint(row: 3, col: 0): .emerald, GridPoint(row: 6, col: 2): .emerald, GridPoint(row: 6, col: 7): .emerald, GridPoint(row: 5, col: 3): .emerald, GridPoint(row: 6, col: 0): .emerald, GridPoint(row: 7, col: 4): .orangePentagon, GridPoint(row: 4, col: 5): .orangePentagon, GridPoint(row: 5, col: 4): .orangePentagon, GridPoint(row: 1, col: 3): .orangePentagon, GridPoint(row: 1, col: 6): .orangePentagon]),
            targets: [.blueSapphire: 6, .star: 5, .redRuby: 6, .emerald: 7, .orangePentagon: 5]
        ),
        AdventureLevel(
            id: 49,
            title: "Level 49",
            subtitle: "Difficulty 5",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 6, col: 7): .blueSapphire, GridPoint(row: 4, col: 6): .blueSapphire, GridPoint(row: 2, col: 0): .blueSapphire, GridPoint(row: 0, col: 4): .blueSapphire, GridPoint(row: 5, col: 3): .blueSapphire, GridPoint(row: 4, col: 0): .blueSapphire, GridPoint(row: 1, col: 6): .star, GridPoint(row: 5, col: 7): .star, GridPoint(row: 7, col: 0): .star, GridPoint(row: 0, col: 1): .star, GridPoint(row: 4, col: 1): .star, GridPoint(row: 1, col: 1): .star, GridPoint(row: 3, col: 6): .redRuby, GridPoint(row: 2, col: 4): .redRuby, GridPoint(row: 4, col: 3): .redRuby, GridPoint(row: 4, col: 4): .redRuby, GridPoint(row: 7, col: 2): .redRuby, GridPoint(row: 1, col: 2): .redRuby, GridPoint(row: 5, col: 5): .emerald, GridPoint(row: 0, col: 7): .emerald, GridPoint(row: 5, col: 0): .emerald, GridPoint(row: 2, col: 1): .emerald, GridPoint(row: 7, col: 4): .emerald, GridPoint(row: 3, col: 1): .orangePentagon, GridPoint(row: 2, col: 6): .orangePentagon, GridPoint(row: 6, col: 0): .orangePentagon, GridPoint(row: 7, col: 3): .orangePentagon, GridPoint(row: 1, col: 7): .orangePentagon, GridPoint(row: 4, col: 2): .orangePentagon]),
            targets: [.blueSapphire: 6, .star: 6, .redRuby: 6, .emerald: 5, .orangePentagon: 6]
        ),
        AdventureLevel(
            id: 50,
            title: "Level 50",
            subtitle: "Difficulty 6",
            initialGrid: buildGrid(gemPlacements: [GridPoint(row: 5, col: 4): .blueSapphire, GridPoint(row: 0, col: 2): .blueSapphire, GridPoint(row: 1, col: 3): .blueSapphire, GridPoint(row: 3, col: 1): .blueSapphire, GridPoint(row: 1, col: 2): .blueSapphire, GridPoint(row: 4, col: 0): .blueSapphire, GridPoint(row: 4, col: 2): .star, GridPoint(row: 2, col: 5): .star, GridPoint(row: 2, col: 7): .star, GridPoint(row: 4, col: 5): .star, GridPoint(row: 3, col: 2): .star, GridPoint(row: 7, col: 4): .star, GridPoint(row: 3, col: 7): .redRuby, GridPoint(row: 5, col: 2): .redRuby, GridPoint(row: 7, col: 1): .redRuby, GridPoint(row: 5, col: 0): .redRuby, GridPoint(row: 4, col: 3): .redRuby, GridPoint(row: 6, col: 7): .redRuby, GridPoint(row: 3, col: 5): .emerald, GridPoint(row: 7, col: 7): .emerald, GridPoint(row: 3, col: 6): .emerald, GridPoint(row: 7, col: 5): .emerald, GridPoint(row: 4, col: 1): .emerald, GridPoint(row: 1, col: 6): .emerald, GridPoint(row: 4, col: 7): .orangePentagon, GridPoint(row: 0, col: 0): .orangePentagon, GridPoint(row: 1, col: 4): .orangePentagon, GridPoint(row: 5, col: 6): .orangePentagon, GridPoint(row: 5, col: 7): .orangePentagon, GridPoint(row: 0, col: 7): .orangePentagon]),
            targets: [.blueSapphire: 6, .star: 6, .redRuby: 6, .emerald: 6, .orangePentagon: 6]
        )
    ]

    static func level(for id: Int) -> AdventureLevel? {
        all.first { $0.id == id }
    }

    static func colorPreset(for level: AdventureLevel) -> [[NeonColor?]] {
        level.initialGrid.map { row in
            row.map { $0.renderColor }
        }
    }
}

// MARK: - AdventureGridManager

final class AdventureGridManager: ObservableObject {

    @Published private(set) var cellStates: [[GridCellState]] =
        Array(repeating: Array(repeating: .empty, count: GridManager.gridSize),
              count: GridManager.gridSize)

    @Published private(set) var lastClearedGems: [TargetGem] = []

    private let core = GridManager()

    func load(level: AdventureLevel) {
        cellStates = level.initialGrid
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

    func canPlace(shape: BlockShape, at origin: GridPoint) -> Bool {
        core.canPlace(shape: shape, at: origin)
    }

    @discardableResult
    func place(shape: BlockShape, color: NeonColor, at origin: GridPoint, gem: TargetGem? = nil) -> [GridPoint] {
        let placed = core.place(shape: shape, color: color, at: origin)
        for (idx, p) in placed.enumerated() {
            if idx == 0, let g = gem {
                cellStates[p.row][p.col] = .target(g)
            } else {
                cellStates[p.row][p.col] = .normal(color)
            }
        }
        return placed
    }

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

    func anyMovePossible(shapes: [BlockShape]) -> Bool {
        core.anyMovePossible(shapes: shapes)
    }

    func canPlaceAnywhere(shape: BlockShape) -> Bool {
        core.canPlaceAnywhere(shape: shape)
    }
}
