//
//  ScoreManager.swift
//  NeonGridBuster
//

import Foundation
import Combine

@MainActor
final class ScoreManager: ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var bestScore: Int = 0
    @Published private(set) var combo: Int = 0
    @Published var isGameOver: Bool = false

    private var lastMoveCleared: Bool = false

    private let bestKey = "NeonGridBuster.bestScore"

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestKey)
    }

    func reset() {
        score = 0
        combo = 0
        lastMoveCleared = false
        isGameOver = false
    }

    func applyMove(placedCells: Int, linesCleared: Int) {
        let placePoints = placedCells * 5
        let linePoints = linesCleared * 120
        let multiLineBonus = max(0, linesCleared - 1) * 180

        if linesCleared > 0 {
            combo = lastMoveCleared ? (combo + 1) : 1
            lastMoveCleared = true
        } else {
            combo = 0
            lastMoveCleared = false
        }

        let comboBonus = (linesCleared > 0) ? (combo * 60) : 0

        score += placePoints + linePoints + multiLineBonus + comboBonus
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestKey)
        }
    }
}
