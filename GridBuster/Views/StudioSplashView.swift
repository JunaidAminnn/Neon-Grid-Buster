//
//  StudioSplashView.swift
//  NeonGridBuster
//

import SwiftUI

struct StudioSplashView: View {

    // MARK: - State

    /// Drives the crossfade from splash → main menu.
    @State private var navigateToMenu = false

    /// Controls the logo's fade-in / glow pulse animation.
    @State private var logoVisible  = false
    @State private var glowPulse    = false
    
    /// Tracks if the privacy flow (ATT/UMP) is finished.
    @State private var privacyFlowFinished = false
    /// Tracks if the minimum splash duration has passed.
    @State private var splashDurationPassed = false

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
        .onChange(of: privacyFlowFinished) { _, finished in
            checkNavigation()
        }
        .onChange(of: splashDurationPassed) { _, passed in
            checkNavigation()
        }
    }

    // MARK: - Splash Content

    private var splashContent: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────────
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

            // ── AdMob & Privacy Flow ──────────────────────────────────────
            // Start the privacy/consent flow.
            Task {
                print("Splash: Starting Privacy Flow (UMP/ATT)...")
                await AdsManager.shared.runConsentAndTrackingFlowIfNeeded()
                withAnimation {
                    print("Splash: Privacy Flow Finished.")
                    privacyFlowFinished = true
                }
            }

            // After minimum duration, allow transition if privacy flow is also done.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                print("Splash: Minimum duration passed.")
                splashDurationPassed = true
            }
        }
    }
    
    private func checkNavigation() {
        if privacyFlowFinished && splashDurationPassed {
            print("Splash: All conditions met. Navigating to menu.")
            navigateToMenu = true
        }
    }

    // MARK: - Sub-views

    /// "SHAFEEK SOLUTIONS" split vertically and scaled to exact matching width
    private var studioNameText: some View {
        VStack(spacing: -4) {
            neonWord("SHAFEEK", size: 45)
            neonWord("SOLUTIONS", size: 35)
        }
        .padding(.horizontal, 40)
        .tracking(6)
        .padding(.leading, 6)
    }

    private func neonWord(_ text: String, size: CGFloat) -> some View {
        ZStack {
            // Outer soft glow layers (bloom)
            Text(text)
                .font(.system(size: size, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Color(red: 1, green: 0, blue: 1))
                .blur(radius: 28)
                .opacity(glowPulse ? 0.85 : 0.55)

            Text(text)
                .font(.system(size: size, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Color(red: 1, green: 0, blue: 1))
                .blur(radius: 14)
                .opacity(0.70)

            // Tight inner glow
            Text(text)
                .font(.system(size: size, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Color(red: 1, green: 0, blue: 1).opacity(0.60))
                .blur(radius: 5)

            // Crisp white core text
            Text(text)
                .font(.system(size: size, weight: .black, design: .rounded))
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
