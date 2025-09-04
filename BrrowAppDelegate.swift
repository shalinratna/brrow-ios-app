import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Error requesting notifications: \(error)")
                }
            }
        )
        
        application.registerForRemoteNotifications()
        
        // Get FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
            } else if let token = token {
                print("FCM Token: \(token)")
                self.sendTokenToServer(token: token)
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("APNs token registered")
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    private func sendTokenToServer(token: String) {
        guard let userApiId = UserDefaults.standard.string(forKey: "userApiId") else {
            print("No user API ID found, saving token for later")
            UserDefaults.standard.set(token, forKey: "pendingFCMToken")
            return
        }
        
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
                print("Error sending FCM token: \(error)")
            } else if let data = data {
                if let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("FCM token update response: \(result)")
                }
            }
        }.resume()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        print("FCM registration token: \(token)")
        
        // Save token locally
        UserDefaults.standard.set(token, forKey: "FCMToken")
        
        // Send to server
        sendTokenToServer(token: token)
        
        // Post notification for app to handle
        NotificationCenter.default.post(
            name: Notification.Name("FCMTokenRefresh"),
            object: nil,
            userInfo: ["token": token]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("Notification received in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped: \(userInfo)")
        
        // Handle different notification types
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "message":
                if let senderId = userInfo["sender_id"] as? String {
                    // Post notification to open chat
                    NotificationCenter.default.post(
                        name: Notification.Name("OpenChat"),
                        object: nil,
                        userInfo: ["senderId": senderId]
                    )
                }
                
            case "new_listing":
                if let listingId = userInfo["listing_id"] as? String {
                    // Post notification to open listing
                    NotificationCenter.default.post(
                        name: Notification.Name("OpenListing"),
                        object: nil,
                        userInfo: ["listingId": listingId]
                    )
                }
                
            case "favorite":
                // Post notification to open favorites
                NotificationCenter.default.post(
                    name: Notification.Name("OpenFavorites"),
                    object: nil
                )
                
            default:
                break
            }
        }
        
        completionHandler()
    }
}