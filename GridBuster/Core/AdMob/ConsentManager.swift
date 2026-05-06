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
        // ConsentInformation manages its own persistence, but we track canRequestAds for UI convenience
        self.canRequestAds = ConsentInformation.shared.canRequestAds
    }
    
    var userDeniedConsent: Bool {
        // In UMP, we check if we can request ads. If not, it could be denied or not yet gathered.
        return consentGatheringComplete && !ConsentInformation.shared.canRequestAds
    }
    
    func requestConsent(from viewController: UIViewController? = nil, completion: @escaping (String) -> Void) {
        let parameters = RequestParameters()
        
        // tagForUnderAgeOfConsent is handled by UMP automatically or via different params in newer SDKs
        
        Task { @MainActor in
            do {
                print("UMP: Requesting consent info update...")
                try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
                print("UMP: Consent info updated.")
                
                let vc = viewController ?? self.getTopViewController()
                try await ConsentForm.loadAndPresentIfRequired(from: vc)
                
                self.canRequestAds = ConsentInformation.shared.canRequestAds
                self.consentGatheringComplete = true
                
                print("UMP: Flow complete. Can request ads: \(self.canRequestAds)")
                completion(self.canRequestAds ? "Consented/NotRequired" : "Denied/Restricted")
                
            } catch {
                print("UMP: Error: \(error.localizedDescription)")
                
                // Even on error, update states just in case consent was already gathered previously
                self.canRequestAds = ConsentInformation.shared.canRequestAds
                self.consentGatheringComplete = true
                completion("Error: \(error.localizedDescription)")
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
        ConsentInformation.shared.reset()
        canRequestAds = false
        consentGatheringComplete = false
        print("UMP: Consent RESET for debugging.")
    }
    #endif
}
