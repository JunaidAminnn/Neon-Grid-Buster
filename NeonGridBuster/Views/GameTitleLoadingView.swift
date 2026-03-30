//
//  GameTitleLoadingView.swift
//  NeonGridBuster
//
//  Game title / loading screen (Prompt 1.2).
//  Loads game data (RNG weights, settings) then transitions to MainMenuView.
//

import SwiftUI
import Combine

// MARK: - GameTitleLoadingView

struct GameTitleLoadingView: View {

    // ── State ────────────────────────────────────────────────────────────
    @State private var navigateToMenu   = false
    @Namespace private var logoNamespace


    // logo entrance
    @State private var topWordVisible   = false
    @State private var bottomWordVisible = false
    @State private var subtextVisible   = false
    @State private var buttonIconVisible = false

    // ambient pulse
    @State private var glowPulse        = false

    // loading bar
    @State private var loadProgress: CGFloat = 0.0
    @State private var loadDone         = false

    // block cluster bounce
    @State private var clusterBounce    = false
    @State private var clusterGlow      = false

    // ── Body ─────────────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            if navigateToMenu {
                MainMenuView(namespace: logoNamespace)
                    .transition(.opacity)
            } else {
                titleScreen
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: navigateToMenu)
    }

    // MARK: - Title Screen

    private var titleScreen: some View {
        ZStack {
            // ── Gradient background (same as splash) ──────────────────
            LinearGradient(
                colors: [
                    Color(red: 0x0D, green: 0x01, blue: 0x2B),
                    Color(red: 0x06, green: 0x00, blue: 0x12),
                    Color(red: 0x00, green: 0x01, blue: 0x05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient radial glows
            ambientGlows

            // ── Content ───────────────────────────────────────────────
            GeometryReader { geo in
                VStack(spacing: 0) {

                    Spacer(minLength: geo.size.height * 0.12)

                    // Logo Group for matched geometry transition
                    VStack(spacing: 0) {
                        // Arcade-button crown icon
                        ArcadeButtonIcon()
                            .opacity(buttonIconVisible ? 1 : 0)
                            .scaleEffect(buttonIconVisible ? 1 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1), value: buttonIconVisible)
                            .padding(.bottom, 18)

                        // "NEON GRID" — cyan neon
                        NeonTitleWord(
                            text: "NEON GRID",
                            color: Color(red: 0, green: 1, blue: 1),   // #00FFFF
                            fontSize: 44
                        )
                        .opacity(topWordVisible ? 1 : 0)
                        .offset(y: topWordVisible ? 0 : -30)
                        .animation(.spring(response: 0.75, dampingFraction: 0.72).delay(0.2), value: topWordVisible)

                        // "BUSTER" — hot-pink neon
                        NeonTitleWord(
                            text: "BUSTER",
                            color: Color(red: 1, green: 0, blue: 1),   // #FF00FF
                            fontSize: 56
                        )
                        .opacity(bottomWordVisible ? 1 : 0)
                        .offset(y: bottomWordVisible ? 0 : 30)
                        .animation(.spring(response: 0.75, dampingFraction: 0.72).delay(0.35), value: bottomWordVisible)

                        // "GRID MASTER" subtext
                        Text("GRID MASTER")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                            .tracking(9)
                            .padding(.top, 10)
                            .opacity(subtextVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.55), value: subtextVisible)
                    }
                    .matchedGeometryEffect(id: "mainLogo", in: logoNamespace)

                    Spacer(minLength: 0)

                    // ── Loading section ───────────────────────────────
                    VStack(spacing: 20) {

                        // Animated block cluster with pulsing shape and rotation
                        AnimatedBlockCluster(bounce: clusterBounce, glow: clusterGlow)

                        // Loading bar
                        LoadingBar(progress: loadProgress)

                        // Status label
                        Text(loadDone ? "READY" : "LOADING...")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                loadDone
                                    ? Color(red: 0, green: 1, blue: 1)
                                    : Color.white.opacity(0.45)
                            )
                            .tracking(5)
                            .animation(.easeOut(duration: 0.3), value: loadDone)
                    }
                    .padding(.bottom, geo.size.height * 0.10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            startEntranceAnimations()
            startLoadingSequence()
        }
    }

    // MARK: - Ambient Glows

    private var ambientGlows: some View {
        ZStack {
            // Cyan top-left bloom
            RadialGradient(
                colors: [Color(red: 0, green: 1, blue: 1).opacity(glowPulse ? 0.18 : 0.08), .clear],
                center: .topLeading, startRadius: 0, endRadius: 400
            )
            .blendMode(.plusLighter)

            // Pink top-right bloom
            RadialGradient(
                colors: [Color(red: 1, green: 0, blue: 1).opacity(glowPulse ? 0.15 : 0.07), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 400
            )
            .blendMode(.plusLighter)

            // Cyan bottom bloom
            RadialGradient(
                colors: [Color(red: 0, green: 1, blue: 1).opacity(glowPulse ? 0.10 : 0.04), .clear],
                center: .bottom, startRadius: 0, endRadius: 320
            )
            .blendMode(.plusLighter)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)
        .onAppear { glowPulse = true }
    }

    // MARK: - Animations

    private func startEntranceAnimations() {
        buttonIconVisible  = true
        topWordVisible     = true
        bottomWordVisible  = true
        subtextVisible     = true
        clusterBounce      = true
        clusterGlow        = true
    }

    // MARK: - Loading Sequence

    private func startLoadingSequence() {
        /// Simulates loading RNG weights + settings data.
        /// Fills the bar in stages, then navigates to menu.
        let steps: [(delay: Double, value: CGFloat)] = [
            (0.3,  0.20),   // parse settings
            (0.7,  0.45),   // load RNG weights
            (1.1,  0.68),   // validate grid config
            (1.5,  0.88),   // finalise state
            (1.85, 1.00)    // done
        ]

        for step in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    loadProgress = step.value
                }
            }
        }

        // Mark done & navigate
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            loadDone = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.85) {
            navigateToMenu = true
        }
    }
}

// MARK: - NeonTitleWord

/// Single neon-glowing title word with layered blur glow.
private struct NeonTitleWord: View {
    let text: String
    let color: Color
    let fontSize: CGFloat

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outermost bloom
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .blur(radius: 32)
                .opacity(pulse ? 0.80 : 0.45)

            // Mid glow
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .blur(radius: 14)
                .opacity(0.65)

            // Tight inner glow
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color.opacity(0.55))
                .blur(radius: 4)

            // Crisp core (solid white to prevent bottom cut-off)
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: color, radius: 10, x: 0, y: 0)
                .shadow(color: color.opacity(0.6), radius: 24, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - ArcadeButtonIcon

/// Crown-position icon: a glowing neon arcade button (concentric circles).
private struct ArcadeButtonIcon: View {
    @State private var halo = false

    var body: some View {
        ZStack {
            // Outer halo glow
            Circle()
                .fill(Color(red: 1, green: 0.75, blue: 0).opacity(halo ? 0.25 : 0.10))
                .frame(width: 88, height: 88)
                .blur(radius: 18)

            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.88, blue: 0), Color(red: 1, green: 0.55, blue: 0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 62, height: 62)
                .shadow(color: Color(red: 1, green: 0.75, blue: 0).opacity(0.85), radius: 8, x: 0, y: 0)

            // Inner filled cap
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1, green: 0.95, blue: 0.3),
                            Color(red: 1, green: 0.65, blue: 0.0)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 24
                    )
                )
                .frame(width: 44, height: 44)
                .shadow(color: Color(red: 1, green: 0.75, blue: 0), radius: 12, x: 0, y: 0)

            // Arcade cross / highlight
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white.opacity(0.80))
                .offset(y: -1)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                halo = true
            }
        }
    }
}

// MARK: - AnimatedBlockCluster

/// Small animated block cluster with pulsing neon glow, cycling shapes and rotating.
private struct AnimatedBlockCluster: View {
    let bounce: Bool
    let glow: Bool

    // A collection of classic tetris/block puzzle shapes
    private let shapes: [[(col: Int, row: Int)]] = [
        [(0,0), (1,0), (0,1), (0,2), (1,2)], // L-shape
        [(0,0), (1,0), (0,1), (1,1)],        // Square
        [(0,0), (1,0), (2,0), (3,0)],        // Line
        [(1,0), (0,1), (1,1), (2,1)],        // T-shape
        [(0,0), (1,0), (1,1), (2,1)],        // Z-shape
        [(0,0), (1,0), (2,0), (0,1), (0,2)]  // Big corner
    ]

    // Associated neon colors
    private let colors: [Color] = [
        Color(red: 1, green: 0.92, blue: 0.0), // Yellow
        Color(red: 0, green: 1.0, blue: 1.0),  // Cyan
        Color(red: 1.0, green: 0.0, blue: 1.0),// Magenta
        Color(red: 0.0, green: 1.0, blue: 0.0),// Green
        Color(red: 1.0, green: 0.5, blue: 0.0),// Orange
        Color(red: 1.0, green: 0.0, blue: 0.0) // Red
    ]

    @State private var shapeIndex = 0
    @State private var rotation: Double = 0

    // Timer to cycle shapes and rotation
    let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        let currentShape = shapes[shapeIndex % shapes.count]
        let currentColor = colors[shapeIndex % colors.count]

        ZStack {
            // Glow halo
            Rectangle()
                .fill(currentColor.opacity(glow ? 0.35 : 0.15))
                .frame(width: 56, height: 56)
                .blur(radius: 18)

            // Block grid canvas
            Canvas { ctx, _ in
                let s: CGFloat = 16   // cell size
                let gap: CGFloat = 2  // gap between cells

                for cell in currentShape {
                    let x = CGFloat(cell.col) * (s + gap)
                    let y = CGFloat(cell.row) * (s + gap)
                    let rect = CGRect(x: x, y: y, width: s, height: s)
                    let path = Path(roundedRect: rect, cornerRadius: 3)
                    ctx.fill(path, with: .color(currentColor))
                }
            }
            .frame(width: 56, height: 56) // Stable frame to center rotation nicely
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(bounce ? 1.0 : 0.88)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: shapeIndex)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bounce)
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                shapeIndex += 1
                rotation += 90
            }
        }
    }
}

// MARK: - LoadingBar

/// Neon loading progress bar.
private struct LoadingBar: View {
    let progress: CGFloat   // 0.0 – 1.0

    private let barWidth: CGFloat = 220
    private let barHeight: CGFloat = 6

    var body: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: barHeight / 2)
                .fill(Color.white.opacity(0.10))
                .frame(width: barWidth, height: barHeight)

            // Fill
            RoundedRectangle(cornerRadius: barHeight / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0, green: 1, blue: 1),
                            Color(red: 0, green: 0.8, blue: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(barHeight, barWidth * progress), height: barHeight)
                .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.85), radius: 6, x: 0, y: 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: barHeight / 2))
    }
}

// MARK: - Preview

#Preview {
    GameTitleLoadingView()
}
