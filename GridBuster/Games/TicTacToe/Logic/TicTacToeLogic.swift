//
//  TicTacToeViewModel.swift
//  NeonGridBuster
//

import SwiftUI
import Combine

class TicTacToeViewModel: ObservableObject {
    // MARK: - State
    @Published var board: [String] = Array(repeating: "", count: 9)
    @Published var isXTurn: Bool = true
    @Published var gameOver: Bool = false
    @Published var winner: String? = nil
    @Published var winIndices: [Int] = []
    
    // Player Setup
    @Published var showSetup: Bool = true
    @Published var player1Name: String = ""
    @Published var player2Name: String = ""
    @Published var player1Color: Color = Theme.Palette.neonLime
    @Published var player2Color: Color = Theme.Palette.neonPurple
    
    // Animations Sync
    @Published var winFlash: Bool = false
    
    let availableColors: [Color] = [
        Theme.Palette.neonCyan, Theme.Palette.neonPink, Theme.Palette.neonLime,
        Theme.Palette.neonYellow, Theme.Palette.neonOrange, Theme.Palette.neonPurple
    ]
    
    // MARK: - Computed Properties
    
    var player1DisplayName: String {
        player1Name.isEmpty ? "Player 1" : player1Name
    }
    
    var player2DisplayName: String {
        player2Name.isEmpty ? "Player 2" : player2Name
    }
    
    var winnerName: String {
        if let winner = winner { return winner == "X" ? player1DisplayName : player2DisplayName }
        return "GRID LOCKED"
    }
    
    var winnerColor: Color {
        if let winner = winner { return winner == "X" ? player1Color : player2Color }
        return Theme.Palette.neonYellow
    }
    
    var currentTurnColor: Color {
        if gameOver { return winner == nil ? Theme.Palette.neonYellow : winnerColor }
        return isXTurn ? player1Color : player2Color
    }
    
    var boardGlowColor: Color {
        if let winner = winner { return winner == "X" ? player1Color : player2Color }
        if gameOver && winner == nil { return Theme.Palette.neonYellow }
        return isXTurn ? player1Color : player2Color
    }
    
    var statusText: String {
        if let _ = winner { return "\(winnerName.uppercased()) VICTORIOUS!" }
        else if gameOver { return "GRID LOCKED" }
        else { 
            let name = isXTurn ? player1DisplayName : player2DisplayName
            return "\(name.uppercased())'S TURN" 
        }
    }
    
    // MARK: - Logic
    
    func makeMove(at index: Int) {
        guard board[index] == "" && !gameOver && !showSetup else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            board[index] = isXTurn ? "X" : "O"
            checkWinner()
            if !gameOver { isXTurn.toggle() }
        }
    }
    
    func checkWinner() {
        let patterns: [[Int]] = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
        for p in patterns {
            if board[p[0]] != "" && board[p[0]] == board[p[1]] && board[p[0]] == board[p[2]] {
                withAnimation {
                    winner = board[p[0]]
                    winIndices = p
                    gameOver = true
                }
                withAnimation(.easeInOut(duration: 0.4).repeatForever()) { winFlash = true }
                return
            }
        }
        if !board.contains("") { withAnimation { gameOver = true } }
    }
    
    func resetGame() {
        withAnimation {
            board = Array(repeating: "", count: 9)
            isXTurn = true
            gameOver = false
            winner = nil
            winIndices = []
            winFlash = false
        }
    }
}
