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
    @State private var safariItem:  URLItem? = nil

    struct URLItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let placeholderURL = "https://docs.google.com/spreadsheets/d/1" // Placeholder Google Sheet

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
                        
                        utilityButtonsBlock
                        neonDivider.padding(.vertical, 8)
                        
                        linksBlock
                        
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
            .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(borderPulse ? 0.30 : 0.15), radius: 24)
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
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .navigationBarHidden(true)
    }

    // MARK: - Panel Background / Border

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0x24/255, green: 0x00/255, blue: 0x21/255), // Dark Purple #240021
                        Color(red: 0x15/255, green: 0x00/255, blue: 0x12/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 1, green: 0, blue: 1).opacity(borderPulse ? 0.80 : 0.45),
                        Color(red: 0, green: 1, blue: 1).opacity(borderPulse ? 0.60 : 0.25),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }

    private var neonDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color(red: 1, green: 0, blue: 1).opacity(0.20), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 1.5)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Color.clear.frame(width: 36, height: 36)
            Spacer()

            Text("MORE INFO")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.45), radius: 8)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white.opacity(0.90))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }

    // MARK: - App Identity Block

    private var appIdentityBlock: some View {
        VStack(spacing: 12) {
            // App "logo"
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0, blue: 1), Color(red: 0, green: 1, blue: 1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.5), radius: 12)

                Image(systemName: "grid.reveal")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("NEON GRID BUSTER")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(2)
                
                Text("Version \(appVersion)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Utility Buttons
    
    private var utilityButtonsBlock: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Share App
                utilityButton(title: "Share App", icon: "square.and.arrow.up.fill", color: .cyan) {
                    shareApp()
                }
                
                // Found a Bug
                utilityButton(title: "Found a Bug", icon: "ant.fill", color: .pink) {
                    contactSupport()
                }
            }
        }
    }
    
    private func utilityButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .black))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: color.opacity(0.2), radius: 8)
        }
    }

    // MARK: - Links Block

    private var linksBlock: some View {
        VStack(spacing: 10) {
            moreLabel("UTILITIES & LEGAL")
            
            linkRow(title: "About Us", url: placeholderURL)
            linkRow(title: "Terms & Policy", url: placeholderURL)
            linkRow(title: "Privacy Policy", url: placeholderURL)
            linkRow(title: "Terms of Use", url: placeholderURL)
        }
        .padding(.vertical, 10)
    }
    
    private func linkRow(title: String, url: String) -> some View {
        Button {
            if let targetURL = URL(string: url) {
                self.safariItem = URLItem(url: targetURL)
            }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(red: 1, green: 0, blue: 1).opacity(0.5))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Handlers
    
    private func shareApp() {
        let text = "Check out Neon Grid Buster! It's an awesome neon-style puzzle game."
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
    
    private func contactSupport() {
        let email = "support@shafeekstudios.com"
        let subject = "Neon Grid Buster Bug Report"
        let mailto = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: mailto) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Ad Banner Placeholder

    private var adBannerPlaceholder: some View {
        VStack(spacing: 8) {
            moreLabel("SPONSOR")

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(Color.white.opacity(0.15))
                    )

                Text("AD SPACE")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.15))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .padding(.top, 10)
    }

    // MARK: - Section Label Helper

    private func moreLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(4)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}


// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MoreSettingsView()
    }
}
