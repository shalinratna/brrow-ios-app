//
//  BrrowAdminApp.swift
//  BrrowAdmin
//
//  Brrow Admin Panel - macOS Database & User Management
//

import SwiftUI

@main
struct BrrowAdminApp: App {
    @StateObject private var authManager = AdminAuthManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                AdminContentView()
                    .frame(minWidth: 1200, minHeight: 800)
            } else {
                AdminLoginView()
                    .frame(width: 500, height: 600)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        Settings {
            AdminSettingsView()
        }
    }
}
