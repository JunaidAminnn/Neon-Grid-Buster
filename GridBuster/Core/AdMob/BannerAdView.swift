import SwiftUI
import GoogleMobileAds
import Combine

struct BannerAdView: View {
    let adUnitID: String
    static let bannerHeight: CGFloat = 72 // Increased for safety
    
    init(adUnitID: String = AdUnitIDs.bannerGlobal) {
        self.adUnitID = adUnitID
    }

    @StateObject private var adsManager = AdsManager.shared
    @State private var isAdLoaded = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Layer 0: The actual Ad (Revealed when loaded)
            BannerAdRepresentable(
                adUnitID: adUnitID,
                isAdLoaded: $isAdLoaded,
                canLoadAds: adsManager.shouldRenderAdViews
            )
            .frame(height: BannerAdView.bannerHeight)
            .opacity(isAdLoaded ? 1.0 : 0.0)
            
            // Layer 1: The Loading Placeholder (Covers until loaded)
            if !isAdLoaded {
                ZStack {
                    Color.black
                    
                    VStack(spacing: 8) {
                        Text("NEON AD LOADING")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(2)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                AngularGradient(
                                    colors: [.cyan, .pink, .yellow, .cyan],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    }
                }
                .background(Color.black)
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
            }
        }
        .frame(height: BannerAdView.bannerHeight)
        .background(Color.black)
        .clipped()
    }
}

fileprivate struct BannerAdRepresentable: UIViewRepresentable {
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
            print("AdMob: Banner received visually for \(bannerView.adUnitID ?? "unknown")")
            #endif
            AdsManager.shared.reportBannerSuccess()
            DispatchQueue.main.async {
                self.parent.isAdLoaded = true
            }
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("AdMob: Banner failed visually: \(error.localizedDescription)")
            #endif
            DispatchQueue.main.async {
                self.parent.isAdLoaded = false
            }
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        guard canLoadAds else { return containerView }
        
        let width = UIScreen.main.bounds.width
        let bannerSize = largePortraitAnchoredAdaptiveBanner(width: width)
        let banner = BannerView(adSize: bannerSize)
        
        banner.adUnitID = adUnitID
        // We need a root view controller for clicks, even in UIViewRepresentable
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootVC
        }
        
        banner.delegate = context.coordinator
        banner.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            banner.widthAnchor.constraint(equalToConstant: width),
            banner.heightAnchor.constraint(equalToConstant: BannerAdView.bannerHeight)
        ])
        
        banner.load(Request())
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }
}
