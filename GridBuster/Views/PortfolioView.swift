//
//  PortfolioView.swift
//  NeonGridBuster
//
//  Created by Antigravity on 06/05/2026.
//

import SwiftUI
import StoreKit

// MARK: - StoreKitView
/// A wrapper for SKStoreProductViewController to show App Store listings in-app.
struct StoreKitView: UIViewControllerRepresentable {
    let appID: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if uiViewController.presentedViewController == nil {
            let storeViewController = SKStoreProductViewController()
            storeViewController.delegate = context.coordinator
            
            let parameters = [SKStoreProductParameterITunesItemIdentifier: appID]
            storeViewController.loadProduct(withParameters: parameters) { (result, error) in
                if result {
                    uiViewController.present(storeViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SKStoreProductViewControllerDelegate {
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - PromotedAppRow
struct PromotedAppRow: View {
    let app: PortfolioApp
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // App Icon
                AsyncImage(url: URL(string: app.iconURL)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(ProgressView().tint(.white.opacity(0.5)))
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0, green: 1, blue: 1), Color(red: 1, green: 0, blue: 1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                            Text(String(format: "%.1f", app.rating))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.yellow)
                        
                        Text("•")
                            .foregroundStyle(.white.opacity(0.3))
                        
                        Text(app.genres.first ?? "Game")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Get Button - Matching Utility Button Style
                Text("GET")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(red: 0, green: 0.8, blue: 1).opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0, green: 0.8, blue: 1).opacity(0.8), lineWidth: 2.2)
                    )
                    .shadow(color: Color(red: 0, green: 0.8, blue: 1).opacity(0.35), radius: 8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PortfolioScaleButtonStyle())
    }
}

// MARK: - PortfolioScaleButtonStyle
struct PortfolioScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
