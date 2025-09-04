//
//  NotificationCenter+Language.swift
//  Brrow
//
//  Notification for language changes
//

import Foundation

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

extension NotificationCenter {
    static func postLanguageChangeNotification() {
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}