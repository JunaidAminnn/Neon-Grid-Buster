//
//  AdventureMapView.swift
//  NeonGridBuster
//
//  Prompt 5.1 — Adventure Map (clone of image_3.png structure).
//  • Deep neon gradient background
//  • Grid-square pixel-art neon magenta tiger head (silhouette of grid squares)
//  • Glowing green "LEVEL 1" button → loads GameView with preset puzzle
//  • Back arrow → returns to Main Menu
//

import SwiftUI

// MARK: - Level Definitions

enum AdventureLevel: Int, CaseIterable {
    case level1 = 1

    var title: String { "LEVEL \(rawValue)" }

    /// Pre-filled grid: 8×8 of optional NeonColor (nil = empty cell).
    /// Level 1 — "Neon Claw": two diagonal claw-slash patterns the player
    /// must fill and complete to clear lines.
    var preset: [[NeonColor?]] {
        var g: [[NeonColor?]] = Array(
            repeating: Array(repeating: nil, count: 8),
            count: 8
        )
        switch self {
        case .level1:
            // Left claw — cyan diagonal from top-left
            let cyanCells = [(0,0),(1,1),(2,2),(3,3),(4,3),(5,2),(6,1),(7,0)]
            for (r,c) in cyanCells { g[r][c] = .cyan }
            // Right claw — pink diagonal from top-right
            let pinkCells = [(0,7),(1,6),(2,5),(3,4),(4,4),(5,5),(6,6),(7,7)]
            for (r,c) in pinkCells { g[r][c] = .pink }
            // Spine — purple vertical centre-left fill
            for r in 0..<4 { g[r][1] = .purple }
            for r in 0..<4 { g[r][6] = .purple }
        }
        return g
    }
}

// MARK: - AdventureMapView

struct AdventureMapView: View {

    @Environment(\.dismiss) private var dismiss

    // Pixel-art tiger head: 1 = filled magenta, 0 = empty (11 × 11 grid)
    private let tigerPixels: [[Int]] = [
        [0,0,1,0,0,0,0,0,1,0,0],  // ear tips
        [0,1,1,1,0,0,0,1,1,1,0],  // ears
        [0,1,1,1,1,1,1,1,1,1,0],  // crown
        [1,1,1,1,1,1,1,1,1,1,1],  // forehead
        [1,1,0,0,1,1,1,0,0,1,1],  // eye sockets
        [1,1,1,1,1,1,1,1,1,1,1],  // nose bridge
        [1,1,1,0,1,1,1,0,1,1,1],  // nostrils
        [1,1,1,1,1,1,1,1,1,1,1],  // muzzle
        [0,1,0,1,1,0,1,1,0,1,0],  // whisker dots / stripes
        [0,0,1,1,1,1,1,1,1,0,0],  // lower chin
        [0,0,0,0,1,1,1,0,0,0,0],  // jaw / neck
    ]

    @State private var glowPulse     = false
    @State private var buttonPressed = false
    @State private var navigateToGame = false

    var body: some View {
        NavigationStack {
            ZStack {
                adventureBackground

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    tigerArtSection
                    Spacer(minLength: 24)
                    levelButton
                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
            .onAppear { withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glowPulse = true } }
            .navigationDestination(isPresented: $navigateToGame) {
                GameView(mode: .adventure, adventurePreset: AdventureLevel.level1.preset)
            }
        }
    }

    // MARK: - Background

    private var adventureBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0x0D/255, green: 0x01/255, blue: 0x2B/255),
                    Color(red: 0x06/255, green: 0x00/255, blue: 0x14/255),
                    Color(red: 0x00/255, green: 0x01/255, blue: 0x05/255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Magenta ambient bloom behind tiger
            RadialGradient(
                colors: [Color(red: 1, green: 0, blue: 1).opacity(0.18), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 260
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .black))
                    Text("MENU")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(3)
                }
                .foregroundStyle(Color(red: 0, green: 1, blue: 1))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0, green: 1, blue: 1).opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.25), radius: 8)
            }

            Spacer()

            Text("ADVENTURE")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.30))
                .tracking(5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 58)
    }

    // MARK: - Tiger Pixel Art

    private var tigerArtSection: some View {
        VStack(spacing: 16) {
            // Section label
            Text("TIGER MODE")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0, blue: 1).opacity(0.70))
                .tracking(6)

            // Pixel tiger
            ZStack {
                // Ambient glow behind the tiger
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 1, green: 0, blue: 1).opacity(glowPulse ? 0.14 : 0.08))
                    .frame(width: 220, height: 220)
                    .blur(radius: 30)

                // Grid-background panel
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 1, green: 0, blue: 1).opacity(0.22), lineWidth: 1)
                    )
                    .frame(width: 210, height: 210)

                TigerPixelView(pixels: tigerPixels, cellSize: 17)
            }

            // Subtitle
            Text("LEVEL SELECT")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.20))
                .tracking(6)
        }
    }

    // MARK: - Level Button

    private var levelButton: some View {
        Button {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.65)) { buttonPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation { buttonPressed = false }
                navigateToGame = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .black))
                Text("LEVEL  1")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.95, blue: 0.30),
                        Color(red: 0.00, green: 0.75, blue: 0.20),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                // Bevel highlight on top half
                LinearGradient(
                    colors: [Color.white.opacity(0.26), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 0, green: 1, blue: 0.4).opacity(0.80), lineWidth: 1.5)
            )
            // Multi-layer neon green glow
            .shadow(color: Color(red: 0, green: 1, blue: 0).opacity(glowPulse ? 0.70 : 0.40), radius: glowPulse ? 22 : 14, x: 0, y: 6)
            .shadow(color: Color(red: 0, green: 1, blue: 0).opacity(0.25), radius: 40, x: 0, y: 12)
            .scaleEffect(buttonPressed ? 0.96 : 1.0)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - TigerPixelView

/// Renders the pixel-art tiger head as a grid of neon magenta squares.
private struct TigerPixelView: View {
    let pixels:   [[Int]]
    let cellSize: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<pixels.count, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<pixels[row].count, id: \.self) { col in
                        if pixels[row][col] == 1 {
                            RoundedRectangle(cornerRadius: cellSize * 0.18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.55, blue: 1.0),  // top-left highlight
                                            Color(red: 1.0, green: 0.00, blue: 1.0),  // #FF00FF magenta
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: cellSize, height: cellSize)
                                .shadow(
                                    color: Color(red: 1, green: 0, blue: 1).opacity(0.60),
                                    radius: 5
                                )
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AdventureMapView()
}
