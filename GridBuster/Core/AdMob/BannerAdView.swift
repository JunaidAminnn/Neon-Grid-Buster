import SwiftUI
import GoogleMobileAds
import Combine

struct BannerAdView: View {
    let adUnitID: String
    static let bannerHeight: CGFloat = 68
    
    init(adUnitID: String = AdUnitIDs.bannerGlobal) {
        self.adUnitID = adUnitID
    }

    @StateObject private var adsManager = AdsManager.shared
    @State private var isAdLoaded = false
    @State private var minimumLoadingTimePassed = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Ad container
            ZStack {
                // Actual AdMob banner
                BannerAdRepresentable(
                    adUnitID: adUnitID,
                    isAdLoaded: $isAdLoaded,
                    canLoadAds: adsManager.shouldRenderAdViews
                )
                .opacity(isAdLoaded && minimumLoadingTimePassed ? 1 : 0.01)
                
                // Loading Placeholder
                if !isAdLoaded || !minimumLoadingTimePassed {
                    ZStack {
                        Color.black
                        
                        VStack(spacing: 12) {
                            Text("NEON AD LOADING")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.8))
                                .tracking(2)
                            
                            // Premium Spinning Ring
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    AngularGradient(
                                        colors: [.cyan, .pink, .yellow, .cyan],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 24, height: 24)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .onAppear {
                                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                        isAnimating = true
                                    }
                                }
                        }
                        .padding(.horizontal, 16)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(height: BannerAdView.bannerHeight)
            .onAppear {
                // Minimum loading time for a premium feel
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        minimumLoadingTimePassed = true
                    }
                }
            }
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
        let bannerSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        let banner = BannerView(adSize: bannerSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = viewController
        banner.delegate = context.coordinator
        
        viewController.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            banner.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            banner.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])
        
        banner.load(Request())
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
