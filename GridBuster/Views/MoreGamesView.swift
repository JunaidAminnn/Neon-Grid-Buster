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
                // Custom Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("GAMES HUB")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.Palette.neonCyan)
                            .tracking(8)
                        
                        Text("MORE GAMES")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Theme.Palette.neonCyan, radius: 15)
                    }
                    
                    Spacer()
                    
                    // Spacer for balance
                    Circle().fill(Color.clear).frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 30)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Tic-Tac-Toe Card (Functional)
                        NavigationLink(destination: TicTacToeView()) {
                            GameCard(
                                title: "TIC-TAC-TOE",
                                subtitle: "NEON BATTLE",
                                imageName: "tic_tac_toe_card",
                                glowColor: Theme.Palette.neonCyan,
                                isAvailable: true
                            )
                        }
                        
                        // Snake Card (Placeholder)
                        GameCard(
                            title: "NEON SNAKE",
                            subtitle: "COMING SOON",
                            imageName: "snake_game_card",
                            glowColor: Theme.Palette.neonLime,
                            isAvailable: false
                        )
                        
                        // Arrow Escape Card (Placeholder)
                        GameCard(
                            title: "ARROW ESCAPE",
                            subtitle: "COMING SOON",
                            imageName: "arrow_escape_card",
                            glowColor: Theme.Palette.neonOrange,
                            isAvailable: false
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
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
    let isAvailable: Bool
    
    @State private var pulse = false
    @State private var angle: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section
            ZStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .grayscale(isAvailable ? 0 : 0.6)
                    .brightness(isAvailable ? 0 : -0.1)
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                if !isAvailable {
                    VStack {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.5))
                            .shadow(color: glowColor, radius: 10)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            // Text Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if isAvailable {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Circle().fill(glowColor.opacity(0.8)))
                            .shadow(color: glowColor, radius: 10)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(isAvailable ? glowColor : Color.gray)
                    .tracking(3)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            glowColor.opacity(isAvailable ? 0.7 : 0.3),
                            glowColor.opacity(0.1),
                            glowColor.opacity(isAvailable ? 0.5 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: glowColor.opacity(isAvailable ? (pulse ? 0.4 : 0.2) : 0.1), radius: pulse ? 20 : 15, x: 0, y: 5)
        .scaleEffect(pulse && isAvailable ? 1.02 : 1.0)
        .onAppear {
            if isAvailable {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
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
