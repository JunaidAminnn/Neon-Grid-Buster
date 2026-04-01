import Foundation
import UserMessagingPlatform
import GoogleMobileAds
import UIKit

/// Enum to track user's consent decision for "Pay or Okay" model (if used)
enum ConsentStatus: String {
    case notDetermined
    case consented
    case denied
}

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
        let parameters = UMPRequestParameters()
        
        // 1. Request updated consent information
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                #if DEBUG
                print("AdMob: Consent update error: \(error.localizedDescription)")
                #endif
                DispatchQueue.main.async {
                    self.canRequestAds = true
                    self.consentStatus = .consented
                    self.saveConsentStatus()
                    self.consentGatheringComplete = true
                    completion(.consented)
                }
                return
            }
            
            // 2. Load and present the consent form if required
            UMPConsentForm.loadAndPresentIfRequired(from: viewController) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    #if DEBUG
                    print("AdMob: Consent form error: \(error.localizedDescription)")
                    #endif
                }
                
                DispatchQueue.main.async {
                    let status = self.determineConsentStatus()
                    self.consentStatus = status
                    self.saveConsentStatus()
                    
                    if UMPConsentInformation.sharedInstance.canRequestAds {
                        self.canRequestAds = true
                    }
                    
                    self.consentGatheringComplete = true
                    completion(status)
                }
            }
        }
    }
    
    private func determineConsentStatus() -> ConsentStatus {
        let consentInfo = UMPConsentInformation.sharedInstance
        
        if consentInfo.canRequestAds {
            return .consented
        }
        
        if consentInfo.consentStatus == .required {
            return .denied
        }
        
        if consentInfo.consentStatus == .notRequired || consentInfo.consentStatus == .obtained {
            return .consented
        }
        
        return .notDetermined
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
        UMPConsentInformation.sharedInstance.reset()
        consentStatus = .notDetermined
        canRequestAds = false
        consentGatheringComplete = false
        UserDefaults.standard.removeObject(forKey: consentStatusKey)
    }
    #endif
}
