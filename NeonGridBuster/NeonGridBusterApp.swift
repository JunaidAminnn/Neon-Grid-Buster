//
//  NeonGridBusterApp.swift
//  NeonGridBuster
//
//  Created by Junaid Amin   on 19/03/2026.
//

import SwiftUI

@main
struct NeonGridBusterApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .tint(Theme.Palette.neonCyan)
        }
    }
}
