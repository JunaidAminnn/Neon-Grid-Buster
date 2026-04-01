import SwiftUI
// import GoogleMobileAds
// import UserMessagingPlatform
import AppTrackingTransparency
import Combine

// MARK: - AdUnitIDs
struct AdUnitIDs {
    #if DEBUG
    // Standard AdMob Test Ad Unit IDs
        static let bannerGlobal         = "ca-app-pub-3940256099942544/2934735716"
        static let interstitialGlobal   = "ca-app-pub-3940256099942544/4411468910"
        static let openApp              = "ca-app-pub-3940256099942544/5575463023"
        static let rewardedGame         = "ca-app-pub-3940256099942544/1712485313"
        static let rewardedGlobal       = "ca-app-pub-3940256099942544/1712485313"
    #else
    // Real Production Ad Unit IDs provided by user
    static let bannerGlobal         = "ca-app-pub-7248360860042690/6799555717"
    static let interstitialGlobal   = "ca-app-pub-7248360860042690/4002001983"
    static let openApp              = "ca-app-pub-7248360860042690/9017487531"
    static let rewardedGame        = "ca-app-pub-7248360860042690/5294902350"
    static let rewardedGlobal      = "ca-app-pub-7248360860042690/8634344153"
    #endif
}

// MARK: - Enums
enum AdTrackingPermissionState: String {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}

enum AdFlowState: String {
    case subscribedUser
    case pendingConsentAndTracking
    case freeUserTrackingAllowed
    case freeUserTrackingDeniedOrRestricted
}

// MARK: - AdsManager
@MainActor
class AdsManager: NSObject, ObservableObject {
    static let shared = AdsManager()
    
    @Published private(set) var trackingPermissionState: AdTrackingPermissionState = .notDetermined
    @Published private(set) var consentAndTrackingResolved: Bool = false
    @Published private(set) var adFlowState: AdFlowState = .pendingConsentAndTracking
    @Published private(set) var adSDKInitialized: Bool = false
    @Published var isConsentFlowHandled: Bool = false
    private var isInitializingAds: Bool = false
    
    // Global Session Flag (Require at least one success within 5s or during session)
    @Published var shouldShowBannersThisSession: Bool = true
    private var sessionGraceTimer: Timer?
    private var hasAnyBannerSucceeded: Bool = false
    
    // Ad Store
    @Published var interstitial: InterstitialAd?
    @Published var rewardedAd: RewardedAd?
    @Published var appOpenAd: AppOpenAd?
    
    @AppStorage("adsConsentAndTrackingResolved") private var storedConsentAndTrackingResolved: Bool = false
    @AppStorage("adsTrackingPermissionState")   private var storedTrackingPermissionStateRaw: String = AdTrackingPermissionState.notDetermined.rawValue
    
    // Frequency Capping
    @AppStorage("adTransactionCount") private var transactionCount: Int = 0
    @AppStorage("adResumeCount")      private var resumeCount: Int = 0
    
    // Configs
    private let transactionFrequency = 3
    private let resumeFrequency      = 3
    
    private var appOpenAdLoadTime: Date?
    private var onAdDismissed: (() -> Void)?
    
    override private init() {
        super.init()
        
        if let storedState = AdTrackingPermissionState(rawValue: storedTrackingPermissionStateRaw) {
            trackingPermissionState = storedState
        }
        consentAndTrackingResolved = storedConsentAndTrackingResolved
        syncWithCurrentState()
    }
    
    // MARK: - SDK Initialization
    
    var shouldRenderAdViews: Bool {
        return shouldShowAds && adSDKInitialized
    }
    
    var shouldShowAds: Bool {
        // Assume ads are enabled for all users for now (no SubscriptionManager yet)
        return consentAndTrackingResolved
            && !ConsentManager.shared.userDeniedConsent
    }
    
    func syncWithCurrentState() {
        // If we had a SubscriptionManager, we'd check isSubscribed here
        let currentPermission = currentTrackingPermissionState()
        applyTrackingPermission(currentPermission, persist: true)
        
        if storedConsentAndTrackingResolved {
            consentAndTrackingResolved = true
            updateAdFlowState(using: currentPermission)
            initializeAdsIfNeeded()
        }
    }
    
    func initializeAdsIfNeeded() {
        guard !adSDKInitialized && !isInitializingAds else { 
            return 
        }
        isInitializingAds = true
        
        GADMobileAds.sharedInstance.start { _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.adSDKInitialized = true
                self.isInitializingAds = false
                
                self.startSessionGraceTimer()
                self.loadInterstitial()
                self.loadAppOpenAd()
                self.loadRewardedAd()
            }
        }
    }
    
    // MARK: - Privacy Flow
    
    func runConsentAndTrackingFlowIfNeeded() async {
        if storedConsentAndTrackingResolved {
            syncWithCurrentState()
            return
        }
        
        applyPendingState()
        
        await withCheckedContinuation { continuation in
            ConsentManager.shared.requestConsent { [weak self] _ in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                self.requestTrackingAuthorizationIfNeeded { [weak self] permission in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    Task { @MainActor in
                        self.consentAndTrackingResolved = true
                        self.storedConsentAndTrackingResolved = true
                        self.applyTrackingPermission(permission, persist: true)
                        self.updateAdFlowState(using: permission)
                        self.initializeAdsIfNeeded()
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    private func requestTrackingAuthorizationIfNeeded(completion: @escaping (AdTrackingPermissionState) -> Void) {
        let current = currentTrackingPermissionState()
        guard current == .notDetermined else {
            completion(current)
            return
        }
        
        // Ensure app is active
        if UIApplication.shared.applicationState != .active {
            NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        completion(Self.mapTrackingStatus(status))
                    }
                }
            }
            return
        }
        
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                completion(Self.mapTrackingStatus(status))
            }
        }
    }
    
    private func currentTrackingPermissionState() -> AdTrackingPermissionState {
        return Self.mapTrackingStatus(ATTrackingManager.trackingAuthorizationStatus)
    }
    
    private static func mapTrackingStatus(_ status: ATTrackingManager.AuthorizationStatus) -> AdTrackingPermissionState {
        switch status {
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .notDetermined: return .notDetermined
        @unknown default:    return .restricted
        }
    }
    
    private func applyTrackingPermission(_ permission: AdTrackingPermissionState, persist: Bool) {
        trackingPermissionState = permission
        if persist {
            storedTrackingPermissionStateRaw = permission.rawValue
        }
    }
    
    private func updateAdFlowState(using permission: AdTrackingPermissionState) {
        guard consentAndTrackingResolved else {
            adFlowState = .pendingConsentAndTracking
            return
        }
        
        if permission == .authorized && !ConsentManager.shared.userDeniedConsent {
            adFlowState = .freeUserTrackingAllowed
        } else {
            adFlowState = .freeUserTrackingDeniedOrRestricted
        }
    }
    
    private func applyPendingState() {
        consentAndTrackingResolved = false
        adFlowState = .pendingConsentAndTracking
        adSDKInitialized = false
        clearLoadedAds()
    }
    
    private func clearLoadedAds() {
        interstitial = nil
        rewardedAd = nil
        appOpenAd = nil
        appOpenAdLoadTime = nil
        onAdDismissed = nil
    }
    
    // MARK: - Banner Helpers
    
    func reportBannerSuccess() {
        guard !hasAnyBannerSucceeded else { return }
        hasAnyBannerSucceeded = true
        shouldShowBannersThisSession = true
        sessionGraceTimer?.invalidate()
        sessionGraceTimer = nil
    }
    
    private func startSessionGraceTimer() {
        shouldShowBannersThisSession = true
        hasAnyBannerSucceeded = false
        
        sessionGraceTimer?.invalidate()
        sessionGraceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if !self.hasAnyBannerSucceeded {
                    self.shouldShowBannersThisSession = false
                }
            }
        }
    }
    
    // MARK: - App Open Ad
    
    func loadAppOpenAd() {
        guard shouldShowAds else { return }
        
        AppOpenAd.load(withAdUnitID: AdUnitIDs.openApp, request: GADRequest()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                self.appOpenAdLoadTime = Date()
                self.reportBannerSuccess()
            }
        }
    }
    
    private func isAppOpenAdAvailable() -> Bool {
        guard let _ = appOpenAd, let loadTime = appOpenAdLoadTime else { return false }
        return Date().timeIntervalSince(loadTime) < (4 * 3600)
    }
    
    func maybeShowAppOpenAd(completion: @escaping () -> Void = {}) {
        guard shouldShowAds else {
            completion()
            return
        }
        
        resumeCount += 1
        if resumeCount % resumeFrequency == 0 {
            showAppOpenAd(completion: completion)
        } else {
            completion()
        }
    }
    
    private func showAppOpenAd(completion: @escaping () -> Void) {
        if isAppOpenAdAvailable() {
            if let topController = getTopViewController() {
                appOpenAd?.present(from: topController)
                self.onAdDismissed = completion
            } else {
                completion()
            }
        } else {
            loadAppOpenAd()
            completion()
        }
    }
    
    // MARK: - Interstitial
    
    func loadInterstitial() {
        guard shouldShowAds else { return }
        
        InterstitialAd.load(withAdUnitID: AdUnitIDs.interstitialGlobal, request: GADRequest()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
                self.reportBannerSuccess()
            }
        }
    }
    
    func maybeShowInterstitial(completion: @escaping () -> Void) {
        guard shouldShowAds else {
            completion()
            return
        }
        
        transactionCount += 1
        if transactionCount % transactionFrequency == 0 {
            showInterstitial(completion: completion)
        } else {
            completion()
        }
    }
    
    private func showInterstitial(completion: @escaping () -> Void) {
        if let ad = interstitial, let topController = getTopViewController() {
            ad.present(from: topController)
            self.onAdDismissed = completion
        } else {
            loadInterstitial()
            completion()
        }
    }
    
    // MARK: - Rewarded
    
    func loadRewardedAd() {
        guard shouldShowAds else { return }
        
        RewardedAd.load(withAdUnitID: AdUnitIDs.rewardedGame, request: GADRequest()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.reportBannerSuccess()
            }
        }
    }
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard shouldShowAds else {
            completion(true)
            return
        }
        
        if let ad = rewardedAd, let topController = getTopViewController() {
            var rewardEarned = false
            ad.present(from: topController) {
                rewardEarned = true
            }
            self.onAdDismissed = {
                completion(rewardEarned)
            }
        } else {
            loadRewardedAd()
            completion(false)
        }
    }
    
    // MARK: - Helper
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            return nil
        }
        
        func findTop(from base: UIViewController?) -> UIViewController? {
            if let nav = base as? UINavigationController { return findTop(from: nav.visibleViewController) }
            if let tab = base as? UITabBarController { return findTop(from: tab.selectedViewController) }
            if let presented = base?.presentedViewController { return findTop(from: presented) }
            return base
        }
        
        return findTop(from: root)
    }
}

// MARK: - FullScreenContentDelegate
extension AdsManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onAdDismissed?()
        onAdDismissed = nil
        
        if ad is AppOpenAd { loadAppOpenAd() }
        else if ad is RewardedAd { loadRewardedAd() }
        else { loadInterstitial() }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onAdDismissed?()
        onAdDismissed = nil
        if ad is AppOpenAd { loadAppOpenAd() }
        else if ad is RewardedAd { loadRewardedAd() }
        else { loadInterstitial() }
    }
}
