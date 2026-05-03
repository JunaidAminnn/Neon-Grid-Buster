# 🌌 Neon Grid Buster

A high-intensity, neon-themed arcade experience for iOS. Featuring classic gameplay mechanics reimagined with premium aesthetics, glassmorphism, and dynamic animations.

---

## 🚀 Getting Started

To keep the project secure, sensitive configuration files (like Firebase and AdMob IDs) are excluded from this repository. To run the project locally, you will need to provide your own configuration.

### 📋 Prerequisites
- **Xcode 15.0+**
- **iOS 17.0+**
- **Swift 5.9+**

### 🛠 Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/JunaidAminnn/Neon-Grid-Buster.git
   cd Neon-Grid-Buster
   ```

2. **Add Firebase Configuration:**
   - Create a project in the [Firebase Console](https://console.firebase.google.com/).
   - Add an iOS app with the bundle ID `com.mediatownapp.GridBuster`.
   - Download the `GoogleService-Info.plist` and place it in:
     `GridBuster/Core/Firebase/GoogleService-Info.plist`

3. **Configure AdMob:**
   - Create an `AdsManager.swift` file in:
     `GridBuster/Core/AdMob/AdsManager.swift`
   - You can use the template below or your own AdMob IDs:

   ```swift
   import SwiftUI
   import GoogleMobileAds
   // ... Add necessary AdsManager implementation ...
   ```

4. **Build and Run:**
   - Open `NeonGridBuster.xcodeproj` in Xcode.
   - Select your target device and press `Cmd + R`.

---

## 🛡 Security Note

This repository uses a `.gitignore` to prevent leaking sensitive API keys. **Never commit your `GoogleService-Info.plist` or real AdMob Unit IDs** to a public repository. If you accidentally expose a secret, rotate it immediately in your respective developer console.

---

## 🎨 Design Philosophy

Neon Grid Buster is built with a **Cyberpunk-inspired aesthetic**:
- **Vibrant Neon Palettes**: High-contrast Cyan, Pink, and Lime glows.
- **Glassmorphism**: Semi-transparent UI elements with heavy background blurs.
- **Micro-animations**: Dynamic haptic and visual feedback for every interaction.

---

## 📄 License

This project is for demonstration purposes. All rights reserved.
