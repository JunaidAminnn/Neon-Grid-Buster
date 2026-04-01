//
//  AdventureMapView.swift
//  NeonGridBuster
//
//  Prompt 3 — Adventure Map & Level Progression
//  ─────────────────────────────────────────────────────────────────────────
//  Visual map / level-select screen.
//
//  Layout (top → bottom):
//    Dark blue-to-purple gradient background
//    ← MENU  (back)          ADVENTURE (label)
//    Trophy icon
//    "Keep Winning!" / "Take part in the Adventure" headline
//    Tiger Head pixel grid — squares fill neon magenta from bottom as
//      levels are completed (progress-driven fill animation)
//    "LEVEL  X" glowing green button → AdventureGameView
//

import SwiftUI

// MARK: - AdventureMapView

struct AdventureMapView: View {

    @Environment(\.dismiss) private var dismiss

    // ── Progress ──────────────────────────────────────────────────────────
    @StateObject private var progress = AdventureProgressManager.shared

    // ── Navigation ────────────────────────────────────────────────────────
    @State private var navigateToGame = false

    // ── Animation ────────────────────────────────────────────────────────
    /// Animated lit-pixel count — drives the fill animation separately
    /// from the raw `progress.litPixelCount` so we can sequence it.
    @State private var animatedLitCount: Int = 0
    @State private var glowPulse        = false
    @State private var buttonPressed    = false
    @State private var trophyScale: CGFloat = 0.80

    // ── Tiger pixel map (11 × 11) — must match AdventureProgressManager ──
    private let tigerPixels = AdventureProgressManager.tigerPixels

    // ── Layout ────────────────────────────────────────────────────────────
    private let cellSize:  CGFloat = 19
    private let cellGap:   CGFloat = 3

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                adventureBackground

                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 10)
                    trophySection
                    Spacer(minLength: 14)
                    tigerGridSection
                    Spacer(minLength: 20)
                    levelButton
                    Spacer(minLength: 44)
                }
            }
            .navigationBarHidden(true)
            // ── On appear: snap animatedLitCount to current (no animation) ──
            .onAppear {
                animatedLitCount = progress.litPixelCount
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.60)) {
                    trophyScale = 1.0
                }
            }
            // ── When progress changes (level cleared and back to map) ──────
            .onChange(of: progress.litPixelCount) { _, newCount in
                animateFill(to: newCount)
            }
            // ── Navigate to gameplay ──────────────────────────────────────
            .navigationDestination(isPresented: $navigateToGame) {
                AdventureGameView(levelID: progress.nextLevelID)
            }
        }
    }

    // MARK: - Background

    private var adventureBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.02, blue: 0.16),
                    Color(red: 0.04, green: 0.01, blue: 0.10),
                    Color(red: 0.02, green: 0.01, blue: 0.05),
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
            // Ambient magenta bloom
            RadialGradient(
                colors: [Color(red: 1, green: 0, blue: 1).opacity(0.16), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 10) {
                    // Inset neon ring for icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 34, height: 34)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                    }
                    
                    Text("MENU")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .tracking(3)
                }
                .padding(.leading, 8)
                .padding(.trailing, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0, green: 1, blue: 1), lineWidth: 2.5)
                )
                .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.50), radius: 12)
            }

            Spacer()

            Text("ADVENTURE")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.40))
                .tracking(6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 38)
    }

    // MARK: - Trophy Section

    private var trophySection: some View {
        VStack(spacing: 12) {
            // ── Trophy icon ───────────────────────────────────────────────
            ZStack {
                // Glow bloom
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1, green: 0.85, blue: 0).opacity(glowPulse ? 0.30 : 0.14),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: progress.anyCompleted ? "trophy.fill" : "trophy")
                    .font(.system(size: progress.anyCompleted ? 48 : 44, weight: .black))
                    .foregroundStyle(
                        progress.anyCompleted
                        ? LinearGradient(
                            colors: [Color(red: 1, green: 0.95, blue: 0.2),
                                     Color(red: 1, green: 0.65, blue: 0)],
                            startPoint: .top, endPoint: .bottom
                          )
                        : LinearGradient(
                            colors: [.white.opacity(0.50), .white.opacity(0.22)],
                            startPoint: .top, endPoint: .bottom
                          )
                    )
                    .shadow(
                        color: progress.anyCompleted
                            ? Color(red: 1, green: 0.85, blue: 0).opacity(glowPulse ? 0.80 : 0.40)
                            : Color.white.opacity(0.10),
                        radius: progress.anyCompleted ? 18 : 4
                    )
            }
            .scaleEffect(trophyScale)

            // ── Headline ──────────────────────────────────────────────────
            if progress.anyCompleted {
                keepWinningLabel
            } else {
                joinAdventureLabel
            }
        }
    }

    private var keepWinningLabel: some View {
        HStack(spacing: 0) {
            // "Keep " in white with shadow
            Text("Keep ")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.80), radius: 12)

            // "Winning!" in neon pink
            Text("Winning!")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0.30, blue: 0.85))
                .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.70), radius: 10)
        }
    }

    private var joinAdventureLabel: some View {
        VStack(spacing: 6) {
            Text("Take part in the Adventure")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
                .multilineTextAlignment(.center)
            Text("and win the trophy.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    // MARK: - Tiger Grid Section

    private var tigerGridSection: some View {
        VStack(spacing: 0) {
            // Ambient glow behind the tiger
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 1, green: 0, blue: 1).opacity(glowPulse ? 0.12 : 0.06))
                    .frame(
                        width: CGFloat(11) * (cellSize + cellGap) + 40,
                        height: CGFloat(11) * (cellSize + cellGap) + 40
                    )
                    .blur(radius: 26)

                // Grid panel
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color(red: 1, green: 0, blue: 1).opacity(0.18), lineWidth: 1)
                    )
                    .frame(
                        width:  CGFloat(11) * (cellSize + cellGap) + 28,
                        height: CGFloat(11) * (cellSize + cellGap) + 28
                    )

                // Tiger grid
                tigerGrid
            }
        }
    }

    private var tigerGrid: some View {
        VStack(spacing: cellGap) {
            ForEach(0..<tigerPixels.count, id: \.self) { row in
                HStack(spacing: cellGap) {
                    ForEach(0..<tigerPixels[row].count, id: \.self) { col in
                        if tigerPixels[row][col] == 1 {
                            tigerCell(row: row, col: col)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    /// Single cell inside the tiger silhouette — either dim (unlit) or glowing magenta (lit).
    private func tigerCell(row: Int, col: Int) -> some View {
        let isLit = isPixelLit(row: row, col: col)

        return ZStack {
            if isLit {
                // ── Lit: glowing magenta ──────────────────────────────────
                RoundedRectangle(cornerRadius: cellSize * 0.22)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.50, blue: 1.0),
                                Color(red: 1.0, green: 0.00, blue: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        )
                    )
                    .frame(width: cellSize, height: cellSize)
                    .shadow(
                        color: Color(red: 1, green: 0, blue: 1).opacity(glowPulse ? 0.85 : 0.55),
                        radius: glowPulse ? 7 : 4
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cellSize * 0.22)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.clear],
                                    startPoint: .topLeading, endPoint: .center
                                )
                            )
                    )
            } else {
                // ── Dim: unfilled silhouette cell ─────────────────────────
                RoundedRectangle(cornerRadius: cellSize * 0.22)
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.28))
                    .frame(width: cellSize, height: cellSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: cellSize * 0.22)
                            .stroke(Color(red: 0.35, green: 0.38, blue: 0.65).opacity(0.60),
                                    lineWidth: 1.0)
                    )
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.62), value: isLit)
    }

    /// Returns true when this tiger pixel should currently be rendered as lit,
    /// based on the animated counter (not the raw progress value directly).
    private func isPixelLit(row: Int, col: Int) -> Bool {
        guard let idx = AdventureProgressManager.tigerPositionsSorted.firstIndex(
            where: { $0.row == row && $0.col == col }
        ) else { return false }
        return idx < animatedLitCount
    }

    // MARK: - Level Button

    private var levelButton: some View {
        Button {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.65)) {
                buttonPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation { buttonPressed = false }
                navigateToGame = true
            }
        } label: {
            HStack(spacing: 0) {
                // Inset neon ring for icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                        )
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 12)
                
                Text(levelButtonTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(6)
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 1, green: 0, blue: 0.8).opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(red: 1, green: 0, blue: 0.8), lineWidth: 3.5)
            )
            .shadow(color: Color(red: 1, green: 0, blue: 0.8).opacity(glowPulse ? 0.75 : 0.45),
                    radius: glowPulse ? 22 : 14)
            .scaleEffect(buttonPressed ? 0.94 : 1.0)
        }
        .padding(.horizontal, 30)
    }

    private var levelButtonTitle: String {
        if progress.allLevelsComplete {
            return "LEVEL  \(AdventureRegistry.all.last?.id ?? 1)"
        }
        return "LEVEL  \(progress.nextLevelID)"
    }

    // MARK: - Fill Animation

    /// Cascades `animatedLitCount` up to `newCount` one pixel at a time,
    /// with a tiny stagger so the squares pop in sequentially (bottom → top).
    private func animateFill(to newCount: Int) {
        let current = animatedLitCount
        guard newCount > current else {
            animatedLitCount = newCount   // immediate reset (if progress was cleared)
            return
        }
        for step in current..<newCount {
            let delay = Double(step - current) * 0.035
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.60)) {
                    animatedLitCount = step + 1
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AdventureMapView()
}
