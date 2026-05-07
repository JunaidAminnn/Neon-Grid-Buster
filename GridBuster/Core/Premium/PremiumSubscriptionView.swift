//
//  PremiumSubscriptionView.swift
//  NeonGridBuster
//

import SwiftUI

enum SubscriptionPlan {
    case monthly
    case annual
    case lifetime
}

struct PremiumSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var canDismiss = false
    @State private var safariItem: URLItem? = nil

    struct URLItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        ZStack {
            // Background
            PremiumBackground()

            VStack(spacing: 0) {
                // Top Navigation
                PremiumHeader()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Hero Section
                            PremiumHero()

                            // Feature List
                            PremiumFeatureList()

                            // Pricing Plans
                            PremiumPricingPlans(selectedPlan: $selectedPlan)
                                .id("plans")

                            // Global CTA
                            PremiumCTA()
                            
                            // Footer
                            PremiumFooter(
                                canDismiss: canDismiss,
                                dismissAction: { dismiss() },
                                openSafari: { url in
                                    if let targetURL = URL(string: url) {
                                        self.safariItem = URLItem(url: targetURL)
                                    }
                                }
                            )
                            .id("footer")
                        }
                        .padding(.horizontal, 24) // Added more padding
                        .padding(.vertical, 24)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                proxy.scrollTo("plans", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    canDismiss = true
                }
            }
        }
    }
}

// MARK: - Background

private struct PremiumBackground: View {
    var body: some View {
        ZStack {
            // Radial Gradient
            RadialGradient(
                colors: [
                    Color(red: 0x1A / 255.0, green: 0x0B / 255.0, blue: 0x2E / 255.0),
                    Color(red: 0x05 / 255.0, green: 0x01 / 255.0, blue: 0x0A / 255.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Grid Pattern Overlay
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 32
                    for x in stride(from: 0, through: geo.size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, through: geo.size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color(red: 1, green: 0, blue: 1).opacity(0.1), lineWidth: 1)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Header

private struct PremiumHeader: View {
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)

            Text("NEON GRID BUSTER")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0.67, blue: 0.95)) // Light Pink
                .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.8), radius: 8)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .overlay(
                    GeometryReader { geo in
                        Color.white.opacity(0.5)
                            .mask(
                                Rectangle()
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [.clear, .white, .clear]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: geo.size.width * 2)
                                    .offset(x: shimmerPhase * geo.size.width * 2 - geo.size.width)
                            )
                    }
                    .mask(
                        Text("NEON GRID BUSTER")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    )
                )
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.2))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(red: 1, green: 0, blue: 1).opacity(0.4)),
            alignment: .bottom
        )
    }
}

// MARK: - Hero Section

private struct PremiumHero: View {
    var body: some View {
        VStack(spacing: 20) {
            // Mascot Image
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.1).opacity(0.4))
                    .frame(width: 220, height: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 1, green: 0, blue: 1).opacity(0.3), lineWidth: 1)
                    )

                Image("premium_hero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .opacity(0.95)
            }
            .padding(.top, 8)

            // Value Prop
            VStack(spacing: 12) {
                Text("LEVEL UP YOUR EXPERIENCE")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .white.opacity(0.5), radius: 8)

                Text("Unlock the ultimate edition and bust grids with a completely ad-free experience.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
        }
    }
}

// MARK: - Feature List

private struct PremiumFeatureList: View {
    let features = [
        "No interstitial or banner ads",
        "Unlimited continues in Adventure mode",
        "Support the developer"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.17, green: 0.9, blue: 0.0).opacity(0.2)) // Green tint
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(Color(red: 0.17, green: 0.9, blue: 0.0), lineWidth: 1.5)
                            )
                            .shadow(color: Color(red: 0.17, green: 0.9, blue: 0.0).opacity(0.8), radius: 6)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(red: 0.47, green: 1.0, blue: 0.35)) // Light green
                    }

                    Text(feature)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Pricing Plans

private struct PremiumPricingPlans: View {
    @Binding var selectedPlan: SubscriptionPlan

    var body: some View {
        VStack(spacing: 16) {
            // Monthly
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedPlan = .monthly
                }
            }) {
                PricingCard(
                    title: "Monthly",
                    subtitle: "Billed every month",
                    price: "$0.99",
                    badge: "RECURRENT",
                    isSelected: selectedPlan == .monthly
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Annually (Best Value)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedPlan = .annual
                }
            }) {
                PricingCard(
                    title: "Annually",
                    subtitle: "Save 15% yearly",
                    price: "$9.99",
                    badge: "MOST POPULAR",
                    isSelected: selectedPlan == .annual,
                    topBadge: "BEST VALUE"
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Lifetime
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedPlan = .lifetime
                }
            }) {
                PricingCard(
                    title: "Lifetime",
                    subtitle: "Pay once, own forever",
                    price: "$19.99",
                    badge: "ONE-TIME",
                    isSelected: selectedPlan == .lifetime
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

private struct PricingCard: View {
    let title: String
    let subtitle: String
    let price: String
    let badge: String
    let isSelected: Bool
    var topBadge: String? = nil

    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(price)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                    
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1)
                }
            }
            .padding(24)
            .background(isSelected ? Color(red: 0.8, green: 0, blue: 1).opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(red: 0.8, green: 0, blue: 1) : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: isSelected ? Color(red: 0.8, green: 0, blue: 1).opacity(0.5) : .clear, radius: 12)

            if let topBadge = topBadge {
                Text(topBadge)
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(red: 1, green: 0, blue: 1))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color(red: 1, green: 0, blue: 1), radius: 6)
                    .offset(y: -14)
            }
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// MARK: - Global CTA

private struct PremiumCTA: View {
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        VStack(spacing: 16) {
            Button(action: { /* Process Subscription */ }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 1, green: 0, blue: 1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 1, green: 0.67, blue: 0.95), lineWidth: 2) // Light pink border
                        )
                    
                    // Shimmer Effect
                    GeometryReader { geo in
                        Color.white.opacity(0.4)
                            .mask(
                                Rectangle()
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [.clear, .white, .clear]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: geo.size.width * 2)
                                    .offset(x: shimmerPhase * geo.size.width * 2 - geo.size.width)
                            )
                    }

                    HStack(spacing: 12) {
                        Text("SUBSCRIBE NOW")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .italic()
                            .tracking(2)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundStyle(.white)
                }
                .frame(height: 70)
                .shadow(color: Color(red: 1, green: 0, blue: 1).opacity(0.9), radius: 16)
            }
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }

            Text("CANCEL ANYTIME • SECURE PAYMENT")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(1.5)
        }
        .padding(.top, 10)
    }
}

// MARK: - Footer

private struct PremiumFooter: View {
    let canDismiss: Bool
    let dismissAction: () -> Void
    let openSafari: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Button("Terms of Use") {
                    openSafari(AppConfig.termsOfUseURL)
                }
                Text("•").foregroundStyle(.white.opacity(0.3))
                Button("Privacy Policy") {
                    openSafari(AppConfig.privacyPolicyURL)
                }
                Text("•").foregroundStyle(.white.opacity(0.3))
                Button("Restore Purchase") {
                    // Placeholder for IAP restore logic
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            // Proper "Maybe Later" Button
            Button(action: {
                if canDismiss { dismissAction() }
            }) {
                Text("MAYBE LATER")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(canDismiss ? .white : .gray)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(canDismiss ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(canDismiss ? Color.white.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }
            .disabled(!canDismiss)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    PremiumSubscriptionView()
}
