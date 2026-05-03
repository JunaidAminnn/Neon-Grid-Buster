//
//  MoreGamesView.swift
//  NeonGridBuster
//
//  A premium, neon-themed screen showcasing additional games.
//

import SwiftUI

struct MoreGamesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var glowPulse = false
    
    var body: some View {
        ZStack {
            // Background
            MenuBackground(pulse: glowPulse)
            
            VStack(spacing: 0) {
                // Vibrant Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                    }
                    
                    Spacer()
                    
                    Text("MORE GAMES")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: Theme.Palette.neonCyan.opacity(0.8), radius: 10)
                        .shadow(color: Theme.Palette.neonBlue.opacity(0.6), radius: 20)
                    
                    Spacer()
                    
                    // Spacer for balance
                    Circle().fill(Color.clear).frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 15)
                .padding(.bottom, 25)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Tic-Tac-Toe Card (Functional)
                        NavigationLink(destination: TicTacToeView()) {
                            GameCard(
                                title: "TIC-TAC-TOE",
                                subtitle: "NEON BATTLE",
                                imageName: "tic_tac_toe_card",
                                glowColor: Theme.Palette.neonCyan
                            )
                        }
                        
                        // Snake Card
                        GameCard(
                            title: "NEON SNAKE",
                            subtitle: "VIBRANT SLITHER",
                            imageName: "snake_game_card",
                            glowColor: Theme.Palette.neonLime
                        )
                        
                        // Arrow Escape Card
                        GameCard(
                            title: "ARROW ESCAPE",
                            subtitle: "SPEED RUN",
                            imageName: "arrow_escape_card",
                            glowColor: Theme.Palette.neonOrange
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            glowPulse = true
        }
    }
}

struct GameCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let glowColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // High-Contrast Image Section
            ZStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 190)
                    .clipped()
                
                // Vibrant gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            
            // Text Section
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8)) // Brighter gray/white
                    .tracking(3)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [glowColor.opacity(0.8), glowColor.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: glowColor.opacity(0.35), radius: 15, x: 0, y: 8)
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

#Preview {
    MoreGamesView()
}
