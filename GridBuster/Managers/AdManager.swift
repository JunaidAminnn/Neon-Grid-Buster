//
//  AdManager.swift
//  GridBuster
//
//  Centralized Ad management for Neon Grid Buster.
//

import GoogleMobileAds
import SwiftUI

class AdManager {
    static let shared = AdManager()
    
    private init() {}
    
    struct AdUnits {
        #if DEBUG
        // Standard Google Test IDs for iOS
        static let bannerGlobal = "ca-app-pub-3940256099942544/2934735716"
        static let interstitialGlobal = "ca-app-pub-3940256099942544/4411468910"
        static let openApp = "ca-app-pub-3940256099942544/5662855259"
        static let rewardedGame = "ca-app-pub-3940256099942544/1712485313"
        static let rewardedGlobal = "ca-app-pub-3940256099942544/1712485313"
        #else
        // Real AdMob IDs from dashboard
        static let bannerGlobal = "ca-app-pub-7248360860042690/6799555717"
        static let interstitialGlobal = "ca-app-pub-7248360860042690/4002001983"
        static let openApp = "ca-app-pub-7248360860042690/9017487531"
        static let rewardedGame = "ca-app-pub-7248360860042690/5294902350"
        static let rewardedGlobal = "ca-app-pub-7248360860042690/8634344153"
        #endif
    }
    
    // MARK: - Initialization
    
    func initialize() {
        GADMobileAds.sharedInstance.start(completionHandler: nil)
    }
    
    // MARK: - Helper Methods
    
    // Future expansion for loading/showing ads can be added here
    // Example: func loadInterstitial() { ... }
}
