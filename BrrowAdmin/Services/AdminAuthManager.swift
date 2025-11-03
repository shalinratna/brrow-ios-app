//
//  AdminAuthManager.swift
//  BrrowAdmin
//
//  Handles admin authentication state
//

import Foundation
import SwiftUI

@MainActor
class AdminAuthManager: ObservableObject {
    static let shared = AdminAuthManager()

    @Published var isAuthenticated = false
    @Published var currentAdmin: AdminUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
        // Check if we have a stored token
        if KeychainManager.shared.getAdminToken() != nil {
            Task {
                await verifyToken()
            }
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AdminAPIClient.shared.login(email: email, password: password)
            self.currentAdmin = response.admin
            self.isAuthenticated = true
            print("✅ Admin logged in: \(response.admin.email)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Login failed: \(error)")
        }

        isLoading = false
    }

    func logout() {
        AdminAPIClient.shared.logout()
        currentAdmin = nil
        isAuthenticated = false
    }

    private func verifyToken() async {
        do {
            let admin = try await AdminAPIClient.shared.getCurrentAdmin()
            self.currentAdmin = admin
            self.isAuthenticated = true
        } catch {
            // Token invalid, clear it
            logout()
        }
    }
}
