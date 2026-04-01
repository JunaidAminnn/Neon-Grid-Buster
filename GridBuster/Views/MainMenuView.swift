//
//  MainMenuView.swift
//  NeonGridBuster
//
//  Prompt 2.1 — Main Menu UI.
//  Deep neon gradient background, cyan/pink title, neon-orange Adventure
//  and neon-pink Classic mode buttons with NavigationStack routing.
//

import SwiftUI

// MARK: - MainMenuView

struct MainMenuView: View {
    var namespace: Namespace.ID? = nil

    // ── State ────────────────────────────────────────────────────────────
    @State private var showAdventure  = false
    @State private var showClassic    = false

    // button press feedback
    @State private var adventurePress = false
    @State private var classicPress   = false
    @State private var moreGamesPress = false

    // entrance animations
    @State private var logoVisible    = false
    @State private var buttonsVisible = false
    @State private var glowPulse      = false

    // ── Body ─────────────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            // ── Background ─────────────────────────────────────────
            MenuBackground(pulse: glowPulse)

                // ── Content ────────────────────────────────────────────
                GeometryReader { geo in
                    VStack(spacing: 0) {

                        Spacer(minLength: geo.size.height * 0.05 + 5)

                        // ── Logo block (Prompt 1.2 title style) ────────
                        if let ns = namespace {
                            menuLogo
                                .matchedGeometryEffect(id: "mainLogo", in: ns)
                        } else {
                            menuLogo
                                .opacity(logoVisible ? 1 : 0)
                                .offset(y: logoVisible ? 0 : -28)
                                .animation(.spring(response: 0.75, dampingFraction: 0.72), value: logoVisible)
                        }

                        Spacer(minLength: geo.size.height * 0.06 + 32)

                        // ── Mode buttons ───────────────────────────────
                        VStack(spacing: 16) {
                            // Adventure button → AdventureMapView
                            NavigationLink(destination: AdventureMapView()) {
                                ModeButton(
                                    title:      "Adventure",
                                    systemIcon: "clock.fill",
                                    accentColor: Color(red: 0.3, green: 0.7, blue: 1.0),    // Light blue
                                    glowColor:   Color(red: 0.0, green: 0.8, blue: 1.0),    // Bright cyan
                                    isPressed:   adventurePress
                                )
                            }
                            .buttonStyle(ScaleButtonStyle(isPressed: $adventurePress))

                            // Classic button → GameView(mode: .classic)
                            NavigationLink(destination: GameView(mode: .classic)) {
                                ModeButton(
                                    title:      "Classic",
                                    systemIcon: "infinity",
                                    accentColor: Color(red: 0.3, green: 0.85, blue: 0.3),   // Light green
                                    glowColor:   Color(red: 0.0, green: 1.0, blue: 0.0),    // Bright green
                                    isPressed:   classicPress
                                )
                            }
                            .buttonStyle(ScaleButtonStyle(isPressed: $classicPress))
                            
                            // More Games button → Currently Non-functional
                            Button(action: {}) {
                                ModeButton(
                                    title:      "More Games",
                                    systemIcon: "gamecontroller.fill",
                                    accentColor: Color(red: 1.0, green: 0.07, blue: 0.94),  // Vibrant neon magenta/pink (#FF13F0)
                                    glowColor:   Color(red: 1.0, green: 0.07, blue: 0.94),
                                    isPressed:   moreGamesPress
                                )
                        }
                            .buttonStyle(ScaleButtonStyle(isPressed: $moreGamesPress))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, geo.size.height * 0.15)
                        .opacity(buttonsVisible ? 1 : 0)
                        .offset(y: buttonsVisible ? 0 : 32)
                        .animation(.spring(response: 0.75, dampingFraction: 0.72).delay(0.2), value: buttonsVisible)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                logoVisible    = true
                buttonsVisible = true
                glowPulse      = true
            }
    }

    // MARK: - Logo

    private var menuLogo: some View {
        VStack(spacing: 6) {
            // Arcade-button crown icon (same as GameTitleLoadingView)
            MenuArcadeIcon()
                .padding(.bottom, 10)

            // "NEON GRID" — cyan #00FFFF
            MenuNeonWord(
                text:     "NEON GRID",
                color:    Color(red: 0, green: 1, blue: 1),
                fontSize: 42
            )

            // "BUSTER" — hot pink #FF00FF
            MenuNeonWord(
                text:     "BUSTER",
                color:    Color(red: 1, green: 0, blue: 1),
                fontSize: 54
            )

            // "MIDNIGHT EDITION" sub-label
            Text("MIDNIGHT EDITION")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
                .tracking(9)
                .padding(.top, 6)
        }
    }


}

// MARK: - MenuBackground

private struct MenuBackground: View {
    let pulse: Bool

    var body: some View {
        ZStack {
            // Base gradient — identical to splash / loading screens
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

            // Cyan top-left ambient
            RadialGradient(
                colors: [Color(red: 0, green: 1, blue: 1).opacity(pulse ? 0.16 : 0.07), .clear],
                center: .topLeading, startRadius: 0, endRadius: 420
            )
            .blendMode(.plusLighter)
            .ignoresSafeArea()

            // Pink top-right ambient
            RadialGradient(
                colors: [Color(red: 1, green: 0, blue: 1).opacity(pulse ? 0.14 : 0.06), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 380
            )
            .blendMode(.plusLighter)
            .ignoresSafeArea()

            // Orange bottom-center (button color echo)
            RadialGradient(
                colors: [Color(red: 1, green: 0.6, blue: 0).opacity(pulse ? 0.09 : 0.03), .clear],
                center: .bottom, startRadius: 0, endRadius: 360
            )
            .blendMode(.plusLighter)
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)
    }
}

// MARK: - MenuNeonWord

/// Neon glowing word for the menu title (mirrors GameTitleLoadingView style).
private struct MenuNeonWord: View {
    let text: String
    let color: Color
    let fontSize: CGFloat

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer bloom
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .blur(radius: 30)
                .opacity(pulse ? 0.80 : 0.42)

            // Mid glow
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .blur(radius: 12)
                .opacity(0.65)

            // Tight inner glow
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(color.opacity(0.55))
                .blur(radius: 4)

            // Crisp core
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: color,               radius: 10, x: 0, y: 0)
                .shadow(color: color.opacity(0.55), radius: 24, x: 0, y: 0)
        }
        .fixedSize(horizontal: true, vertical: false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - MenuArcadeIcon

/// Crown-position app icon (reads from bundle or assets).
private struct MenuArcadeIcon: View {
    @State private var halo = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0, green: 1, blue: 1).opacity(halo ? 0.28 : 0.10))
                .frame(width: 80, height: 80)
                .blur(radius: 20)

            if let appIcon = fetchAppIcon() {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.85), radius: 8)
            } else {
                // Fallback geometry if asset is totally missing
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.cyan, lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "app.dashed")
                            .font(.system(size: 28))
                            .foregroundStyle(.cyan)
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                halo = true
            }
        }
    }

    private func fetchAppIcon() -> UIImage? {
        if let icon = UIImage(named: "AppIcon") { return icon }
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last {
            return UIImage(named: name)
        }
        return nil
    }
}

// MARK: - ModeButton

/// Large rounded-rectangle mode button with a left-side icon container
/// and neon glow matching the button's accent color — mirrors image_2.png layout.
private struct ModeButton: View {
    let title:       String
    let systemIcon:  String
    let accentColor: Color
    let glowColor:   Color
    let isPressed:   Bool

    var body: some View {
        HStack(spacing: 0) {

            // ── Left icon container ─────────────────────────────
            ZStack {
                // Frosted-dark inset
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Image(systemName: systemIcon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white.opacity(0.94))
                    .shadow(color: glowColor.opacity(0.55), radius: 6)
            }
            .padding(.leading, 10)

            // ── Button label ────────────────────────────────────
            Text(title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.97))
                .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 2)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(glowColor, lineWidth: 3)
        )
        // Flat intense neon glow, replacing previous heavy drop shadows
        .shadow(color: glowColor.opacity(0.60), radius: 14, x: 0, y: 0)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isPressed)
    }
}

// MARK: - ScaleButtonStyle

/// Tracks press state for haptic-style scale feedback.
private struct ScaleButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}

// MARK: - Preview

#Preview {
    MainMenuView()
}
