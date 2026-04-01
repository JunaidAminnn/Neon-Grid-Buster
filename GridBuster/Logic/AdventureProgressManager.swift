//
//  AdventureProgressManager.swift
//  NeonGridBuster
//
//  Prompt 3 — Adventure Map & Level Progression
//  ─────────────────────────────────────────────────────────────────────────
//  Singleton that persists which Adventure levels the player has completed
//  and exposes the data needed by AdventureMapView for the fill animation.
//

import Foundation
import SwiftUI
import Combine

// MARK: - AdventureProgressManager

@MainActor
final class AdventureProgressManager: ObservableObject {

    // ── Singleton ─────────────────────────────────────────────────────────
    static let shared = AdventureProgressManager()

    // ── Published State ───────────────────────────────────────────────────

    /// Set of level IDs the player has beaten at least once.
    @Published private(set) var completedLevelIDs: Set<Int> = []

    // ── Persistence ───────────────────────────────────────────────────────

    private let storageKey = "adventure_completed_levels"

    // MARK: - Init

    private init() {
        load()
    }

    // MARK: - Public API

    /// Records `levelID` as completed and persists the change.
    func markComplete(levelID: Int) {
        guard !completedLevelIDs.contains(levelID) else { return }
        completedLevelIDs.insert(levelID)
        persist()
    }

    /// Returns true if `levelID` has already been cleared.
    func isCompleted(_ levelID: Int) -> Bool {
        completedLevelIDs.contains(levelID)
    }

    // MARK: - Derived Properties

    /// The ID of the next level the player should attempt —
    /// first uncompleted in `AdventureRegistry.all`, or the last one if all done.
    var nextLevelID: Int {
        for level in AdventureRegistry.all {
            if !completedLevelIDs.contains(level.id) { return level.id }
        }
        return AdventureRegistry.all.last?.id ?? 1
    }

    /// Whether the player has beaten every available level.
    var allLevelsComplete: Bool {
        AdventureRegistry.all.allSatisfy { completedLevelIDs.contains($0.id) }
    }

    /// 0.0 → 1.0 fraction of levels completed.
    var completionFraction: Double {
        let total = Double(AdventureRegistry.all.count)
        guard total > 0 else { return 0 }
        return min(1.0, Double(completedLevelIDs.count) / total)
    }

    var anyCompleted: Bool { !completedLevelIDs.isEmpty }

    // MARK: - Tiger Fill Data

    /// The tiger pixel map (11 × 11, 1 = filled cell in tiger silhouette).
    /// Identical to the one rendered by AdventureMapView.
    static let tigerPixels: [[Int]] = [
        [0,0,1,0,0,0,0,0,1,0,0],   // row 0  — ear tips
        [0,1,1,1,0,0,0,1,1,1,0],   // row 1  — ears
        [0,1,1,1,1,1,1,1,1,1,0],   // row 2  — crown
        [1,1,1,1,1,1,1,1,1,1,1],   // row 3  — forehead
        [1,1,0,0,1,1,1,0,0,1,1],   // row 4  — eye sockets
        [1,1,1,1,1,1,1,1,1,1,1],   // row 5  — nose bridge
        [1,1,1,0,1,1,1,0,1,1,1],   // row 6  — nostrils
        [1,1,1,1,1,1,1,1,1,1,1],   // row 7  — muzzle
        [0,1,0,1,1,0,1,1,0,1,0],   // row 8  — whisker spots
        [0,0,1,1,1,1,1,1,1,0,0],   // row 9  — lower chin
        [0,0,0,0,1,1,1,0,0,0,0],   // row 10 — jaw / neck
    ]

    /// All (row, col) pixel positions inside the tiger silhouette,
    /// sorted **bottom-to-top** (row descending) so fill animation rises upward.
    static let tigerPositionsSorted: [(row: Int, col: Int)] = {
        var positions: [(row: Int, col: Int)] = []
        for row in 0..<tigerPixels.count {
            for col in 0..<tigerPixels[row].count {
                if tigerPixels[row][col] == 1 {
                    positions.append((row: row, col: col))
                }
            }
        }
        // Sort bottom (large row index) → top (small row index)
        return positions.sorted { ($0.row, $0.col) > ($1.row, $1.col) }
    }()

    static var totalTigerPixels: Int { tigerPositionsSorted.count }

    /// How many tiger pixels should glow given the current completion fraction.
    var litPixelCount: Int {
        Int(Double(AdventureProgressManager.totalTigerPixels) * completionFraction)
    }

    /// True if the pixel at `(row, col)` should be rendered as lit (neon magenta).
    func isPixelLit(row: Int, col: Int) -> Bool {
        let idx = AdventureProgressManager.tigerPositionsSorted.firstIndex {
            $0.row == row && $0.col == col
        }
        guard let idx else { return false }
        return idx < litPixelCount
    }

    // MARK: - Persistence

    private func load() {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? ""
        completedLevelIDs = Set(raw.split(separator: ",").compactMap { Int($0) })
    }

    private func persist() {
        let raw = completedLevelIDs.map(String.init).joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: storageKey)
    }

    // MARK: - Debug

    #if DEBUG
    func resetProgress() {
        completedLevelIDs = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    #endif
}
