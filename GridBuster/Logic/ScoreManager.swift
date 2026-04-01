//
//  ScoreManager.swift
//  NeonGridBuster
//
//  Prompt 3.3 — Core Loop: tiered line-clearing scoring, exponential multi-line
//  bonuses, board-clear bonus, combo chain, and best-score persistence.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class ScoreManager: ObservableObject {

    // ── Published state (drives all game UI) ────────────────────────────
    @Published private(set) var score:       Int  = 0
    @Published private(set) var bestScore:   Int  = 0
    /// Consecutive-clear streak (resets when a placement clears nothing).
    @Published private(set) var combo:       Int  = 0
    @Published var isGameOver: Bool = false

    // ── Private ──────────────────────────────────────────────────────────
    private var lastMoveCleared: Bool = false
    private var comboGraceMoves: Int  = 0
    private let bestKey = "NeonGridBuster.bestScore"

    // MARK: - Init

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestKey)
    }

    // MARK: - Reset

    func reset() {
        score           = 0
        combo           = 0
        lastMoveCleared = false
        comboGraceMoves = 0
        isGameOver      = false
    }

    func restoreState(score: Int, combo: Int) {
        self.score = score
        self.combo = combo
    }

    // MARK: - Tiered Line Score (Prompt 3.3)

    /// Exponential line-clear points matching spec exactly.
    ///
    ///  1 line  =    100 pts
    ///  2 lines =    400 pts   (4× the 1-line value)
    ///  3 lines =  1 200 pts   (3× the 2-line value)
    ///  4 lines =  4 000 pts   (3.3× the 3-line value)
    ///  5+      continues tripling each additional line.
    static func lineScore(for linesCleared: Int) -> Int {
        switch linesCleared {
        case 0:  return 0
        case 1:  return 100
        case 2:  return 400
        case 3:  return 1_200
        case 4:  return 4_000
        default:
            // 5+ lines: continue roughly tripling from the 4-line value.
            var pts = 4_000
            for _ in 0..<(linesCleared - 4) { pts = pts * 3 }
            return pts
        }
    }

    // MARK: - Apply Move

    /// Called after every valid block placement + line-clear pass.
    ///
    /// - Parameters:
    ///   - placedCells:      Number of cells in the placed shape (minor fill reward).
    ///   - totalLinesCleared: Total rows + cols cleared this move.
    ///   - isBoardClear:     `true` if every grid cell is empty after clearing.
    func applyMove(placedCells: Int, totalLinesCleared: Int, isBoardClear: Bool) {

        // ── 1. Update combo FIRST so the multiplier is correct this turn ─
        if totalLinesCleared > 0 {
            // If combo > 0, it means it hasn't been reset by missing too many moves.
            // On the 3rd turn after a clear (graceMoves 2 -> 1 -> 0), combo is still > 0.
            combo           = (combo > 0) ? combo + 1 : 1
            lastMoveCleared = true
            comboGraceMoves = 2   // Reset grace period on any clear
        } else {
            if comboGraceMoves > 0 {
                comboGraceMoves -= 1
                // We DON'T reset combo here, lastMoveCleared stays false
                lastMoveCleared = false
            } else {
                combo           = 0
                lastMoveCleared = false
            }
        }

        // ── 2. Cell-fill points ─────────────────────────────────────────
        let cellPoints = placedCells * 2

        // ── 3. Tiered line score × true combo multiplier ────────────────
        //       Combo 1 = 1× · Combo 2 = 2× · Combo 3 = 3× …
        let comboMultiplier = totalLinesCleared > 0 ? combo : 1
        let linePoints      = Self.lineScore(for: totalLinesCleared) * comboMultiplier

        // ── 4. Perfect board-clear bonus ────────────────────────────────
        let boardBonus = isBoardClear ? 10_000 : 0

        // ── 5. Accumulate and persist best score ────────────────────────
        let delta = cellPoints + linePoints + boardBonus
        score += delta

        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestKey)
        }
    }
}
