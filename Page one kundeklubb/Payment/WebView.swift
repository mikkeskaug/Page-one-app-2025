//
//  WebView.swift
//  Testing Dintero API
//
//  Created by Service on 10/02/2025.
//

// WebView implementation for showing the payment page
@preconcurrency import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
    let url: URL
    var onPaymentCompletion: (Bool) -> Void // Callback for payment status

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString {
                print("🌐 Navigating to URL: \(url)")
                if url.contains("status=success") {
                    // Payment successful
                    parent.onPaymentCompletion(true)
                } else if url.contains("status=failure") {
                    // Payment failed
                    parent.onPaymentCompletion(false)
                }
            }
            decisionHandler(.allow)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        print("🌐 Loading URL in WebView: \(url)")
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
