//
//  MainMenuView.swift
//  NeonGridBuster
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                ArcadeBlueBackgroundView()

                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Spacer(minLength: geo.size.height * 0.09)

                        NeonLogoView()

                        Spacer(minLength: geo.size.height * 0.16)

                        VStack(spacing: 14) {
                            Text("NEON MIDNIGHT EDITION")
                                .font(Theme.Fonts.arcade(14))
                                .foregroundStyle(.white.opacity(0.60))
                                .padding(.bottom, 4)

                            NavigationLink {
                                GameView(mode: .adventure)
                            } label: {
                                ModeButton(
                                    title: "Adventure",
                                    systemIcon: "clock",
                                    fill: LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.72, blue: 0.10), Color(red: 1.0, green: 0.56, blue: 0.02)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }

                            NavigationLink {
                                GameView(mode: .classic)
                            } label: {
                                ModeButton(
                                    title: "Classic",
                                    systemIcon: "infinity",
                                    fill: LinearGradient(
                                        colors: [Color(red: 0.15, green: 0.88, blue: 0.72), Color(red: 0.06, green: 0.72, blue: 0.60)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, geo.size.height * 0.14)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct NeonLogoView: View {
    @State private var revealWords = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .top) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(Theme.Palette.neonYellow)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
                    .offset(y: -18)

                ZStack {
                    ExtrudedWord(
                        "NEON",
                        fill: LinearGradient(
                            colors: [Theme.Palette.neonCyan, Theme.Palette.neonYellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(y: revealWords ? -54 : 0)
                    .zIndex(1)

                    ExtrudedWord(
                        "BUSTER",
                        fill: LinearGradient(
                            colors: [Theme.Palette.neonPink, Theme.Palette.neonPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(y: revealWords ? 54 : 0)
                    .zIndex(1)

                    ExtrudedWord(
                        "GRID",
                        fill: LinearGradient(
                            colors: [Theme.Palette.neonLime, Theme.Palette.neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .zIndex(2)
                }
                .frame(height: 180)
                .clipped()
                .animation(.spring(response: 0.9, dampingFraction: 0.82), value: revealWords)
                .onAppear {
                    guard revealWords == false else { return }
                    revealWords = true
                }
            }

            MiniBlockMark()
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Neon Grid Buster")
    }
}

private struct MiniBlockMark: View {
    var body: some View {
        HStack(spacing: 6) {
            BlockDot(color: Theme.Palette.neonYellow)
            BlockDot(color: Theme.Palette.neonYellow)
            BlockDot(color: Theme.Palette.neonYellow)
            BlockDot(color: Theme.Palette.neonYellow)
        }
        .rotationEffect(.degrees(-18))
        .opacity(0.85)
    }
}

private struct BlockDot: View {
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color.opacity(0.85))
            .frame(width: 14, height: 14)
            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.black.opacity(0.22), lineWidth: 1))
            .shadow(color: color.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}

private struct ExtrudedWord: View {
    let text: String
    let fill: LinearGradient

    init(_ text: String, fill: LinearGradient) {
        self.text = text
        self.fill = fill
    }

    var body: some View {
        ZStack {
            Text(text)
                .font(Theme.Fonts.arcade(46))
                .foregroundStyle(Color.black.opacity(0.25))
                .offset(x: 0, y: 10)

            Text(text)
                .font(Theme.Fonts.arcade(46))
                .foregroundStyle(Color.black.opacity(0.12))
                .offset(x: 0, y: 7)

            Text(text)
                .font(Theme.Fonts.arcade(46))
                .foregroundStyle(fill)
                .overlay(
                    Text(text)
                        .font(Theme.Fonts.arcade(46))
                        .foregroundStyle(.white.opacity(0.22))
                        .mask(
                            LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                        )
                )
                .shadow(color: Color.black.opacity(0.24), radius: 14, x: 0, y: 12)
        }
    }
}

private struct ModeButton: View {
    let title: String
    let systemIcon: String
    let fill: LinearGradient

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: systemIcon)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))

                Text(title)
                    .font(Theme.Fonts.arcade(24))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(fill)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.28), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.softLight)
                    .opacity(0.85)
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 16)
    }
}

#Preview {
    MainMenuView()
}
