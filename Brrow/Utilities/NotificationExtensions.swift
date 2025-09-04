//
//  NotificationExtensions.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import UserNotifications

// MARK: - Notification Names
extension Notification.Name {
    
    // MARK: - Authentication
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let userDidUpdate = Notification.Name("userDidUpdate")
    static let authenticationFailed = Notification.Name("authenticationFailed")
    
    // MARK: - Listings
    static let listingDidCreate = Notification.Name("listingDidCreate")
    static let listingDidUpdate = Notification.Name("listingDidUpdate")
    static let listingDidDelete = Notification.Name("listingDidDelete")
    static let listingStatusChanged = Notification.Name("listingStatusChanged")
    
    // MARK: - Offers
    static let offerDidCreate = Notification.Name("offerDidCreate")
    static let offerDidUpdate = Notification.Name("offerDidUpdate")
    static let offerDidAccept = Notification.Name("offerDidAccept")
    static let offerDidReject = Notification.Name("offerDidReject")
    static let offerDidExpire = Notification.Name("offerDidExpire")
    static let offerStatusChanged = Notification.Name("offerStatusChanged")
    
    // MARK: - Transactions
    static let transactionDidCreate = Notification.Name("transactionDidCreate")
    static let transactionDidUpdate = Notification.Name("transactionDidUpdate")
    static let transactionDidComplete = Notification.Name("transactionDidComplete")
    static let transactionDidCancel = Notification.Name("transactionDidCancel")
    static let transactionStatusChanged = Notification.Name("transactionStatusChanged")
    static let paymentDidProcess = Notification.Name("paymentDidProcess")
    static let paymentDidFail = Notification.Name("paymentDidFail")
    
    // MARK: - Seeks
    static let seekDidCreate = Notification.Name("seekDidCreate")
    static let seekDidUpdate = Notification.Name("seekDidUpdate")
    static let seekDidDelete = Notification.Name("seekDidDelete")
    static let seekMatched = Notification.Name("seekMatched")
    static let seekAlertTriggered = Notification.Name("seekAlertTriggered")
    
    // MARK: - Garage Sales
    static let garageSaleDidCreate = Notification.Name("garageSaleDidCreate")
    static let garageSaleDidUpdate = Notification.Name("garageSaleDidUpdate")
    static let garageSaleDidStart = Notification.Name("garageSaleDidStart")
    static let garageSaleDidEnd = Notification.Name("garageSaleDidEnd")
    static let garageSaleRSVPChanged = Notification.Name("garageSaleRSVPChanged")
    
    // MARK: - Chat & Messages
    static let messageDidReceive = Notification.Name("messageDidReceive")
    static let messageDidSend = Notification.Name("messageDidSend")
    static let conversationDidUpdate = Notification.Name("conversationDidUpdate")
    static let typingIndicatorChanged = Notification.Name("typingIndicatorChanged")
    static let newMessageReceived = Notification.Name("newMessageReceived")
    static let messageRead = Notification.Name("messageRead")
    
    // MARK: - Location
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
    static let locationPermissionChanged = Notification.Name("locationPermissionChanged")
    
    // MARK: - Network
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let syncDidComplete = Notification.Name("syncDidComplete")
    static let syncDidFail = Notification.Name("syncDidFail")
    
    // MARK: - Push Notifications
    static let pushNotificationReceived = Notification.Name("pushNotificationReceived")
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
    
    // MARK: - App Lifecycle
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    
    // MARK: - Theme & Settings
    static let themeDidChange = Notification.Name("themeDidChange")
    static let settingsDidChange = Notification.Name("settingsDidChange")
    
    // MARK: - Favorites
    static let favoriteDidAdd = Notification.Name("favoriteDidAdd")
    static let favoriteDidRemove = Notification.Name("favoriteDidRemove")
    
    // MARK: - Analytics
    static let analyticsEventTracked = Notification.Name("analyticsEventTracked")
    
    // MARK: - Errors
    static let errorDidOccur = Notification.Name("errorDidOccur")
    static let apiErrorDidOccur = Notification.Name("apiErrorDidOccur")
}

// MARK: - Notification UserInfo Keys
extension Notification {
    
    struct UserInfoKey {
        static let user = "user"
        static let listing = "listing"
        static let offer = "offer"
        static let transaction = "transaction"
        static let seek = "seek"
        static let garageSale = "garageSale"
        static let message = "message"
        static let conversation = "conversation"
        static let location = "location"
        static let error = "error"
        static let eventData = "eventData"
        static let userId = "userId"
        static let listingId = "listingId"
        static let offerId = "offerId"
        static let transactionId = "transactionId"
        static let seekId = "seekId"
        static let garageSaleId = "garageSaleId"
        static let conversationId = "conversationId"
        static let isTyping = "isTyping"
        static let networkStatus = "networkStatus"
        static let theme = "theme"
        static let settings = "settings"
        static let pushData = "pushData"
        static let analyticsData = "analyticsData"
    }
}
