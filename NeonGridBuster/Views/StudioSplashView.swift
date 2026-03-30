//
//  StudioSplashView.swift
//  NeonGridBuster
//
//  Studio splash — "SHAFEEK STUDIOS" neon logo shown for 2 seconds
//  before transitioning to the main game title screen.
//

import SwiftUI

struct StudioSplashView: View {

    // MARK: - State

    /// Drives the crossfade from splash → main menu.
    @State private var navigateToMenu = false

    /// Controls the logo's fade-in / glow pulse animation.
    @State private var logoVisible  = false
    @State private var glowPulse    = false

    // MARK: - Body

    var body: some View {
        ZStack {
            if navigateToMenu {
                GameTitleLoadingView()
                    .transition(.opacity)
            } else {
                splashContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.55), value: navigateToMenu)
    }

    // MARK: - Splash Content

    private var splashContent: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────────
            LinearGradient(
                colors: [
                    Color(red: 0x0D, green: 0x01, blue: 0x2B),   // deep dark violet  → top
                    Color(red: 0x06, green: 0x00, blue: 0x12),   // ultra-dark violet → mid
                    Color(red: 0x00, green: 0x01, blue: 0x05)    // near-black        → bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle radial ambient behind the logo
            RadialGradient(
                colors: [
                    Color(red: 1, green: 0, blue: 1).opacity(glowPulse ? 0.22 : 0.10),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 340
            )
            .blendMode(.plusLighter)
            .ignoresSafeArea()
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: glowPulse
            )

            // ── Logo ──────────────────────────────────────────────────────
            VStack(spacing: 10) {
                studioNameText
                taglineText
            }
            .opacity(logoVisible ? 1 : 0)
            .scaleEffect(logoVisible ? 1.0 : 0.82)
            .animation(.spring(response: 0.75, dampingFraction: 0.72), value: logoVisible)
        }
        .onAppear {
            // Trigger logo entrance
            logoVisible = true
            glowPulse   = true

            // After 2 seconds transition to main menu
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                navigateToMenu = true
            }
        }
    }

    // MARK: - Sub-views

    /// "SHAFEEK SOLUTIONS" split vertically and scaled to exact matching width
    private var studioNameText: some View {
        VStack(spacing: -6) {
            neonWord("SHAFEEK")
            neonWord("SOLUTIONS")
        }
        .padding(.horizontal, 40)
        .tracking(6)
        .padding(.leading, 6)
    }

    private func neonWord(_ text: String) -> some View {
        ZStack {
            // Outer soft glow layers (bloom)
            Text(text)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .foregroundStyle(Color(red: 1, green: 0, blue: 1))
                .blur(radius: 28)
                .opacity(glowPulse ? 0.85 : 0.55)

            Text(text)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .foregroundStyle(Color(red: 1, green: 0, blue: 1))
                .blur(radius: 14)
                .opacity(0.70)

            // Tight inner glow
            Text(text)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .foregroundStyle(Color(red: 1, green: 0, blue: 1).opacity(0.60))
                .blur(radius: 5)

            // Crisp white core text
            Text(text)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 1, green: 0.85, blue: 1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Sharp magenta shadow to simulate tube-lighting edge
                .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.90), radius: 8,  x: 0, y: 0)
                .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.55), radius: 22, x: 0, y: 0)
        }
    }

    /// Subtle edition tag below the main wordmark
    private var taglineText: some View {
        Text("PRESENTS")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.38))
            .tracking(8)
            .padding(.leading, 8)
    }
}

// MARK: - Preview

#Preview {
    StudioSplashView()
}
