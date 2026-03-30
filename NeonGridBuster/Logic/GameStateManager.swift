//
//  GameStateManager.swift
//  NeonGridBuster
//

import Combine
import Foundation

// MARK: - SavedGameState
struct SavedGameState: Codable {
    var score: Int
    var combo: Int
    var currentPaletteIndex: Int
    var paletteColorCursor: Int
    var gridCells: [[String?]] // NeonColor string representation or nil
    var trayShapeIDs: [String?] // BlockShape.id or nil
    var trayColors: [String?]   // NeonColor string representation or nil
}

// MARK: - GameStateManager
final class GameStateManager: ObservableObject {
    static let shared = GameStateManager()
    private let saveKey = "savedClassicState"

    @Published private(set) var savedState: SavedGameState?
    
    init() {
        loadState()
    }
    
    func saveState(
        score: Int,
        combo: Int,
        paletteIndex: Int,
        paletteCursor: Int,
        grid: [[NeonColor?]],
        tray: [(shape: BlockShape, color: NeonColor)?]
    ) {
        let gridCells = grid.map { row in
            row.map { $0?.rawValue }
        }
        
        let trayShapeIDs = tray.map { $0?.shape.id }
        let trayColors = tray.map { $0?.color.rawValue }
        
        let state = SavedGameState(
            score: score,
            combo: combo,
            currentPaletteIndex: paletteIndex,
            paletteColorCursor: paletteCursor,
            gridCells: gridCells,
            trayShapeIDs: trayShapeIDs,
            trayColors: trayColors
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: saveKey)
            self.savedState = state
        }
    }
    
    func loadState() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let state = try? JSONDecoder().decode(SavedGameState.self, from: data) {
            self.savedState = state
        } else {
            self.savedState = nil
        }
    }
    
    func clearState() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        self.savedState = nil
    }
}
