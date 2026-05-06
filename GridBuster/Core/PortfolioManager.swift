//
//  PortfolioManager.swift
//  NeonGridBuster
//
//  Created by Antigravity on 06/05/2026.
//

import Foundation
import Combine

struct PortfolioApp: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let iconURL: String
    let rating: Double
    let ratingCount: Int
    let artistName: String
    let url: String
    let genres: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case name = "trackName"
        case iconURL = "artworkUrl100"
        case rating = "averageUserRating"
        case ratingCount = "userRatingCount"
        case artistName
        case url = "trackViewUrl"
        case genres
    }
}

@MainActor
class PortfolioManager: ObservableObject {
    static let shared = PortfolioManager()
    
    @Published var apps: [PortfolioApp] = []
    @Published var isLoading = false
    
    private let cacheKey = "com.neongridbuster.portfolio.cache"
    private let lastUpdateKey = "com.neongridbuster.portfolio.lastUpdate"
    
    private init() {
        loadFromCache()
    }
    
    func fetchPortfolio() {
        // If we already have apps, don't show loading unless it's a forced refresh
        if apps.isEmpty { isLoading = true }
        
        let ids = AppConfig.promotedAppIDs.joined(separator: ",")
        let urlString = "https://itunes.apple.com/lookup?id=\(ids)&country=us&entity=software"
        
        guard let url = URL(string: urlString) else {
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("[Portfolio] ❌ Fetch error: \(error?.localizedDescription ?? "Unknown")")
                Task { @MainActor in
                    self.isLoading = false
                }
                return
            }
            
            do {
                let result = try JSONDecoder().decode(iTunesLookupResult.self, from: data)
                
                Task { @MainActor in
                    self.apps = result.results
                    self.saveToCache()
                    self.isLoading = false
                    print("[Portfolio] ✅ Fetched \(result.results.count) apps.")
                }
            } catch {
                print("[Portfolio] ❌ Decode error: \(error)")
                Task { @MainActor in
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func saveToCache() {
        if let data = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUpdateKey)
        }
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedApps = try? JSONDecoder().decode([PortfolioApp].self, from: data) {
            self.apps = cachedApps
            print("[Portfolio] 📁 Loaded \(apps.count) apps from cache.")
        }
    }
}

// Internal Apple models
private struct iTunesLookupResult: Codable, Sendable {
    let results: [PortfolioApp]
}
