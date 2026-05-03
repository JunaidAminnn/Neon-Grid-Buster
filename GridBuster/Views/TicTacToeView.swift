//
//  TicTacToeView.swift
//  NeonGridBuster
//
//  A premium Neon-themed Tic Tac Toe game with high contrast and glowing UI.
//

import SwiftUI

struct TicTacToeView: View {
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @State private var board: [String] = Array(repeating: "", count: 9)
    @State private var isXTurn: Bool = true
    @State private var gameOver: Bool = false
    @State private var winner: String? = nil
    @State private var winIndices: [Int] = []
    
    // Player Setup
    @State private var showSetup: Bool = true
    @State private var player1Name: String = "Player 1"
    @State private var player2Name: String = "Player 2"
    @State private var player1Color: Color = Theme.Palette.neonCyan
    @State private var player2Color: Color = Theme.Palette.neonPink
    
    // Animations
    @State private var glowPulse: Bool = false
    @State private var titleOffset: CGFloat = -20
    @State private var winFlash: Bool = false
    
    let availableColors: [Color] = [
        Theme.Palette.neonCyan,
        Theme.Palette.neonPink,
        Theme.Palette.neonLime,
        Theme.Palette.neonYellow,
        Theme.Palette.neonOrange,
        Theme.Palette.neonPurple
    ]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 3)
    
    var body: some View {
        ZStack {
            // Background
            MenuBackground(pulse: glowPulse)
            
            VStack(spacing: 20) {
                // Refined Header (Single Line)
                HStack(alignment: .center) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    
                    Spacer()
                    
                    NeonText(text: "TIC TAC TOE", color: Theme.Palette.neonCyan, size: 28)
                        .offset(y: titleOffset)
                    
                    Spacer()
                    
                    Button(action: { withAnimation { showSetup = true } }) {
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // Status Bar
                StatusIndicator(text: statusText, color: currentTurnColor)
                
                // Game Board
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.black.opacity(0.6))
                        .shadow(color: boardGlowColor.opacity(0.4), radius: 40)
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(boardGlowColor.opacity(0.3), lineWidth: 2))
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(0..<9) { index in
                            NeonCell(
                                value: board[index],
                                isWinningCell: winIndices.contains(index),
                                winFlash: winFlash,
                                xColor: player1Color,
                                oColor: player2Color,
                                action: { makeMove(at: index) }
                            )
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 420)
                
                Spacer()
            }
            
            // Player Setup Overlay (NEON COMMAND)
            if showSetup {
                SetupOverlay(
                    p1Name: $player1Name,
                    p2Name: $player2Name,
                    p1Color: $player1Color,
                    p2Color: $player2Color,
                    colors: availableColors,
                    onStart: {
                        withAnimation(.spring()) {
                            showSetup = false
                            resetGame()
                        }
                    }
                )
                .zIndex(10)
            }
            
            // Victory Overlay (Detailed Card)
            if gameOver {
                VictoryOverlay(
                    winnerName: winnerName,
                    winnerColor: winnerColor,
                    isDraw: winner == nil,
                    onRestart: resetGame,
                    onExit: { dismiss() }
                )
                .zIndex(20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { titleOffset = 0 }
            glowPulse = true
        }
    }
    
    // MARK: - Logic
    
    var winnerName: String {
        if let winner = winner { return winner == "X" ? player1Name : player2Name }
        return "GRID LOCKED"
    }
    
    var winnerColor: Color {
        if let winner = winner { return winner == "X" ? player1Color : player2Color }
        return Theme.Palette.neonYellow // Neutral pro color for tie
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
            let name = isXTurn ? (player1Name.isEmpty ? "Player 1" : player1Name) : (player2Name.isEmpty ? "Player 2" : player2Name)
            return "\(name.uppercased())'S TURN" 
        }
    }
    
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

// MARK: - Refined Components

struct SetupOverlay: View {
    @Binding var p1Name: String
    @Binding var p2Name: String
    @Binding var p1Color: Color
    @Binding var p2Color: Color
    let colors: [Color]
    let onStart: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("MATCH SETUP")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: p1Color.opacity(0.6), radius: 15)
                
                VStack(spacing: 20) {
                    SetupSection(name: $p1Name, selectedColor: $p1Color, label: "PLAYER 1 (X)", placeholder: "Enter Player 1 Name", colors: colors)
                    SetupSection(name: $p2Name, selectedColor: $p2Color, label: "PLAYER 2 (O)", placeholder: "Enter Player 2 Name", colors: colors)
                }
                .padding(.horizontal, 25)
                
                Button(action: onStart) {
                    Text("LAUNCH BATTLE")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(p1Color.opacity(0.2))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [p1Color, p2Color], startPoint: .leading, endPoint: .trailing), lineWidth: 3))
                        )
                }
                .padding(.horizontal, 25)
            }
            .padding(.vertical, 30)
            .background(RoundedRectangle(cornerRadius: 40).fill(Color.white.opacity(0.05)))
            .padding(.horizontal, 20)
        }
    }
}

struct SetupSection: View {
    @Binding var name: String
    @Binding var selectedColor: Color
    let label: String
    let placeholder: String
    let colors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(selectedColor)
                .tracking(2)
            
            TextField(placeholder, text: $name)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(15)
                .background(Color.white.opacity(0.12)) // Brighter background
                .cornerRadius(15)
                .foregroundStyle(.white) // Ensure white text
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(selectedColor.opacity(0.6), lineWidth: 2))
            
            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0))
                        .onTapGesture { withAnimation { selectedColor = color } }
                }
            }
        }
    }
}

struct VictoryOverlay: View {
    let winnerName: String
    let winnerColor: Color
    let isDraw: Bool
    let onRestart: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            
            VStack(spacing: 35) {
                VStack(spacing: 12) {
                    Text(isDraw ? "GRID LOCKED" : "VICTORY")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(winnerColor)
                        .tracking(10)
                    
                    Text(isDraw ? "NO ONE SURVIVES" : "\(winnerName.uppercased())")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: winnerColor.opacity(0.6), radius: 15)
                    
                    if !isDraw {
                        Text("VICTORIOUS!")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(winnerColor)
                            .tracking(4)
                    }
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 30).fill(Color.white.opacity(0.05)))
                
                VStack(spacing: 18) {
                    Button(action: onRestart) {
                        Text("BATTLE AGAIN")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(winnerColor.opacity(0.2))
                                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(winnerColor, lineWidth: 3))
                            )
                            .shadow(color: winnerColor.opacity(0.5), radius: 15)
                    }
                    
                    Button(action: onExit) {
                        Text("EXIT TO HUB")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(35)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.1), lineWidth: 1))
            )
            .padding(.horizontal, 20)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Subviews

struct StatusIndicator: View {
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 14) {
            Circle().fill(color).frame(width: 12, height: 12).shadow(color: color, radius: 8)
            Text(text).font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(.white).tracking(4)
        }
        .padding(.horizontal, 24).padding(.vertical, 12)
        .background(Capsule().fill(Color.white.opacity(0.08)).overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 2)))
    }
}

struct NeonCell: View {
    let value: String
    let isWinningCell: Bool
    let winFlash: Bool
    let xColor: Color
    let oColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(isWinningCell ? (winFlash ? Color.white : cellColor) : cellColor.opacity(0.3), lineWidth: isWinningCell ? 5 : 2))
                
                if value != "" {
                    ZStack {
                        // VIBRANT CORE (NO MORE PLAIN WHITE)
                        Text(value)
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(cellColor) // Solid Neon Color
                            .shadow(color: cellColor, radius: 10)
                            .shadow(color: cellColor.opacity(0.6), radius: 25)
                        
                        Text(value)
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7)) // Inner spark
                            .blur(radius: 2)
                    }
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .frame(height: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var cellColor: Color {
        if value == "X" { return xColor }
        if value == "O" { return oColor }
        return .white
    }
}

struct NeonText: View {
    let text: String
    let color: Color
    let size: CGFloat
    var body: some View {
        ZStack {
            Text(text).font(.system(size: size, weight: .black, design: .rounded)).foregroundStyle(color).blur(radius: 12).opacity(0.7)
            Text(text).font(.system(size: size, weight: .black, design: .rounded)).foregroundStyle(.white).shadow(color: color, radius: 4)
        }
    }
}

// Background
private struct MenuBackground: View {
    let pulse: Bool
    var body: some View {
        ZStack {
            Theme.Palette.midnight.ignoresSafeArea()
            RadialGradient(colors: [Theme.Palette.neonCyan.opacity(pulse ? 0.16 : 0.08), .clear], center: .topLeading, startRadius: 0, endRadius: 500).ignoresSafeArea()
            RadialGradient(colors: [Theme.Palette.neonPink.opacity(pulse ? 0.16 : 0.08), .clear], center: .topTrailing, startRadius: 0, endRadius: 500).ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)
    }
}




