//
//  MoreSettingsView.swift
//  NeonGridBuster
//
//  Prompt 5.2 — "More" utility overlay (clone of image_6.png).
//  ───────────────────────────────────────────────────────────────────────────
//  • Deep neon-blue (#000D1A) background with animated cyan neon border
//  • App logo block + version info
//  • 5 social-link rows with flat neon-coloured icons
//  • Privacy / Legal / More-Info link rows with cyan > arrows
//  • Ad banner placeholder at bottom
//  • Close (✕) button top-right
//

import SwiftUI

// MARK: - MoreSettingsView

struct MoreSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var borderPulse  = false
    @State private var panelVisible = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNum   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Body

    var body: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.65).ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                headerBar
                    .padding(.bottom, 8)

                neonDivider

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        appIdentityBlock
                        neonDivider.padding(.vertical, 8)
                        socialLinksBlock
                        neonDivider.padding(.vertical, 8)
                        legalLinksBlock
                        neonDivider.padding(.vertical, 8)
                        adBannerPlaceholder
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .frame(maxWidth: 400)
            .background(panelBackground)
            .overlay(panelBorder)
            .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(borderPulse ? 0.28 : 0.12), radius: 28)
            .shadow(color: .black.opacity(0.60), radius: 44, x: 0, y: 24)
            .padding(.horizontal, 16)
            .scaleEffect(panelVisible ? 1.0 : 0.88)
            .opacity(panelVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.40, dampingFraction: 0.72), value: panelVisible)
        }
        .onAppear {
            panelVisible = true
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                borderPulse = true
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Panel Background / Border

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0x00/255, green: 0x0D/255, blue: 0x1A/255),
                        Color(red: 0x00/255, green: 0x07/255, blue: 0x12/255),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 0, green: 1, blue: 1).opacity(borderPulse ? 0.90 : 0.55),
                        Color(red: 0, green: 0.65, blue: 1).opacity(borderPulse ? 0.65 : 0.30),
                        Color(red: 0, green: 1, blue: 1).opacity(borderPulse ? 0.90 : 0.55),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.8
            )
    }

    private var neonDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color(red: 0, green: 1, blue: 1).opacity(0.30), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Balance spacer
            Color.clear.frame(width: 36, height: 36)
            Spacer()

            Text("MORE INFO")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.45), radius: 8)

            Spacer()

            // Close button
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white.opacity(0.90))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    .shadow(color: .black.opacity(0.30), radius: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }

    // MARK: - App Identity Block

    private var appIdentityBlock: some View {
        VStack(spacing: 10) {
            // App "logo" — styled block cluster matching game aesthetic
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0, green: 1, blue: 1), Color(red: 0, green: 0.6, blue: 1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.32), .clear],
                                startPoint: .topLeading, endPoint: .center
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                    )
                    .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.55), radius: 16)

                VStack(spacing: 2) {
                    Text("NGB")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            // App name
            VStack(spacing: 2) {
                Text("NEON GRID BUSTER")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .tracking(2)
                    .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.40), radius: 6)

                Text("by Shafeek Studios")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.40))

                Text("Version \(appVersion)  (\(buildNum))")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color(red: 0, green: 1, blue: 1).opacity(0.50))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    // MARK: - Social Links

    private struct SocialLink: Identifiable {
        let id         = UUID()
        let icon:  String        // SF Symbol name
        let label: String
        let urlStr: String
        let color: Color
    }

    private let socialLinks: [SocialLink] = [
        SocialLink(icon: "play.rectangle.fill", label: "TikTok",   urlStr: "https://tiktok.com",   color: Color(red: 1.0, green: 0.0, blue: 0.55)),
        SocialLink(icon: "bubble.left.and.bubble.right.fill", label: "Discord", urlStr: "https://discord.com", color: Color(red: 0.40, green: 0.46, blue: 0.94)),
        SocialLink(icon: "xmark.circle.fill",  label: "X (Twitter)", urlStr: "https://x.com",   color: Color(red: 0.8,  green: 0.8,  blue: 0.8)),
        SocialLink(icon: "person.2.fill",      label: "Facebook",  urlStr: "https://facebook.com", color: Color(red: 0.26, green: 0.52, blue: 0.96)),
        SocialLink(icon: "play.tv.fill",       label: "YouTube",   urlStr: "https://youtube.com",  color: Color(red: 1.0, green: 0.18, blue: 0.18)),
    ]

    private var socialLinksBlock: some View {
        VStack(spacing: 4) {
            moreLabel("FOLLOW US")

            ForEach(socialLinks) { link in
                Button {
                    if let url = URL(string: link.urlStr) { openURL(url) }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: link.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(link.color)
                            .frame(width: 42, height: 42)
                            .background(link.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(link.color.opacity(0.28), lineWidth: 1)
                            )
                            .shadow(color: link.color.opacity(0.40), radius: 8)

                        Text(link.label)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.90))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Legal Links

    private struct LegalLink: Identifiable {
        let id    = UUID()
        let title: String
        let urlStr: String
    }

    private let legalLinks: [LegalLink] = [
        LegalLink(title: "Privacy Policy",    urlStr: "https://example.com/privacy"),
        LegalLink(title: "Terms of Service",  urlStr: "https://example.com/terms"),
        LegalLink(title: "Cookie Policy",     urlStr: "https://example.com/cookies"),
        LegalLink(title: "Support",           urlStr: "mailto:support@shafeeekstudios.com"),
        LegalLink(title: "License Info",      urlStr: "https://example.com/license"),
    ]

    private var legalLinksBlock: some View {
        VStack(spacing: 4) {
            moreLabel("LEGAL & SUPPORT")

            ForEach(legalLinks) { link in
                Button {
                    if let url = URL(string: link.urlStr) { openURL(url) }
                } label: {
                    HStack {
                        Text(link.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0, green: 1, blue: 1).opacity(0.90))

                        Spacer()

                        Text("›")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(Color(red: 0, green: 1, blue: 1).opacity(0.55))
                    }
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0, green: 1, blue: 1).opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Ad Banner Placeholder

    private var adBannerPlaceholder: some View {
        VStack(spacing: 6) {
            moreLabel("ADS")

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                            .foregroundStyle(Color.white.opacity(0.14))
                    )

                VStack(spacing: 6) {
                    Image(systemName: "rectangle.and.hand.point.up.left")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.18))
                    Text("Ad Banner Placeholder")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.18))
                }
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
        }
    }

    // MARK: - Section Label Helper

    private func moreLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0, green: 1, blue: 1).opacity(0.50))
                .tracking(5)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .padding(.top, 2)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MoreSettingsView()
    }
}
