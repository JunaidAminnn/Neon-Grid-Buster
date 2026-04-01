import UIKit

// MARK: - GoogleMobileAds Stubs

open class GADRequest: NSObject {
    public override init() { super.init() }
}

public typealias Request = GADRequest

open class GADBannerView: UIView {
    public var adUnitID: String?
    public var rootViewController: UIViewController?
    public weak var delegate: GADBannerViewDelegate?
    public init(adSize: GADAdSize) { super.init(frame: .zero) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
    open func load(_ request: GADRequest?) {
        // Mock success after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.delegate?.bannerViewDidReceiveAd?(self)
        }
    }
}

@objc public protocol GADBannerViewDelegate: NSObjectProtocol {
    @objc optional func bannerViewDidReceiveAd(_ bannerView: GADBannerView)
    @objc optional func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error)
}

public typealias BannerView = GADBannerView
public typealias BannerViewDelegate = GADBannerViewDelegate

public struct GADAdSize {
    public var size: CGSize
}

public func GADAdSizeFromCGSize(_ size: CGSize) -> GADAdSize {
    return GADAdSize(size: size)
}

public func GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(_ width: CGFloat) -> GADAdSize {
    return GADAdSize(size: CGSize(width: width, height: 50))
}

// Rewriting specific function used in BannerAdView.swift
public func largePortraitAnchoredAdaptiveBanner(width: CGFloat) -> GADAdSize {
    return GADAdSize(size: CGSize(width: width, height: 60))
}

open class GADFullScreenPresentingAd: NSObject {}
public typealias FullScreenPresentingAd = GADFullScreenPresentingAd

@objc public protocol GADFullScreenContentDelegate: NSObjectProtocol {
    @objc optional func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd)
    @objc optional func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error)
}

public typealias FullScreenContentDelegate = GADFullScreenContentDelegate

open class GADInterstitialAd: GADFullScreenPresentingAd {
    public weak var fullScreenContentDelegate: GADFullScreenContentDelegate?
    public static func load(withAdUnitID adUnitID: String, request: GADRequest?, completionHandler: @escaping (GADInterstitialAd?, Error?) -> Void) {
        completionHandler(GADInterstitialAd(), nil)
    }
    open func present(from viewController: UIViewController) {
        fullScreenContentDelegate?.adDidDismissFullScreenContent?(self)
    }
}

public typealias InterstitialAd = GADInterstitialAd

open class GADAppOpenAd: GADFullScreenPresentingAd {
    public weak var fullScreenContentDelegate: GADFullScreenContentDelegate?
    public static func load(withAdUnitID adUnitID: String, request: GADRequest?, completionHandler: @escaping (GADAppOpenAd?, Error?) -> Void) {
        completionHandler(GADAppOpenAd(), nil)
    }
    open func present(from viewController: UIViewController) {
        fullScreenContentDelegate?.adDidDismissFullScreenContent?(self)
    }
}

public typealias AppOpenAd = GADAppOpenAd

public struct GADAdReward {
    public var amount: NSDecimalNumber = 1
    public var type: String = "reward"
}

open class GADRewardedAd: GADFullScreenPresentingAd {
    public weak var fullScreenContentDelegate: GADFullScreenContentDelegate?
    public static func load(withAdUnitID adUnitID: String, request: GADRequest?, completionHandler: @escaping (GADRewardedAd?, Error?) -> Void) {
        completionHandler(GADRewardedAd(), nil)
    }
    open func present(from viewController: UIViewController, userDidEarnRewardHandler: @escaping () -> Void) {
        userDidEarnRewardHandler()
        fullScreenContentDelegate?.adDidDismissFullScreenContent?(self)
    }
}

public typealias RewardedAd = GADRewardedAd

open class GADMobileAds: NSObject {
    public static let sharedInstance = GADMobileAds()
    open func start(completionHandler: ((GADInitializationStatus) -> Void)? = nil) {
        completionHandler?(GADInitializationStatus())
    }
}

public typealias MobileAds = GADMobileAds

public class GADInitializationStatus: NSObject {}

// MARK: - UserMessagingPlatform Stubs

public class UMPRequestParameters: NSObject {}
public typealias RequestParameters = UMPRequestParameters

public class UMPConsentInformation: NSObject {
    public static let sharedInstance = UMPConsentInformation()
    public var canRequestAds: Bool = true
    public var consentStatus: UMPConsentStatus = .obtained
    public func requestConsentInfoUpdate(with parameters: UMPRequestParameters?, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
    public func reset() {}
}

public typealias ConsentInformation = UMPConsentInformation

public enum UMPConsentStatus: Int {
    case unknown = 0
    case required = 1
    case notRequired = 2
    case obtained = 3
}

public class UMPConsentForm: NSObject {
    public static func loadAndPresentIfRequired(from viewController: UIViewController?, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
}

public typealias ConsentForm = UMPConsentForm
