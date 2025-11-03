//
//  BrrowDBApp.swift
//  Brrow Database Manager - Native macOS App
//
//  Standalone database manager - no browser needed!
//

import SwiftUI
import WebKit

@main
struct BrrowDBApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            DatabaseBrowserView()
                .frame(minWidth: 1400, minHeight: 900)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start Prisma Studio in background if not running
        startPrismaStudio()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func startPrismaStudio() {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "cd /Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend && npx prisma studio > /dev/null 2>&1 &"]

        do {
            try task.run()
            print("✅ Prisma Studio started automatically")
        } catch {
            print("⚠️ Could not auto-start Prisma Studio: \(error)")
        }
    }
}

struct DatabaseBrowserView: View {
    @State private var isLoading = true
    @State private var showError = false

    var body: some View {
        ZStack {
            WebView(url: URL(string: "http://localhost:5555")!, isLoading: $isLoading, showError: $showError)

            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading Database...")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }

            if showError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("Database Manager Not Running")
                        .font(.title)
                        .bold()

                    Text("Starting database manager...")
                        .foregroundColor(.secondary)

                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()

                    Text("This will take 3-5 seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
}

struct WebView: NSViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var showError: Bool

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true

        // Custom user agent to identify as native app
        webView.customUserAgent = "BrrowDB/1.0 (Macintosh; Intel Mac OS X)"

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var retryCount = 0
        var retryTimer: Timer?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.showError = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.showError = false
            retryCount = 0
            retryTimer?.invalidate()
            print("✅ Database browser loaded successfully")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(webView: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(webView: webView)
        }

        private func handleError(webView: WKWebView) {
            parent.isLoading = false
            parent.showError = true

            // Auto-retry with exponential backoff
            if retryCount < 6 {
                let delay = Double(retryCount + 1) * 1.0 // 1s, 2s, 3s, 4s, 5s, 6s
                retryCount += 1

                print("⏳ Waiting for database manager... (attempt \(retryCount)/6)")

                retryTimer?.invalidate()
                retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    print("🔄 Retrying connection...")
                    let request = URLRequest(url: self.parent.url)
                    webView.load(request)
                }
            } else {
                parent.showError = true
                print("❌ Could not connect to database manager after 6 attempts")
            }
        }
    }
}

#Preview {
    DatabaseBrowserView()
        .frame(width: 1400, height: 900)
}
