//
//  SettingsView.swift
//  NeonGridBuster
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var onHome: (() -> Void)? = nil
    var onReplay: (() -> Void)? = nil

    @AppStorage("settings.soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("settings.bgmEnabled") private var bgmEnabled: Bool = true
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings.ghostEnabled") private var ghostEnabled: Bool = true

    var body: some View {
        ZStack {
            ArcadeBlueBackgroundView()

            Color.black.opacity(0.30)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Text("Settings")
                        .font(Theme.Fonts.arcade(26))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.22), radius: 0, x: 0, y: 2)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white.opacity(0.90))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 14)

                VStack(spacing: 0) {
                    SettingsToggleRow(icon: "speaker.wave.2.fill", title: "Sound", isOn: $soundEnabled)
                    Divider().overlay(Color.white.opacity(0.10))
                    SettingsToggleRow(icon: "music.note", title: "BGM", isOn: $bgmEnabled)
                    Divider().overlay(Color.white.opacity(0.10))
                    SettingsToggleRow(icon: "iphone.radiowaves.left.and.right", title: "Vibration", isOn: $hapticsEnabled)
                    Divider().overlay(Color.white.opacity(0.10))
                    SettingsToggleRow(icon: "square.on.square", title: "Ghost Preview", isOn: $ghostEnabled)
                }
                .padding(.horizontal, 14)

                VStack(spacing: 12) {
                    SettingsActionRow(icon: "house.fill", title: "Home", buttonTitle: "Back") {
                        if let onHome { onHome(); dismiss() } else { dismiss() }
                    }

                    SettingsActionRow(icon: "arrow.counterclockwise", title: "Replay", buttonTitle: "Play") {
                        if let onReplay { onReplay(); dismiss() }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.Palette.arcadePanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blendMode(.softLight)
                    )
            )
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.35), radius: 30, x: 0, y: 22)
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white.opacity(0.95))
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))

            Text(title)
                .font(Theme.Fonts.arcade(20))
                .foregroundStyle(.white.opacity(0.95))

            Spacer(minLength: 0)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Palette.neonLime)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SettingsActionRow: View {
    let icon: String
    let title: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white.opacity(0.95))
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))

            Text(title)
                .font(Theme.Fonts.arcade(20))
                .foregroundStyle(.white.opacity(0.95))

            Spacer(minLength: 0)

            Button(action: action) {
                Text(buttonTitle)
                    .font(Theme.Fonts.arcade(18))
                    .foregroundStyle(.white.opacity(0.98))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.20, green: 0.92, blue: 0.30), Color(red: 0.10, green: 0.65, blue: 0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    SettingsView()
}
