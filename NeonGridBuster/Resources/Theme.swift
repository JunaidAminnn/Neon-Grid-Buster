//
//  Theme.swift
//  NeonGridBuster
//
//  Neon Midnight design system for Neon Grid Buster.
//

import SwiftUI
import SpriteKit

enum Theme {
    enum Palette {
        static let midnight = Color(red: 0x0B / 255, green: 0x0C / 255, blue: 0x10 / 255)
        static let midnightDeep = Color(red: 0x07 / 255, green: 0x08 / 255, blue: 0x0B / 255)
        static let tile = Color.white.opacity(0.06)
        static let tileStroke = Color.white.opacity(0.10)

        static let arcadeBlueTop = Color(red: 0x0A / 255, green: 0x2D / 255, blue: 0xC9 / 255)
        static let arcadeBlueBottom = Color(red: 0x10 / 255, green: 0x7D / 255, blue: 0xF2 / 255)
        static let arcadePanel = Color(red: 0x12 / 255, green: 0x2E / 255, blue: 0x82 / 255).opacity(0.55)

        static let neonCyan = Color(red: 0x00 / 255, green: 0xF5 / 255, blue: 0xFF / 255)
        static let neonPurple = Color(red: 0xBF / 255, green: 0x00 / 255, blue: 0xFF / 255)
        static let neonPink = Color(red: 0xFF / 255, green: 0x4F / 255, blue: 0xD8 / 255)
        static let neonLime = Color(red: 0x39 / 255, green: 0xFF / 255, blue: 0x14 / 255)
        static let neonYellow = Color(red: 0xFF / 255, green: 0xF0 / 255, blue: 0x1F / 255)
        static let neonRed = Color(red: 0xFF / 255, green: 0x2D / 255, blue: 0x2D / 255)
        static let neonOrange = Color(red: 0xFF / 255, green: 0x8A / 255, blue: 0x00 / 255)
        static let neonBlue = Color(red: 0x2F / 255, green: 0x6B / 255, blue: 0xFF / 255)
        static let neonIce = Color(red: 0x6D / 255, green: 0xF0 / 255, blue: 0xFF / 255)

        static let goldLight = Color(red: 0xFF / 255, green: 0xE5 / 255, blue: 0x7A / 255)
        static let goldDeep = Color(red: 0xFF / 255, green: 0xB7 / 255, blue: 0x1A / 255)

        static let textPrimary = Color.white.opacity(0.95)
        static let textSecondary = Color.white.opacity(0.70)
    }

    enum Fonts {
        static func display(_ size: CGFloat) -> Font { .custom("Outfit-SemiBold", size: size) }
        static func title(_ size: CGFloat) -> Font { .custom("Outfit-Bold", size: size) }
        static func body(_ size: CGFloat) -> Font { .custom("Inter-Regular", size: size) }
        static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
        static func arcade(_ size: CGFloat) -> Font { .system(size: size, weight: .black, design: .rounded) }
    }

    static func neonColor(_ color: NeonColor) -> Color {
        switch color {
        case .cyan: return Palette.neonCyan
        case .purple: return Palette.neonPurple
        case .pink: return Palette.neonPink
        case .lime: return Palette.neonLime
        case .yellow: return Palette.neonYellow
        case .red: return Palette.neonRed
        case .orange: return Palette.neonOrange
        case .blue: return Palette.neonBlue
        case .ice: return Palette.neonIce
        }
    }
}

struct NeonBackgroundView: View {
    var body: some View {
        ZStack {
            Theme.Palette.midnight
                .ignoresSafeArea()

            ZStack {
                RadialGradient(colors: [
                    Theme.Palette.neonPurple.opacity(0.18),
                    .clear
                ], center: .topLeading, startRadius: 0, endRadius: 420)

                RadialGradient(colors: [
                    Theme.Palette.neonCyan.opacity(0.16),
                    .clear
                ], center: .topTrailing, startRadius: 0, endRadius: 420)

                RadialGradient(colors: [
                    Theme.Palette.neonPink.opacity(0.12),
                    .clear
                ], center: .bottomLeading, startRadius: 0, endRadius: 520)

                RadialGradient(colors: [
                    Theme.Palette.neonLime.opacity(0.10),
                    .clear
                ], center: .bottomTrailing, startRadius: 0, endRadius: 520)
            }
            .blendMode(.plusLighter)
            .opacity(0.85)
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Theme.Palette.midnightDeep.opacity(0.55),
                    .clear,
                    Theme.Palette.midnightDeep.opacity(0.70),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct ArcadeBlueBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.Palette.arcadeBlueTop, Theme.Palette.arcadeBlueBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.10), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 520
            )
            .blendMode(.softLight)
        )
        .overlay(
            LinearGradient(
                colors: [Color.black.opacity(0.15), .clear, Color.black.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
    }
}

enum NeonColor: String, CaseIterable, Hashable, Codable {
    case cyan
    case purple
    case pink
    case lime
    case yellow
    case red
    case orange
    case blue
    case ice
}

extension Color {
    init(red: Int, green: Int, blue: Int) {
        self.init(red: Double(red) / 255.0, green: Double(green) / 255.0, blue: Double(blue) / 255.0)
    }
}

extension SKColor {
    static func neon(_ color: NeonColor) -> SKColor {
        switch color {
        case .cyan: return SKColor(red: 0x00 / 255, green: 0xF5 / 255, blue: 0xFF / 255, alpha: 1)
        case .purple: return SKColor(red: 0xBF / 255, green: 0x00 / 255, blue: 0xFF / 255, alpha: 1)
        case .pink: return SKColor(red: 0xFF / 255, green: 0x4F / 255, blue: 0xD8 / 255, alpha: 1)
        case .lime: return SKColor(red: 0x39 / 255, green: 0xFF / 255, blue: 0x14 / 255, alpha: 1)
        case .yellow: return SKColor(red: 0xFF / 255, green: 0xF0 / 255, blue: 0x1F / 255, alpha: 1)
        case .red: return SKColor(red: 0xFF / 255, green: 0x2D / 255, blue: 0x2D / 255, alpha: 1)
        case .orange: return SKColor(red: 0xFF / 255, green: 0x8A / 255, blue: 0x00 / 255, alpha: 1)
        case .blue: return SKColor(red: 0x2F / 255, green: 0x6B / 255, blue: 0xFF / 255, alpha: 1)
        case .ice: return SKColor(red: 0x6D / 255, green: 0xF0 / 255, blue: 0xFF / 255, alpha: 1)
        }
    }
}
