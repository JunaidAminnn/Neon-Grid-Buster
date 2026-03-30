//
//  SafariView.swift
//  GridBuster
//
//  A simple UIViewControllerRepresentable wrapper for SFSafariViewController
//  to open web links inside the app.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredBarTintColor = UIColor(red: 0x24/255, green: 0x00/255, blue: 0x21/255, alpha: 1.0)
        vc.preferredControlTintColor = .white
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
