//
//  WebView.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import SwiftUI
import WebKit

/// In-app webview to display EULA
struct WebView: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

