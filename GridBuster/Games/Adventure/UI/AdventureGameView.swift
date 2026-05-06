//
//  AdventureGameView.swift
//  NeonGridBuster
//
//  Prompt 2 — Adventure Gameplay UI & Target Collection Logic
//  ─────────────────────────────────────────────────────────────────────────
//  Layout (top → bottom, dark blue-purple game canvas):
//    [ Back arrow ]    [ TARGET HUD — gem icons + counts ] [ Settings gear ]
//    SpriteKit game board  ←  adventure-aware AdventureGameScene
//  ─────────────────────────────────────────────────────────────────────────
//

import SwiftUI
import SpriteKit
import Combine

// MARK: - AdventureGameView

struct AdventureGameView: View {

    // ── Inputs ────────────────────────────────────────────────────────────
    let levelID: Int

    @Environment(\.dismiss) private var dismiss

    // ── Engine ────────────────────────────────────────────────────────────
    @StateObject private var engine: AdventureGameEngine

    // ── Scene ─────────────────────────────────────────────────────────────
    @State private var scene: AdventureGameScene?

    // ── Settings stored prefs ─────────────────────────────────────────────
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings.ghostEnabled")   private var ghostEnabled:   Bool = true

    // ── UI state ─────────────────────────────────────────────────────────
    @State private var showSettings:  Bool = false
    @State private var gemBumpScale:  [TargetGem: CGFloat] = [:]

    // ── Colours (Adventure skin – warm dark blue, not pitch black) ────────
    private let canvasColor = Color(red: 0x0B / 255, green: 0x0C / 255, blue: 0x10 / 255)

    // MARK: - Init

    init(levelID: Int = 1) {
        self.levelID = levelID
        _engine = StateObject(wrappedValue: AdventureGameEngine(levelID: levelID))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // ── Background ──────────────────────────────────────────────
                ArcadeBlueBackgroundView()

                // ── SpriteKit Scene ─────────────────────────────────────────
                if let scene {
                    SpriteView(
                        scene: scene,
                        options: [.allowsTransparency, .shouldCullNonVisibleNodes]
                    )
                    .ignoresSafeArea()
                }

                // ── HUD overlay ─────────────────────────────────────────────
                VStack(spacing: 0) {
                    adventureHUD
                    Spacer()
                }

                // ── Level Won overlay ────────────────────────────────────────
                if engine.isLevelWon {
                    LevelWonOverlay(
                        levelID:    engine.currentLevel.id,
                        score:      engine.score,
                        playAgain:  { restartLevel() },
                        nextLevel:  { loadNextLevel() },
                        goHome:     { dismiss() }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }

                // ── Game Over overlay ────────────────────────────────────────
                if engine.isGameOver && !engine.isLevelWon {
                    AdventureGameOverOverlay(
                        score:     engine.score,
                        playAgain: { restartLevel() },
                        continueGame: { engine.continueAfterAd() },
                        goHome:    { dismiss() }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .padding(.top, 10)
            
            // ── Banner Ad at bottom ──────────────────────────────────────
            BannerAdView()
                .padding(.bottom, 4)
        }
        .navigationBarHidden(true)
        .onAppear { setupScene() }
        .onChange(of: hapticsEnabled) { _, v in
            scene?.updateSettings(hapticsEnabled: v, ghostEnabled: ghostEnabled)
        }
        .onChange(of: ghostEnabled) { _, v in
            scene?.updateSettings(hapticsEnabled: hapticsEnabled, ghostEnabled: v)
        }
        .onChange(of: engine.isLevelWon) { _, won in
            if won {
                AdventureProgressManager.shared.markComplete(levelID: engine.currentLevel.id)
            }
        }
        .onChange(of: engine.remainingTargets) { _, newTargets in
            for gem in TargetGem.allCases {
                withAnimation(.spring(response: 0.20, dampingFraction: 0.50)) {
                    gemBumpScale[gem] = 1.22
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                        gemBumpScale[gem] = 1.0
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                onHome:   { dismiss() },
                onReplay: { restartLevel() }
            )
            .presentationBackground(.clear)
            .presentationDetents([.large])
        }
        .animation(.easeInOut(duration: 0.22), value: engine.isLevelWon)
        .animation(.easeInOut(duration: 0.22), value: engine.isGameOver)
    }

    // MARK: - Adventure HUD

    private var adventureHUD: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 0) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .contentShape(Rectangle())
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }
                Spacer()
                Spacer()
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .contentShape(Rectangle())
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }
            }
            .padding(.top, 8)
            targetTracker
        }
        .padding(.top, -10)
    }

    private var targetTracker: some View {
        let gemOrder: [TargetGem] = TargetGem.allCases.filter {
            engine.currentLevel.targets[$0] != nil
        }

        return HStack(spacing: 42) {
            ForEach(gemOrder, id: \.self) { gem in
                TargetGemBadge(
                    gem:       gem,
                    remaining: engine.remainingTargets[gem] ?? 0,
                    total:     engine.currentLevel.targets[gem] ?? 0,
                    bumpScale: gemBumpScale[gem] ?? 1.0
                )
            }
        }
        .padding(.top, 2)
        .padding(.horizontal, 20)
    }

    private func setupScene() {
        let s = AdventureGameScene(engine: engine)
        s.updateSettings(hapticsEnabled: hapticsEnabled, ghostEnabled: ghostEnabled)
        scene = s
        engine.startLevel()
    }

    private func restartLevel() {
        engine.restartLevel()
        scene?.restartLevel()
    }

    private func loadNextLevel() {
        let nextID = engine.currentLevel.id + 1
        if AdventureRegistry.level(for: nextID) != nil {
            engine.loadLevel(id: nextID)
            scene?.restartLevel()
        } else {
            dismiss()
        }
    }
}

// MARK: - TargetGemBadge

struct TargetGemBadge: View {
    let gem:       TargetGem
    let remaining: Int
    let total:     Int
    let bumpScale: CGFloat

    private var isCleared: Bool { remaining == 0 }
    private var gemSwiftUIColor: Color { Theme.neonColor(gem.neonColor) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                GemIconView(gem: gem, size: 40, isCleared: isCleared)
                    .scaleEffect(bumpScale)
                
                if isCleared {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Color(red: 0, green: 1, blue: 0.5))
                        .shadow(color: Color(red: 0, green: 1, blue: 0.5).opacity(0.8), radius: 6)
                }
            }
            .frame(width: 44, height: 44)

            Text("\(remaining)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(isCleared ? .white.opacity(0.20) : .white)
                .contentTransition(.numericText())
                .shadow(color: gemSwiftUIColor.opacity(isCleared ? 0 : 0.80), radius: 8)
        }
    }
}

// MARK: - LevelWonOverlay

private struct LevelWonOverlay: View {
    let levelID:   Int
    let score:     Int
    let playAgain: () -> Void
    let nextLevel: () -> Void
    let goHome:    () -> Void

    @State private var starScale: CGFloat = 0.4
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1, green: 0.85, blue: 0).opacity(glowPulse ? 0.28 : 0.14))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                    Image(systemName: "star.fill")
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.95, blue: 0.2),
                                         Color(red: 1, green: 0.65, blue: 0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 1, green: 0.85, blue: 0).opacity(0.90), radius: 20)
                        .scaleEffect(starScale)
                }
                VStack(spacing: 4) {
                    Text("LEVEL COMPLETE!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                        .shadow(color: Color(red: 1, green: 0.85, blue: 0).opacity(0.55), radius: 10)
                        .tracking(2)
                    Text("Level \(levelID) cleared")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.40))
                }
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.40), radius: 4)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    Text("SCORE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.50))
                        .tracking(3)
                    Spacer()
                    Text("\(score)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0, green: 1, blue: 1).opacity(0.18), lineWidth: 1))
                VStack(spacing: 12) {
                    NeonGameOverButton(
                        title:       "Next Level",
                        systemIcon:  "arrow.right",
                        accentColor: Theme.Palette.neonLime.opacity(0.75),
                        glowColor:   Theme.Palette.neonLime
                    ) { nextLevel() }
                    NeonGameOverButton(
                        title:       "Main Menu",
                        systemIcon:  "house.fill",
                        accentColor: Theme.Palette.neonBlue.opacity(0.70),
                        glowColor:   Theme.Palette.neonBlue
                    ) { goHome() }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
            .frame(maxWidth: 340)
            .background(Theme.Palette.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 0.85, blue: 0).opacity(0.65),
                                Color(red: 1, green: 0.40, blue: 0).opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            )
            .shadow(color: Color(red: 1, green: 0.85, blue: 0).opacity(0.25), radius: 28, x: 0, y: 14)
            .shadow(color: .black.opacity(0.60), radius: 42, x: 0, y: 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { starScale = 1.0 }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - AdventureGameOverOverlay

private struct AdventureGameOverOverlay: View {
    let score:        Int
    let playAgain:    () -> Void
    let continueGame: () -> Void
    let goHome:       () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("NO MOVES LEFT")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                        .shadow(color: Color(red: 1, green: 0, blue: 0.5).opacity(0.65), radius: 10)
                        .tracking(2)
                    Text("The grid is blocked")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0, blue: 0.5), Color(red: 1, green: 0.5, blue: 0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .padding(.horizontal, 20)
                        .opacity(0.50)
                }
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 1, green: 0, blue: 0.5))
                        .frame(width: 36, height: 36)
                        .background(Color(red: 1, green: 0, blue: 0.5).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    Text("SCORE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.50))
                        .tracking(3)
                    Spacer()
                    Text("\(score)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                VStack(spacing: 10) {
                    NeonGameOverButton(
                        title:       "Watch Ad",
                        systemIcon:  "play.rectangle.fill",
                        accentColor: Color(red: 0, green: 0.8, blue: 0.4),
                        glowColor:   Color(red: 0, green: 1, blue: 0)
                    ) {
                        AdsManager.shared.showRewardedAd { earned in
                            if earned { continueGame() }
                        }
                    }
                    NeonGameOverButton(
                        title:       "Try Again",
                        systemIcon:  "arrow.counterclockwise",
                        accentColor: Color(red: 0, green: 0.60, blue: 1.0),
                        glowColor:   Color(red: 0, green: 1.00, blue: 1.0)
                    ) { playAgain() }
                    NeonGameOverButton(
                        title:       "Main Menu",
                        systemIcon:  "house.fill",
                        accentColor: Color(red: 1.0, green: 0.72, blue: 0.0),
                        glowColor:   Color(red: 1.0, green: 0.95, blue: 0.0)
                    ) { goHome() }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: 340)
            .background(Theme.Palette.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 0, blue: 0.5).opacity(0.60),
                                Color(red: 1, green: 0, blue: 1).opacity(0.40)
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            )
            .shadow(color: Color(red: 1, green: 0, blue: 0.5).opacity(0.25), radius: 28)
        }
    }
}
