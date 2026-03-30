//
//  GameView.swift
//  NeonGridBuster
//
//  Prompt 4.1 — Classic Gameplay UI (clone of image_4.png).
//  ─────────────────────────────────────────────────────────────────────────
//  Layout (top → bottom on solid #000000 background):
//    [Crown + Best]  |  [Large pink score — centre]  |  [Gear]
//    SpriteKit game board (fills remaining height)
//  ─────────────────────────────────────────────────────────────────────────

import SwiftUI
import SpriteKit
import Combine
import UIKit

// MARK: - GameMode

enum GameMode: String, Hashable {
    case adventure
    case classic

    var title: String {
        switch self {
        case .adventure: return "Adventure"
        case .classic:   return "Classic"
        }
    }
}

// MARK: - GameTheme
// Global colour-set variable (Prompt 4.1). Currently "Neon Midnight" = cyan / magenta.
// Swap .neonMidnight for a future theme to change all placed-block colours at once.
enum GameTheme: String, CaseIterable {
    case neonMidnight   // default: cyan fill, magenta accents
    case synthwave      // future: purple fill, orange accents
    case acidGreen      // future: lime fill, pink accents

    /// Primary block fill colour for this theme.
    var primaryNeonColor: NeonColor {
        switch self {
        case .neonMidnight: return .cyan
        case .synthwave:    return .purple
        case .acidGreen:    return .lime
        }
    }

    /// Secondary accent colour used for score text and gear icon.
    var accentNeonColor: NeonColor {
        switch self {
        case .neonMidnight: return .pink
        case .synthwave:    return .orange
        case .acidGreen:    return .pink
        }
    }
}

/// Shared app-level theme. Change this once to reskin the whole game.
let activeGameTheme: GameTheme = .neonMidnight

// MARK: - GameContainer

@MainActor
final class GameContainer: ObservableObject {
    let scoreManager = ScoreManager()
    let gameStateManager = GameStateManager.shared
    let scene: GameScene
    private var cancellable: AnyCancellable?

    init(adventurePreset: [[NeonColor?]]? = nil) {
        scene = GameScene(scoreManager: scoreManager, gameStateManager: gameStateManager, adventurePreset: adventurePreset)
        cancellable = scoreManager.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

// MARK: - GameView

struct GameView: View {
    let mode: GameMode

    @Environment(\.dismiss) private var dismiss
    @StateObject private var container: GameContainer

    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings.ghostEnabled")   private var ghostEnabled:   Bool = true

    @State private var showSettings: Bool = false
    @State private var scoreScale:   CGFloat = 1.0

    init(mode: GameMode, adventurePreset: [[NeonColor?]]? = nil) {
        self.mode = mode
        _container = StateObject(wrappedValue: GameContainer(adventurePreset: adventurePreset))
    }

    var body: some View {
        ZStack {
            // ── Pure black game canvas (Prompt 4.1) ──────────────────────
            Color.black.ignoresSafeArea()

            // ── SpriteKit board ───────────────────────────────────────────
            SpriteView(
                scene: container.scene,
                options: [.allowsTransparency, .shouldCullNonVisibleNodes]
            )
            .ignoresSafeArea()

            // ── HUD overlay ───────────────────────────────────────────────
            VStack(spacing: 0) {
                gameHUD
                Spacer()
            }

            // ── Game Over overlay ─────────────────────────────────────────
            if container.scoreManager.isGameOver {
                GameOverOverlay(
                    score:     container.scoreManager.score,
                    best:      container.scoreManager.bestScore,
                    playAgain: { container.scene.startNewGame() },
                    goHome:    { dismiss() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            container.scene.updateSettings(
                hapticsEnabled: hapticsEnabled,
                ghostEnabled:   ghostEnabled
            )
        }
        .onChange(of: hapticsEnabled) { _, v in
            container.scene.updateSettings(hapticsEnabled: v, ghostEnabled: ghostEnabled)
        }
        .onChange(of: ghostEnabled) { _, v in
            container.scene.updateSettings(hapticsEnabled: hapticsEnabled, ghostEnabled: v)
        }
        .onChange(of: container.scoreManager.score) { _, _ in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) { scoreScale = 1.12 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) { scoreScale = 1.0 }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onHome:   { dismiss() },
                onReplay: { container.scene.startNewGame() }
            )
            .presentationBackground(.clear)
            .presentationDetents([.large])
        }
        .animation(.easeInOut(duration: 0.18), value: container.scoreManager.isGameOver)
    }

    // MARK: - HUD

    /// Top bar: [Crown + Best Score] (Left) | [Gear] (Right)
    /// Bottom row: [Large Centre Score]
    private var gameHUD: some View {
        VStack(spacing: 16) {
            
            // ── Top Row: High Score & Settings ───────────────────────────
            HStack(alignment: .center) {
                
                // Left: Crown + High Score
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color(red: 0.2, green: 0.35, blue: 0.7)) // Dark blue

                    Text("\(container.scoreManager.bestScore)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.5)) // Pinkish
                        .contentTransition(.numericText())
                }

                Spacer()

                // Right: Settings Gear
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            .padding(.horizontal, 24)

            // ── Bottom Row: Large Current Score ───────────────────────────
            VStack(spacing: 0) {
                NeonScoreLabel(
                    score: container.scoreManager.score,
                    scale: scoreScale
                )

                // Combo badge (shown only during a streak)
                if container.scoreManager.combo > 1 {
                    comboBadge
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.22, dampingFraction: 0.65),
                       value: container.scoreManager.combo)
        }
        .padding(.top, 16)   // reduced from 56 to prevent grid overlap
    }

    // Combo streak badge
    private var comboBadge: some View {
        Text("x\(container.scoreManager.combo) COMBO")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 1, green: 0.95, blue: 0))
            .tracking(3)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(Color.black.opacity(0.55), in: Capsule())
            .overlay(Capsule().stroke(Color(red: 1, green: 0.95, blue: 0).opacity(0.50), lineWidth: 1))
            .shadow(color: Color(red: 1, green: 0.95, blue: 0).opacity(0.45), radius: 6)
            .offset(y: 6)
    }
}

// MARK: - NeonScoreLabel

/// Large centred score with multi-layer neon-pink glow — mirrors image_4.png.
private struct NeonScoreLabel: View {
    let score: Int
    let scale: CGFloat

    var body: some View {
        ZStack {
            // Outer bloom
            Text("\(score)")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0, blue: 1))
                .blur(radius: 22)
                .opacity(0.55)

            // Mid glow
            Text("\(score)")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0, blue: 1))
                .blur(radius: 8)
                .opacity(0.65)

            // Crisp core
            Text("\(score)")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 1, green: 0.55, blue: 1)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 1, green: 0, blue: 1), radius: 8)
                .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.50), radius: 20)
                .contentTransition(.numericText())
        }
        .scaleEffect(scale)
    }
}

// MARK: - GameOverOverlay

private struct GameOverOverlay: View {
    let score:     Int
    let best:      Int
    let playAgain: () -> Void
    let goHome:    () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.60).ignoresSafeArea()

            VStack(spacing: 14) {

                // Title
                VStack(spacing: 4) {
                    Text("GAME OVER")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                        .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.55), radius: 12)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0, green: 1, blue: 1), Color(red: 1, green: 0, blue: 1)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .padding(.horizontal, 30)
                        .opacity(0.55)
                }

                // Score rows
                VStack(spacing: 8) {
                    GameOverScoreRow(
                        icon:  "crown.fill",
                        label: "BEST",
                        value: best,
                        tint:  Color(red: 0, green: 1, blue: 1)
                    )
                    GameOverScoreRow(
                        icon:  "bolt.fill",
                        label: "SCORE",
                        value: score,
                        tint:  Color(red: 1, green: 0, blue: 1)
                    )
                }

                // Buttons
                VStack(spacing: 12) {
                    NeonGameOverButton(
                        title:      "Play Again",
                        systemIcon: "arrow.counterclockwise",
                        accentColor: Color(red: 0.0, green: 0.6, blue: 1.0),
                        glowColor:   Color(red: 0.0, green: 1.0, blue: 1.0)
                    ) {
                        GameStateManager.shared.clearState()
                        playAgain()
                    }

                    NeonGameOverButton(
                        title:      "Watch Ad",
                        systemIcon: "play.rectangle.fill",
                        accentColor: Color(red: 0.0, green: 0.8, blue: 0.4),
                        glowColor:   Color(red: 0.0, green: 1.0, blue: 0.0)
                    ) {
                        // TODO: Implement Watch Ad functionality
                        print("Watch Ad clicked")
                    }

                    NeonGameOverButton(
                        title:      "Main Menu",
                        systemIcon: "house.fill",
                        accentColor: Color(red: 1.0, green: 0.72, blue: 0.0), // Golden Yellow
                        glowColor:   Color(red: 1.0, green: 0.95, blue: 0.0)  // Bright Neon Yellow
                    ) {
                        goHome()
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0x24/255, green: 0x00/255, blue: 0x21/255), // Very Dark Purple (#240021)
                                Color(red: 0x1A/255, green: 0x00/255, blue: 0x18/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1, green: 0, blue: 1).opacity(0.60),
                                        Color(red: 0, green: 1, blue: 1).opacity(0.40)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.25), radius: 30, x: 0, y: 16)
            .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 24)
        }
    }
}

// MARK: - NeonGameOverButton

private struct NeonGameOverButton: View {
    let title:       String
    let systemIcon:  String
    let accentColor: Color
    let glowColor:   Color
    let action:      () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Left icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    Image(systemName: systemIcon)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: glowColor.opacity(0.6), radius: 4)
                }
                .padding(.leading, 12)

                // Label
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(accentColor.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(glowColor.opacity(0.8), lineWidth: 2.5)
            )
            .shadow(color: glowColor.opacity(0.5), radius: 10)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - GameOverScoreRow

private struct GameOverScoreRow: View {
    let icon:  String
    let label: String
    let value: Int
    let tint:  Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: tint.opacity(0.8), radius: 4)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.25), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.4), lineWidth: 1.5)
                )

            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.60))
                .tracking(3)

            Spacer()

            Text("\(value)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    GameView(mode: .classic)
}
