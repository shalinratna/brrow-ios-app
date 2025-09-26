//
//  Notification+Extensions.swift
//  Brrow
//
//  Notification names used throughout the app
//

import Foundation

extension Notification.Name {
    // Navigation
    static let navigateToChat = Notification.Name("navigateToChat")
    static let openSpecificChat = Notification.Name("openSpecificChat")
    static let navigateToMessages = Notification.Name("navigateToMessages")
    static let navigateToEarnings = Notification.Name("navigateToEarnings")
    static let navigateToMyPosts = Notification.Name("navigateToMyPosts")
    
    // Widget Deep Links
    static let openEarnings = Notification.Name("openEarnings")
    static let filterNearby = Notification.Name("filterNearby")
    static let createNewListing = Notification.Name("createNewListing")
    
    // Push Notifications
    static let newSeekMatch = Notification.Name("newSeekMatch")
    static let newMessage = Notification.Name("newMessage")
    static let offerUpdate = Notification.Name("offerUpdate")
    static let transactionUpdate = Notification.Name("transactionUpdate")
    static let rentalUpdate = Notification.Name("rentalUpdate")
    static let paymentUpdate = Notification.Name("paymentUpdate")
}