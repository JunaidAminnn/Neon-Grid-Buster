//
//  NeonGridBusterApp.swift
//  NeonGridBuster
//
//  Created by Junaid Amin   on 19/03/2026.
//

import SwiftUI
import UIKit

@main
struct NeonGridBusterApp: App {
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIHostingController<MainMenuView>.self]).backgroundColor = .black
        UIView.appearance(whenContainedInInstancesOf: [UIHostingController<GameView>.self]).backgroundColor = .black
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Palette.midnight
                    .ignoresSafeArea()

                MainMenuView()
            }
            .tint(Theme.Palette.neonCyan)
            .preferredColorScheme(.dark)
        }
    }
}
