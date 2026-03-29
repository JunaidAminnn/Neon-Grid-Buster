//
//  SettingsView.swift
//  NeonGridBuster
//
//  Prompt 2.2 — Settings Overlay UI.
//  Dark smoky (#121212) modal container with cyan neon border.
//  Mirrors image_5.png layout: toggle rows, green action buttons, blue skin button.
//

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    // ── Callbacks (passed in by host screen) ─────────────────────────────
    var onHome:   (() -> Void)? = nil
    var onReplay: (() -> Void)? = nil

    // ── Persisted settings ───────────────────────────────────────────────
    @AppStorage("settings.soundEnabled")   private var soundEnabled:   Bool = true
    @AppStorage("settings.bgmEnabled")     private var bgmEnabled:     Bool = true
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings.ghostEnabled")   private var ghostEnabled:   Bool = true

    // ── Local UI state ───────────────────────────────────────────────────
    @State private var panelVisible   = false
    @State private var skinSelected   = false
    @State private var borderPulse    = false
    @State private var showMore       = false     // Prompt 5.2 trigger

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Dimmed scrim ──────────────────────────────────────────────
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // ── Modal panel ───────────────────────────────────────────────
            VStack(spacing: 0) {

                panelHeader
                    .padding(.bottom, 10)

                Divider()
                    .overlay(Color(red: 0, green: 1, blue: 1).opacity(0.18))
                    .padding(.horizontal, 2)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {

                        // ── Toggle section ────────────────────────────────
                        sectionLabel("AUDIO & FEEDBACK")

                        SettingsToggleRow(
                            icon:  "speaker.wave.2.fill",
                            title: "Sound",
                            isOn:  $soundEnabled
                        )
                        SettingsToggleRow(
                            icon:  "music.note",
                            title: "BGM",
                            isOn:  $bgmEnabled
                        )
                        SettingsToggleRow(
                            icon:  "iphone.radiowaves.left.and.right",
                            title: "Vibration",
                            isOn:  $hapticsEnabled
                        )
                        SettingsToggleRow(
                            icon:  "square.on.square",
                            title: "Ghost Preview",
                            isOn:  $ghostEnabled
                        )

                        // ── Navigation section ────────────────────────────
                        sectionLabel("NAVIGATION")
                            .padding(.top, 6)

                        SettingsActionRow(
                            icon:        "house.fill",
                            title:       "Home",
                            buttonTitle: "Back",
                            buttonColor: .green
                        ) {
                            if let onHome { onHome() }
                            dismiss()
                        }

                        SettingsActionRow(
                            icon:        "arrow.counterclockwise",
                            title:       "Replay",
                            buttonTitle: "Play",
                            buttonColor: .green
                        ) {
                            if let onReplay { onReplay() }
                            dismiss()
                        }

                        SettingsActionRow(
                            icon:        "gamecontroller.fill",
                            title:       "More Games",
                            buttonTitle: "Start",
                            buttonColor: .green
                        ) {
                            // Phase N: deep-link to game store / more games
                        }

                        SettingsActionRow(
                            icon:        "gearshape.2.fill",
                            title:       "More Settings",
                            buttonTitle: "Open",
                            buttonColor: .green
                        ) {
                            showMore = true
                        }

                        // ── Skin section ──────────────────────────────────
                        sectionLabel("APPEARANCE")
                            .padding(.top, 6)

                        SettingsActionRow(
                            icon:        "paintpalette.fill",
                            title:       "Default Skin",
                            buttonTitle: skinSelected ? "Applied" : "Apply",
                            buttonColor: .blue
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                skinSelected = true
                            }
                        }

                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: 380)
            .background(
                ZStack {
                    // Smoky dark base #121212
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0x12/255, green: 0x12/255, blue: 0x12/255))

                    // Subtle inner highlight
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.06), .clear],
                                startPoint: .top, endPoint: .center
                            )
                        )
                }
            )
            // Cyan neon border (the key brand element)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0, green: 1, blue: 1).opacity(borderPulse ? 0.90 : 0.55),
                                Color(red: 0, green: 0.7, blue: 1).opacity(borderPulse ? 0.70 : 0.35),
                                Color(red: 0, green: 1, blue: 1).opacity(borderPulse ? 0.90 : 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.8
                    )
            )
            // Neon outer glow on the container
            .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(borderPulse ? 0.30 : 0.14), radius: 24, x: 0, y: 0)
            .shadow(color: Color.black.opacity(0.55), radius: 40, x: 0, y: 22)
            .padding(.horizontal, 20)
            // Entrance animation
            .scaleEffect(panelVisible ? 1.0 : 0.90)
            .opacity(panelVisible ? 1.0 : 0)
            .animation(.spring(response: 0.42, dampingFraction: 0.74), value: panelVisible)
        }
        .onAppear {
            panelVisible = true
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                borderPulse = true
            }
        }
        .sheet(isPresented: $showMore) {
            MoreSettingsView()
                .presentationBackground(.clear)
                .presentationDetents([.large])
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var panelHeader: some View {
        HStack(alignment: .center) {
            // Spacer so title is visually centered despite the X button
            Color.clear.frame(width: 38, height: 38)

            Spacer()

            Text("Settings")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))
                .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.40), radius: 8)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0, green: 1, blue: 1).opacity(0.55))
                .tracking(4)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// MARK: - SettingsToggleRow

private struct SettingsToggleRow: View {

    let icon:  String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {

            // Icon container
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 44, height: 44)
                .background(
                    Color.white.opacity(0.09),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            // Title
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            Spacer(minLength: 0)

            // Cyan-tinted toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0, green: 1, blue: 1))
                // Glow effect when ON
                .shadow(
                    color: isOn
                        ? Color(red: 0, green: 1, blue: 1).opacity(0.60)
                        : .clear,
                    radius: 8
                )
                .animation(.easeInOut(duration: 0.2), value: isOn)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isOn
                                ? Color(red: 0, green: 1, blue: 1).opacity(0.25)
                                : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - SettingsActionRow

private struct SettingsActionRow: View {

    let icon:        String
    let title:       String
    let buttonTitle: String
    let buttonColor: ActionButtonColor
    let action:      () -> Void

    enum ActionButtonColor {
        case green, blue

        var gradient: [Color] {
            switch self {
            case .green:
                return [Color(red: 0.20, green: 0.85, blue: 0.28), Color(red: 0.10, green: 0.60, blue: 0.17)]
            case .blue:
                return [Color(red: 0.16, green: 0.48, blue: 0.96), Color(red: 0.10, green: 0.32, blue: 0.75)]
            }
        }

        var glow: Color {
            switch self {
            case .green: return Color(red: 0.10, green: 0.90, blue: 0.28)
            case .blue:  return Color(red: 0.16, green: 0.55, blue: 1.00)
            }
        }
    }

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {

            // Icon container
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 44, height: 44)
                .background(
                    Color.white.opacity(0.09),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            // Title
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            Spacer(minLength: 0)

            // Colored action button
            Button {
                action()
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 64)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: buttonColor.gradient,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
                            .blendMode(.softLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: buttonColor.glow.opacity(0.45), radius: 10, x: 0, y: 4)
                    .scaleEffect(isPressed ? 0.94 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isPressed)
            }
            .buttonStyle(ActionPressStyle(isPressed: $isPressed))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - ActionPressStyle

private struct ActionPressStyle: ButtonStyle {
    @Binding var isPressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, val in isPressed = val }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SettingsView(
            onHome:   { print("Home tapped") },
            onReplay: { print("Replay tapped") }
        )
    }
}
