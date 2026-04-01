import Foundation
// import UserMessagingPlatform
// import GoogleMobileAds
import UIKit
import Combine

/// Enum to track user's consent decision for "Pay or Okay" model (if used)
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
    @Published var consentStatus: ConsentStatus = .notDetermined
    
    private let consentStatusKey = "user_consent_status"
    
    private init() {
        loadConsentStatus()
    }
    
    var userConsentedToAds: Bool {
        return consentStatus == .consented
    }
    
    var userDeniedConsent: Bool {
        return consentStatus == .denied
    }
    
    func requestConsent(from viewController: UIViewController? = nil, completion: @escaping (ConsentStatus) -> Void) {
        #if DEBUG
        print("AdMob: Consent requested (MOCKED)")
        #endif
        
        // Mocking successful consent info update and form presentation
        DispatchQueue.main.async {
            self.canRequestAds = true
            self.consentStatus = .consented
            self.saveConsentStatus()
            self.consentGatheringComplete = true
            completion(.consented)
        }
    }
    
    private func saveConsentStatus() {
        UserDefaults.standard.set(consentStatus.rawValue, forKey: consentStatusKey)
    }
    
    private func loadConsentStatus() {
        if let savedStatus = UserDefaults.standard.string(forKey: consentStatusKey),
           let status = ConsentStatus(rawValue: savedStatus) {
            self.consentStatus = status
        }
    }
    
    #if DEBUG
    func resetConsent() {
        consentStatus = .notDetermined
        canRequestAds = false
        consentGatheringComplete = false
        UserDefaults.standard.removeObject(forKey: consentStatusKey)
    }
    #endif
}
