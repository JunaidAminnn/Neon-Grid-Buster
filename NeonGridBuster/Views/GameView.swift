//
//  GameView.swift
//  NeonGridBuster
//

import SwiftUI
import SpriteKit
import Combine
import UIKit

enum GameMode: String, Hashable {
    case adventure
    case classic

    var title: String {
        switch self {
        case .adventure: return "Adventure"
        case .classic: return "Classic"
        }
    }
}

@MainActor
final class GameContainer: ObservableObject {
    let scoreManager = ScoreManager()
    let scene: GameScene
    private var cancellable: AnyCancellable?

    init() {
        scene = GameScene(scoreManager: scoreManager)
        cancellable = scoreManager.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

struct GameView: View {
    let mode: GameMode

    @Environment(\.dismiss) private var dismiss
    @StateObject private var container = GameContainer()

    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings.ghostEnabled") private var ghostEnabled: Bool = true

    @State private var showSettings: Bool = false

    var body: some View {
        ZStack {
            NeonBackgroundView()

            SpriteView(
                scene: container.scene,
                options: [.allowsTransparency, .shouldCullNonVisibleNodes]
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    BestScorePill(best: container.scoreManager.bestScore)

                    Spacer(minLength: 0)

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .scaledToFit()
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Theme.Palette.goldDeep)
                            .frame(width: 20, height: 20)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
                            .shadow(color: Theme.Palette.goldDeep.opacity(0.22), radius: 8, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)

                CurrentScoreHeart(score: container.scoreManager.score, combo: container.scoreManager.combo)
                    .padding(.top, -18)

                Spacer()
            }

            if container.scoreManager.isGameOver {
                GameOverOverlay(
                    score: container.scoreManager.score,
                    best: container.scoreManager.bestScore,
                    playAgain: { container.scene.startNewGame() },
                    goHome: { dismiss() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            container.scene.updateSettings(hapticsEnabled: hapticsEnabled, ghostEnabled: ghostEnabled)
        }
        .onChange(of: hapticsEnabled) { _, newValue in
            container.scene.updateSettings(hapticsEnabled: newValue, ghostEnabled: ghostEnabled)
        }
        .onChange(of: ghostEnabled) { _, newValue in
            container.scene.updateSettings(hapticsEnabled: hapticsEnabled, ghostEnabled: newValue)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onHome: { dismiss() },
                onReplay: { container.scene.startNewGame() }
            )
        }
        .animation(.easeInOut(duration: 0.18), value: container.scoreManager.isGameOver)
    }
}

private struct BestScorePill: View {
    let best: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Theme.Palette.goldDeep)
                .frame(width: 20, height: 20)
                .shadow(color: Theme.Palette.goldDeep.opacity(0.20), radius: 10, x: 0, y: 4)

            Text("\(best)")
                .font(Theme.Fonts.arcade(22))
                .foregroundStyle(.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 2)
        }
        .frame(height: 44)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
    }
}

private struct CurrentScoreHeart: View {
    let score: Int
    let combo: Int

    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Palette.neonRed.opacity(0.16))
                .frame(width: 98, height: 98)
                .blur(radius: 18)

            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Theme.Palette.neonRed)
                .frame(width: 110, height: 102)
                .shadow(color: Theme.Palette.neonRed.opacity(0.50), radius: 24, x: 0, y: 10)
                .symbolEffect(.pulse, value: pulse)

            Text("\(score)")
                .font(Theme.Fonts.arcade(40))
                .foregroundStyle(.white.opacity(0.96))
                .contentTransition(.numericText())
                .shadow(color: Color.black.opacity(0.20), radius: 0, x: 0, y: 3)

            if combo > 0 {
                Text("x\(combo)")
                    .font(Theme.Fonts.arcade(18))
                    .foregroundStyle(Theme.Palette.neonYellow.opacity(0.95))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.black.opacity(0.18), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .offset(y: 48)
            }
        }
        .frame(width: 220, height: 140)
        .scaleEffect(pulse ? 1.04 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: pulse)
        .animation(.spring(response: 0.22, dampingFraction: 0.70), value: score)
        .onChange(of: score) { _, _ in
            pulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                pulse = false
            }
        }
    }
}



private struct GameOverOverlay: View {
    let score: Int
    let best: Int
    let playAgain: () -> Void
    let goHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Game Over")
                    .font(Theme.Fonts.arcade(28))
                    .foregroundStyle(.white.opacity(0.96))
                    .shadow(color: Theme.Palette.neonCyan.opacity(0.18), radius: 10, x: 0, y: 6)

                VStack(spacing: 10) {
                    ScoreRow(title: "Best", value: best, icon: "crown.fill", tint: Theme.Palette.goldDeep)
                    ScoreRow(title: "Score", value: score, icon: "heart.fill", tint: Theme.Palette.neonRed)
                }

                VStack(spacing: 10) {
                    Button(action: playAgain) {
                        Text("Play Again")
                            .font(Theme.Fonts.arcade(18))
                            .foregroundStyle(.white.opacity(0.98))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Palette.neonBlue, Theme.Palette.neonCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.Palette.neonCyan.opacity(0.95), lineWidth: 2)
                            )
                            .shadow(color: Theme.Palette.neonCyan.opacity(0.20), radius: 16, x: 0, y: 10)
                    }

                    Button(action: goHome) {
                        Text("Main Menu")
                            .font(Theme.Fonts.arcade(16))
                            .foregroundStyle(.white.opacity(0.95))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Palette.neonPurple.opacity(0.85), Theme.Palette.neonPink.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.Palette.neonPink.opacity(0.75), lineWidth: 1.5)
                            )
                            .shadow(color: Theme.Palette.neonPurple.opacity(0.12), radius: 12, x: 0, y: 8)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: 308)
            .background(
                LinearGradient(
                    colors: [
                        Theme.Palette.arcadeBlueTop.opacity(0.96),
                        Theme.Palette.arcadePanel.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Theme.Palette.neonCyan.opacity(0.38), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 30, x: 0, y: 18)
            .padding(.horizontal, 22)
        }
    }
}

private struct ScoreRow: View {
    let title: String
    let value: Int
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(Theme.Fonts.arcade(14))
                .foregroundStyle(.white.opacity(0.86))

            Spacer()

            Text("\(value)")
                .font(Theme.Fonts.arcade(18))
                .foregroundStyle(.white.opacity(0.96))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    GameView(mode: .classic)
}
