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
    
    let columns = [GridItem(.flexible(), spacing: 20)]
    
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
                    
                    Text("MORE GAMES")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: Color.cyan, radius: 10)
                        .shadow(color: Color.cyan.opacity(0.5), radius: 20)
                    
                    Spacer()
                    
                    // Spacer for balance
                    Circle().fill(Color.clear).frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Tic-Tac-Toe Card (Functional)
                        NavigationLink(destination: TicTacToeView()) {
                            GameCard(
                                title: "TIC-TAC-TOE",
                                subtitle: "NEON BATTLE",
                                imagePath: "tic_tac_toe_card_1777812887098.png",
                                glowColor: Color.cyan
                            )
                        }
                        
                        // Snake Card (Placeholder)
                        GameCard(
                            title: "NEON SNAKE",
                            subtitle: "COMING SOON",
                            imagePath: "snake_game_card_1777812902809.png",
                            glowColor: Color.green
                        )
                        .opacity(0.8)
                        
                        // Arrow Escape Card (Placeholder)
                        GameCard(
                            title: "ARROW ESCAPE",
                            subtitle: "COMING SOON",
                            imagePath: "arrow_escape_card_1777812919540.png",
                            glowColor: Color.orange
                        )
                        .opacity(0.8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
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
    let imagePath: String
    let glowColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section
            ZStack {
                if let uiImage = UIImage(contentsOfFile: "/Users/junaidamin/Documents/Projects/Neon Grid Buster/GridBuster/Resources/Images/\(imagePath)") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(height: 180)
                        .overlay(Text("Loading...").foregroundColor(.white))
                }
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            // Text Section
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(glowColor.opacity(0.9))
                    .tracking(2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [glowColor.opacity(0.6), glowColor.opacity(0.1), glowColor.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: glowColor.opacity(0.3), radius: 15, x: 0, y: 5)
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
