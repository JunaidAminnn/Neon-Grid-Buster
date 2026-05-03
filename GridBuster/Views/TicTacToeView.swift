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
    @State private var player1Name: String = ""
    @State private var player2Name: String = ""
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
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                            .shadow(color: .white.opacity(0.3), radius: 8)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: -4) {
                        NeonText(text: "TIC TAC", color: Theme.Palette.neonCyan, size: 32)
                        NeonText(text: "TOE", color: Theme.Palette.neonPink, size: 44)
                    }
                    .offset(y: titleOffset)
                    
                    Spacer()
                    
                    // Reset / Setup trigger
                    Button(action: { withAnimation { showSetup = true } }) {
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Status Bar
                StatusIndicator(text: statusText, color: currentTurnColor)
                
                // Game Board
                ZStack {
                    // Outer glow for the board
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.black.opacity(0.4))
                        .shadow(color: boardGlowColor.opacity(0.25), radius: 30)
                    
                    LazyVGrid(columns: columns, spacing: 18) {
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
                    .padding(25)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 450)
                
                Spacer()
            }
            
            // Player Setup Overlay
            if showSetup {
                SetupOverlay(
                    p1Name: $player1Name,
                    p2Name: $player2Name,
                    p1Color: $player1Color,
                    p2Color: $player2Color,
                    colors: availableColors,
                    onStart: {
                        if player1Name.isEmpty { player1Name = "Player 1" }
                        if player2Name.isEmpty { player2Name = "Player 2" }
                        withAnimation(.spring()) {
                            showSetup = false
                            resetGame()
                        }
                    }
                )
            }
            
            // Victory Overlay
            if gameOver {
                VictoryOverlay(
                    winnerName: winnerName,
                    winnerColor: winnerColor,
                    isDraw: winner == nil,
                    onRestart: resetGame,
                    onExit: { dismiss() }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                titleOffset = 0
            }
            glowPulse = true
        }
    }
    
    // MARK: - Logic
    
    var winnerName: String {
        if let winner = winner {
            return winner == "X" ? player1Name : player2Name
        }
        return "STALEMATE"
    }
    
    var winnerColor: Color {
        if let winner = winner {
            return winner == "X" ? player1Color : player2Color
        }
        return .white
    }
    
    var currentTurnColor: Color {
        if gameOver { return .gray }
        return isXTurn ? player1Color : player2Color
    }
    
    var boardGlowColor: Color {
        if let winner = winner {
            return winner == "X" ? player1Color : player2Color
        }
        return .white
    }
    
    var statusText: String {
        if let _ = winner {
            return "\(winnerName.uppercased()) VICTORIOUS!"
        } else if gameOver {
            return "STALEMATE"
        } else {
            let currentPlayer = isXTurn ? player1Name : player2Name
            return "\(currentPlayer.uppercased())'S TURN"
        }
    }
    
    func makeMove(at index: Int) {
        guard board[index] == "" && !gameOver && !showSetup else { return }
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
            board[index] = isXTurn ? "X" : "O"
            checkWinner()
            if !gameOver {
                isXTurn.toggle()
            }
        }
    }
    
    func checkWinner() {
        let winPatterns: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]
        ]
        
        for pattern in winPatterns {
            if board[pattern[0]] != "" && board[pattern[0]] == board[pattern[1]] && board[pattern[0]] == board[pattern[2]] {
                withAnimation(.easeInOut(duration: 0.5)) {
                    winner = board[pattern[0]]
                    winIndices = pattern
                    gameOver = true
                }
                startWinAnimation()
                return
            }
        }
        
        if !board.contains("") {
            withAnimation {
                gameOver = true
            }
        }
    }
    
    func startWinAnimation() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            winFlash = true
        }
    }
    
    func resetGame() {
        withAnimation(.spring()) {
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
            Color.black.opacity(0.9).ignoresSafeArea()
                .blur(radius: 10)
            
            VStack(spacing: 30) {
                Text("NEON SETUP")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(6)
                    .shadow(color: p1Color.opacity(0.5), radius: 10)
                
                VStack(spacing: 25) {
                    SetupSection(name: $p1Name, selectedColor: $p1Color, label: "PLAYER 1 (X)", colors: colors)
                    SetupSection(name: $p2Name, selectedColor: $p2Color, label: "PLAYER 2 (O)", colors: colors)
                }
                .padding(.horizontal, 25)
                
                Button(action: onStart) {
                    Text("LAUNCH BATTLE")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(p1Color.opacity(0.15))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [p1Color, p2Color], startPoint: .leading, endPoint: .trailing), lineWidth: 3))
                        )
                        .shadow(color: p1Color.opacity(0.4), radius: 15)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 35)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 35).stroke(Color.white.opacity(0.1), lineWidth: 1))
            )
            .padding(.horizontal, 20)
        }
    }
}

struct SetupSection: View {
    @Binding var name: String
    @Binding var selectedColor: Color
    let label: String
    let colors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(selectedColor)
                .tracking(2)
            
            TextField("Commander Name", text: $name)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(selectedColor.opacity(0.4), lineWidth: 2))
                .foregroundStyle(.white)
            
            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0))
                        .shadow(color: color.opacity(0.6), radius: 5)
                        .onTapGesture {
                            withAnimation(.spring()) { selectedColor = color }
                        }
                }
            }
            .padding(.top, 4)
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
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text(isDraw ? "STALEMATE" : "VICTORY")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: winnerColor, radius: 20)
                    
                    if !isDraw {
                        Text(winnerName.uppercased())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(winnerColor)
                            .tracking(8)
                    }
                }
                
                VStack(spacing: 18) {
                    Button(action: onRestart) {
                        Text("BATTLE AGAIN")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(winnerColor.opacity(0.2))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(winnerColor, lineWidth: 3))
                            )
                            .shadow(color: winnerColor.opacity(0.5), radius: 15)
                    }
                    
                    Button(action: onExit) {
                        Text("EXIT TO HUB")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Subviews

struct NeonText: View {
    let text: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Text(text)
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .blur(radius: 12)
                .opacity(0.7)
            
            Text(text)
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: color, radius: 4)
                .shadow(color: color.opacity(0.8), radius: 12)
        }
    }
}

struct StatusIndicator: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color, radius: 5)
            
            Text(text)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .tracking(3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        )
        .shadow(color: color.opacity(0.2), radius: 10)
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
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isWinningCell ? (winFlash ? Color.white : cellColor) : Color.white.opacity(0.12),
                                lineWidth: isWinningCell ? 4 : 2
                            )
                    )
                    .shadow(color: isWinningCell ? cellColor.opacity(0.6) : .clear, radius: 15)
                
                if value != "" {
                    ZStack {
                        // Outer bloom
                        Text(value)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundStyle(isWinningCell && winFlash ? Color.white : cellColor)
                            .blur(radius: 15)
                            .opacity(0.8)
                        
                        // Crisp white core
                        Text(value)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: cellColor, radius: 8)
                            .shadow(color: cellColor.opacity(0.6), radius: 20)
                            .scaleEffect(isWinningCell && winFlash ? 1.1 : 1.0)
                    }
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .frame(height: 110)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var cellColor: Color {
        value == "X" ? xColor : oColor
    }
}

// Reuse background from MainMenu for consistency
private struct MenuBackground: View {
    let pulse: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0x0D / 255.0, green: 0x01 / 255.0, blue: 0x2B / 255.0),
                    Color(red: 0x06 / 255.0, green: 0x00 / 255.0, blue: 0x12 / 255.0),
                    Color(red: 0x00 / 255.0, green: 0x01 / 255.0, blue: 0x05 / 255.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0, green: 1, blue: 1).opacity(pulse ? 0.16 : 0.07), .clear],
                center: .topLeading, startRadius: 0, endRadius: 420
            )
            .blendMode(.plusLighter)
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 1, green: 0, blue: 1).opacity(pulse ? 0.14 : 0.06), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 380
            )
            .blendMode(.plusLighter)
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)
    }
}


