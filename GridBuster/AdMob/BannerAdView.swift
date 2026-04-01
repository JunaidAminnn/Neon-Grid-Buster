import SwiftUI
// import GoogleMobileAds

struct BannerAdView: View {
    let adUnitID: String
    @State private var isAdLoaded = false
    @State private var loadingDots = ""
    @State private var timer: Timer? = nil
    
    @ObservedObject private var adsManager = AdsManager.shared
    
    // Standard banner height
    static let bannerHeight: CGFloat = 60
    
    init(adUnitID: String = AdUnitIDs.bannerGlobal) {
        self.adUnitID = adUnitID
    }
    
    var body: some View {
        if adsManager.shouldRenderAdViews && adsManager.shouldShowBannersThisSession {
            ZStack {
                // Neon-themed loading placeholder
                if !adsManager.adSDKInitialized || !isAdLoaded {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.Palette.neonCyan.opacity(0.35), lineWidth: 1.5)
                                .overlay(
                                    HStack(spacing: 4) {
                                        Text("NEON AD LOADING\(loadingDots)")
                                            .font(.system(size: 13, weight: .black, design: .monospaced))
                                            .foregroundStyle(Theme.Palette.neonCyan.opacity(0.6))
                                            .tracking(1.5)
                                    }
                                )
                        )
                        .onAppear {
                            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                                if loadingDots.count >= 3 {
                                    loadingDots = ""
                                } else {
                                    loadingDots += "."
                                }
                            }
                        }
                        .onDisappear {
                            timer?.invalidate()
                            timer = nil
                        }
                }
                
                // Actual AdMob banner
                BannerAdRepresentable(
                    adUnitID: adUnitID,
                    isAdLoaded: $isAdLoaded,
                    canLoadAds: adsManager.shouldRenderAdViews
                )
                .opacity(isAdLoaded ? 1 : 0.01)
            }
            .frame(height: BannerAdView.bannerHeight)
            .padding(.horizontal, 16)
        }
    }
}

fileprivate struct BannerAdRepresentable: UIViewControllerRepresentable {
    let adUnitID: String
    @Binding var isAdLoaded: Bool
    let canLoadAds: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdRepresentable
        
        init(_ parent: BannerAdRepresentable) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            #if DEBUG
            print("AdMob: Banner received for \(bannerView.adUnitID ?? "")")
            #endif
            AdsManager.shared.reportBannerSuccess()
            DispatchQueue.main.async {
                self.parent.isAdLoaded = true
            }
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("AdMob: Banner failed for \(bannerView.adUnitID ?? ""): \(error.localizedDescription)")
            #endif
            DispatchQueue.main.async {
                self.parent.isAdLoaded = false
            }
        }
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        
        guard canLoadAds else { return viewController }
        
        let width = UIScreen.main.bounds.width
        // Use adaptive size
        let bannerSize = largePortraitAnchoredAdaptiveBanner(width: width)
        let banner = BannerView(adSize: bannerSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = viewController
        banner.delegate = context.coordinator
        
        banner.frame = CGRect(x: 0, y: 0, width: width, height: BannerAdView.bannerHeight)
        viewController.view.clipsToBounds = true
        viewController.view.addSubview(banner)
        
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            banner.widthAnchor.constraint(equalToConstant: width),
            banner.heightAnchor.constraint(equalToConstant: BannerAdView.bannerHeight)
        ])
        
        banner.load(Request())
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
