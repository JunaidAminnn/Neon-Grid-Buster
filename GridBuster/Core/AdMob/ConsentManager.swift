import Foundation
import UserMessagingPlatform
import UIKit
import Combine

/// Enum to track user's consent decision
enum ConsentStatus: String {
    case notDetermined
    case consented
    case denied
}

@MainActor
class ConsentManager: ObservableObject {
    static let shared = ConsentManager()
    
    @Published var canRequestAds: Bool = false
    @Published var consentGatheringComplete: Bool = false
    
    private init() {
        // UMP manages its own persistence, but we track canRequestAds for UI convenience
        self.canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds
    }
    
    var userDeniedConsent: Bool {
        // In UMP, we check if we can request ads. If not, it could be denied or not yet gathered.
        return consentGatheringComplete && !UMPConsentInformation.sharedInstance.canRequestAds
    }
    
    func requestConsent(from viewController: UIViewController? = nil, completion: @escaping (String) -> Void) {
        let parameters = UMPRequestParameters()
        
        // For testing in non-EU regions, you can use debug settings:
        /*
        let debugSettings = UMPDebugSettings()
        debugSettings.geography = .EEA
        debugSettings.testDeviceIdentifiers = ["YOUR_TEST_DEVICE_ID"]
        parameters.debugSettings = debugSettings
        */
        
        // tagForUnderAgeOfConsent is handled by UMP automatically or via different params in newer SDKs
        
        print("UMP: Requesting consent info update...")
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("UMP: Error updating consent info: \(error.localizedDescription)")
                completion("Error: \(error.localizedDescription)")
                return
            }
            
            print("UMP: Consent info updated.")
            
            UMPConsentForm.loadAndPresentIfRequired(from: viewController ?? self.getTopViewController()) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("UMP: Error loading/presenting form: \(error.localizedDescription)")
                }
                
                self.canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds
                self.consentGatheringComplete = true
                
                print("UMP: Flow complete. Can request ads: \(self.canRequestAds)")
                completion(self.canRequestAds ? "Consented/NotRequired" : "Denied/Restricted")
            }
        }
    }
    
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
    
    #if DEBUG
    func resetConsent() {
        UMPConsentInformation.sharedInstance.reset()
        canRequestAds = false
        consentGatheringComplete = false
        print("UMP: Consent RESET for debugging.")
    }
    #endif
}
