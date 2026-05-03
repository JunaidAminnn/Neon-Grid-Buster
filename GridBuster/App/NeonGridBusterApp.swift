//
//  NeonGridBusterApp.swift
//  NeonGridBuster
//
//  Created by Junaid Amin on 19/03/2026.
//

import SwiftUI
import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("Firebase: Starting initialization...")
        
        // Check if GoogleService-Info.plist exists
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("Firebase: GoogleService-Info.plist found at \(path)")
            FirebaseApp.configure()
            print("Firebase: Configuration successful. App Name: \(FirebaseApp.app()?.name ?? "Unknown")")
        } else {
            print("Firebase ERROR: GoogleService-Info.plist MISSING! Firebase will not work.")
        }
        
        // Initialize AdMob SDK
        print("AdMob: Initializing via AppDelegate...")
        AdsManager.shared.initialize()
        
        return true
    }
}

@main
struct NeonGridBusterApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIHostingController<MainMenuView>.self]).backgroundColor = .black
        UIView.appearance(whenContainedInInstancesOf: [UIHostingController<GameView>.self]).backgroundColor = .black
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Near-black base so no white flash during transitions
                Color(red: 0x00 / 255.0, green: 0x01 / 255.0, blue: 0x05 / 255.0)
                    .ignoresSafeArea()

                // Entry point: studio splash → auto-transitions to MainMenuView
                StudioSplashView()
            }
            .tint(Theme.Palette.neonCyan)
            .preferredColorScheme(.dark)
        }
    }
}
