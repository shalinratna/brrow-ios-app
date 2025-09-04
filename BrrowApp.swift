import SwiftUI
import FirebaseCore

@main
struct BrrowApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // State management
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotificationObservers()
                }
        }
    }
    
    private func setupNotificationObservers() {
        // Listen for FCM token updates
        NotificationCenter.default.addObserver(
            forName: Notification.Name("FCMTokenRefresh"),
            object: nil,
            queue: .main
        ) { notification in
            if let token = notification.userInfo?["token"] as? String {
                print("New FCM token received: \(token)")
                // Update token on server if user is logged in
                if authManager.isAuthenticated {
                    authManager.updateFCMToken(token)
                }
            }
        }
        
        // Listen for notification taps
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OpenChat"),
            object: nil,
            queue: .main
        ) { notification in
            if let senderId = notification.userInfo?["senderId"] as? String {
                notificationManager.openChat(with: senderId)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OpenListing"),
            object: nil,
            queue: .main
        ) { notification in
            if let listingId = notification.userInfo?["listingId"] as? String {
                notificationManager.openListing(listingId: listingId)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OpenFavorites"),
            object: nil,
            queue: .main
        ) { _ in
            notificationManager.openFavorites()
        }
    }
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userApiId: String?
    
    init() {
        // Check if user is already logged in
        if let savedUserApiId = UserDefaults.standard.string(forKey: "userApiId") {
            self.userApiId = savedUserApiId
            self.isAuthenticated = true
            
            // Send pending FCM token if exists
            if let pendingToken = UserDefaults.standard.string(forKey: "pendingFCMToken") {
                updateFCMToken(pendingToken)
                UserDefaults.standard.removeObject(forKey: "pendingFCMToken")
            }
        }
    }
    
    func updateFCMToken(_ token: String) {
        guard let userApiId = userApiId else { return }
        
        guard let url = URL(string: "https://brrowapp.com/api_update_fcm_token.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_api_id": userApiId,
            "fcm_token": token,
            "platform": "ios"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating FCM token: \(error)")
            } else {
                print("FCM token updated successfully")
            }
        }.resume()
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    @Published var showingChat = false
    @Published var chatUserId: String?
    @Published var showingListing = false
    @Published var listingId: String?
    @Published var showingFavorites = false
    
    func openChat(with userId: String) {
        chatUserId = userId
        showingChat = true
    }
    
    func openListing(listingId: String) {
        self.listingId = listingId
        showingListing = true
    }
    
    func openFavorites() {
        showingFavorites = true
    }
}