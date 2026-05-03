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
        FirebaseApp.configure()
        
        // Initialize AdMob SDK
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
