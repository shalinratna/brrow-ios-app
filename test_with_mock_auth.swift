// Test code to simulate logged-in user for MyPostsView testing
// Add this temporarily to BrrowApp.swift or a test view

import SwiftUI

struct TestAuthButton: View {
    var body: some View {
        Button("Mock Login as Mom") {
            Task {
                // Create a mock user
                let mockUser = User(
                    id: 9,
                    apiId: "usr_687b4d8b25f075.49510878",
                    email: "mom@brrowapp.com",
                    username: "mom",
                    profilePicture: nil,
                    verified: false,
                    createdAt: Date()
                )
                
                // Set the mock token
                let mockToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo5LCJhcGlfaWQiOiJ1c3JfNjg3YjRkOGIyNWYwNzUuNDk1MTA4NzgiLCJlbWFpbCI6Im1vbUBicnJvd2FwcC5jb20iLCJleHAiOjE3NTQ2ODYyMzMsImlhdCI6MTc1NDA4MTQzM30.dJvhJcUWWXYxHGkJyJl4bvhqILIXxrOV3L89SqNBp8I"
                
                // Manually set authentication
                await AuthManager.shared.setAuthenticationForTesting(
                    user: mockUser,
                    token: mockToken
                )
                
                print("✅ Mock login successful - User: mom, API ID: usr_687b4d8b25f075.49510878")
            }
        }
        .padding()
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}

// Extension to AuthManager for testing
extension AuthManager {
    func setAuthenticationForTesting(user: User, token: String) async {
        await MainActor.run {
            self.currentUser = user
            self.authToken = token
            self.isAuthenticated = true
            
            // Store in keychain for persistence
            KeychainHelper.save(token, forKey: "brrow_auth_token")
            if let userData = try? JSONEncoder().encode(user) {
                KeychainHelper.save(userData, forKey: "brrow_user_data")
            }
        }
    }
}