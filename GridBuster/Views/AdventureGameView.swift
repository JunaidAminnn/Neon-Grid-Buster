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
    private let canvasColor = Color(red: 0.07, green: 0.09, blue: 0.20)

    // MARK: - Init

    init(levelID: Int = 1) {
        self.levelID = levelID
        _engine = StateObject(wrappedValue: AdventureGameEngine(levelID: levelID))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────
            canvasColor.ignoresSafeArea()

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
                    goHome:    { dismiss() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .navigationBarHidden(true)
        .onAppear { setupScene() }
        .onChange(of: hapticsEnabled) { _, v in
            scene?.updateSettings(hapticsEnabled: v, ghostEnabled: ghostEnabled)
        }
        .onChange(of: ghostEnabled) { _, v in
            scene?.updateSettings(hapticsEnabled: hapticsEnabled, ghostEnabled: v)
        }
        // Mark level complete in progress manager the moment the win fires.
        // This ensures AdventureMapView's tiger fill is updated whether the
        // player taps Next Level, Play Again, or Main Menu.
        .onChange(of: engine.isLevelWon) { _, won in
            if won {
                AdventureProgressManager.shared.markComplete(levelID: engine.currentLevel.id)
            }
        }
        // Animate gem count bumps on change
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

            // ── Row 1: Back | Level title | Gear ─────────────────────────
            HStack(alignment: .center) {
                // Back button
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.10), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }

                Spacer()

                // Level title
                Text(engine.currentLevel.title.uppercased())
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
                    .tracking(4)

                Spacer()

                // Gear
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.80))
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.10), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)

            // ── Row 2: Target Gem Tracker ─────────────────────────────────
            targetTracker
        }
        .padding(.top, 18)
    }

    // MARK: - Target Tracker

    /// The centrepiece of the Adventure HUD.
    /// Renders one badge per gem type defined in the level's `targets`.
    private var targetTracker: some View {
        let gemOrder: [TargetGem] = TargetGem.allCases.filter {
            engine.currentLevel.targets[$0] != nil
        }

        return HStack(spacing: 24) {
            ForEach(gemOrder, id: \.self) { gem in
                TargetGemBadge(
                    gem:       gem,
                    remaining: engine.remainingTargets[gem] ?? 0,
                    total:     engine.currentLevel.targets[gem] ?? 0,
                    bumpScale: gemBumpScale[gem] ?? 1.0
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Scene Lifecycle

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
        // isLevelWon onChange already called markComplete; no need to repeat.
        let nextID = engine.currentLevel.id + 1
        if AdventureRegistry.level(for: nextID) != nil {
            engine.loadLevel(id: nextID)
            scene?.restartLevel()
        } else {
            // All levels done — return to map so the player sees the full tiger.
            dismiss()
        }
    }
}

// MARK: - TargetGemBadge

/// A single gem counter badge shown in the Target Tracker HUD.
/// Displays the gem icon (coloured + glowing), the count below it,
/// and strikes through / dims when the count reaches 0.
struct TargetGemBadge: View {
    let gem:       TargetGem
    let remaining: Int
    let total:     Int
    let bumpScale: CGFloat

    private var isCleared: Bool { remaining == 0 }
    private var gemSwiftUIColor: Color { Theme.neonColor(gem.neonColor) }

    var body: some View {
        VStack(spacing: 6) {

            // ── Gem icon ────────────────────────────────────────────────
            ZStack {
                // Outer glow bloom
                Circle()
                    .fill(gemSwiftUIColor.opacity(isCleared ? 0.0 : 0.25))
                    .frame(width: 52, height: 52)
                    .blur(radius: 10)

                // Icon container
                ZStack {
                    Circle()
                        .fill(gemSwiftUIColor.opacity(isCleared ? 0.08 : 0.18))
                    Circle()
                        .stroke(gemSwiftUIColor.opacity(isCleared ? 0.18 : 0.65), lineWidth: 2)

                    Image(systemName: gem.systemImage)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(isCleared ? .white.opacity(0.22) : gemSwiftUIColor)
                        .shadow(color: gemSwiftUIColor.opacity(isCleared ? 0 : 0.90), radius: 8)
                }
                .frame(width: 46, height: 46)

                // Tick overlay when cleared
                if isCleared {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white.opacity(0.80))
                        .shadow(color: .white.opacity(0.4), radius: 4)
                }
            }
            .scaleEffect(bumpScale)

            // ── Count ────────────────────────────────────────────────────
            Text("\(remaining)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(isCleared ? .white.opacity(0.30) : gemSwiftUIColor)
                .contentTransition(.numericText())
                .shadow(color: gemSwiftUIColor.opacity(isCleared ? 0 : 0.70), radius: 6)
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

                // ── Trophy / Star ─────────────────────────────────────────
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

                // ── Title ────────────────────────────────────────────────
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

                // ── Score row ─────────────────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 0, green: 1, blue: 1))
                        .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.80), radius: 4)
                        .frame(width: 36, height: 36)
                        .background(Color(red: 0, green: 1, blue: 1).opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 10))

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
                .background(Color.white.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0, green: 1, blue: 1).opacity(0.18), lineWidth: 1))

                // ── Buttons ───────────────────────────────────────────────
                VStack(spacing: 10) {
                    NeonGameOverButton(
                        title:       "Next Level",
                        systemIcon:  "arrow.right",
                        accentColor: Color(red: 0, green: 0.75, blue: 0.35),
                        glowColor:   Color(red: 0, green: 1, blue: 0.4)
                    ) { nextLevel() }

                    NeonGameOverButton(
                        title:       "Play Again",
                        systemIcon:  "arrow.counterclockwise",
                        accentColor: Color(red: 0, green: 0.6, blue: 1.0),
                        glowColor:   Color(red: 0, green: 1, blue: 1)
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
    let score:     Int
    let playAgain: () -> Void
    let goHome:    () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()

            VStack(spacing: 16) {
                // Title
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

                // Score
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 1, green: 0, blue: 0.5))
                        .frame(width: 36, height: 36)
                        .background(Color(red: 1, green: 0, blue: 0.5).opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 10))
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
                .background(Color.white.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 14))

                // Buttons
                VStack(spacing: 10) {
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

// MARK: - Preview

#Preview {
    AdventureGameView(levelID: 1)
}
