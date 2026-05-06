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
    @StateObject private var portfolioManager = PortfolioManager.shared
    @StateObject private var adsManager       = AdsManager.shared
    @State private var selectedAppID: String? = nil

    struct URLItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

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
                        
                        moreAppsSection
                        
                        // adBannerPlaceholder (Commented out per user request)
                        //    .padding(.bottom, 20)
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
        .onAppear {
            portfolioManager.fetchPortfolio()
        }
        .background(
            ZStack {
                if let id = selectedAppID {
                    StoreKitView(appID: id)
                        .frame(width: 0, height: 0)
                        .onAppear {
                            // Reset selection after a short delay so it can be re-triggered
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                selectedAppID = nil
                            }
                        }
                }
            }
        )
        .navigationBarHidden(true)
    }

    // MARK: - Panel Background / Border

    private var panelBackground: some View {
        Theme.Palette.panelBackground
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
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
                lineWidth: 2.5
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
            // App icon
            Group {
                if let appIcon = fetchAppIcon() {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0, blue: 1), Color(red: 0, green: 1, blue: 1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            )
            .shadow(color: Color(red: 0, green: 1, blue: 1).opacity(0.45), radius: 14, x: 0, y: 0)

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
                utilityButton(title: "Share App", icon: "square.and.arrow.up.fill", color: Theme.Palette.neonYellow) {
                    shareApp()
                }
                
                // Rate Us
                utilityButton(title: "Rate Us", icon: "star.fill", color: Theme.Palette.neonLime) {
                    rateApp()
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
                    .stroke(color.opacity(0.8), lineWidth: 2.2)
            )
            .shadow(color: color.opacity(0.35), radius: 10)
        }
    }

    // MARK: - Links Block

    private var linksBlock: some View {
        VStack(spacing: 10) {
            moreLabel("UTILITIES & LEGAL")
            
            linkRow(title: "About Us", url: AppConfig.aboutUsURL)
            linkRow(title: "Terms and Conditions", url: AppConfig.termsAndConditionsURL)
            linkRow(title: "Privacy Policy", url: AppConfig.privacyPolicyURL)
            linkRow(title: "Terms of Use", url: AppConfig.termsOfUseURL)
        }
        .padding(.vertical, 10)
    }

    // MARK: - More Apps Section

    private var moreAppsSection: some View {
        VStack(spacing: 12) {
            moreLabel("MORE APPS")
            
            if portfolioManager.isLoading && portfolioManager.apps.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Color(red: 0, green: 1, blue: 1))
                    Text("FETCHING NEW RELEASES...")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 10) {
                    // Prioritize Calculator Vault Pro (6759670222) at the top
                    let displayApps = portfolioManager.apps.sorted { app1, app2 in
                        if String(app1.id) == "6759670222" { return true }
                        if String(app2.id) == "6759670222" { return false }
                        return false
                    }
                    
                    if displayApps.isEmpty {
                        Text("CHECK BACK LATER FOR UPDATES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(displayApps) { app in
                            PromotedAppRow(app: app) {
                                selectedAppID = String(app.id)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    private func linkRow(title: String, url: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .onTapGesture {
                    openSafari(url)
                }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white.opacity(0.8))
                .onTapGesture {
                    openSafari(url)
                }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func openSafari(_ urlString: String) {
        if let targetURL = URL(string: urlString) {
            self.safariItem = URLItem(url: targetURL)
        }
    }

    // MARK: - Handlers
    
    private func shareApp() {
        // TODO: Update this link to the live Neon Grid Buster URL before final release
        let text = """
        🎮 Neon Grid Buster

        A premium neon puzzle experience 🧩 with high-contrast visuals and addictive gameplay 🕹️.
        Vibrant, smart, and competitive.

        👉 Download now and master the neon grid! 😎

        https://apps.apple.com/app/calculator-vault-hide-photos/id6759670222
        """
        
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let topVC = getTopViewController() {
            // For iPad compatibility
            if let popover = av.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            topVC.present(av, animated: true)
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            return nil
        }
        
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    private func rateApp() {
        let appId = AppConfig.appStoreID

        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review") {
            openURL(url)
            return
        }

        if let url = URL(string: "https://apps.apple.com/app/id\(appId)?action=write-review") {
            openURL(url)
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

    private var adBannerPlaceholder: some View {
        Group {
            if adsManager.shouldRenderAdViews {
                VStack(spacing: 8) {
                    moreLabel("SPONSOR")
                    
                    BannerAdView(adUnitID: AdUnitIDs.bannerGlobal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                        )
                }
                .padding(.top, 10)
            }
        }
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
