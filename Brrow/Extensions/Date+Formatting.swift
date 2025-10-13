//
//  Date+Formatting.swift
//  Brrow
//
//  Date formatting utilities for transaction dates
//

import Foundation

extension Date {
    /// Formats date to user-friendly string with relative dates (Today, Yesterday) and 12-hour time
    /// - Returns: Formatted string like "Today at 3:45 PM", "Yesterday at 2:30 PM", "Mar 15 at 11:20 AM", or "Feb 3, 2025 at 4:15 PM"
    func toUserFriendlyString() -> String {
        let calendar = Calendar.current
        let now = Date()

        // Check if date is today
        if calendar.isDateInToday(self) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Today at \(timeFormatter.string(from: self))"
        }

        // Check if date is yesterday
        if calendar.isDateInYesterday(self) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Yesterday at \(timeFormatter.string(from: self))"
        }

        // Check if date is within current year
        if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: self)
        }

        // Date is from a different year
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: self)
    }

    /// Formats date to a shorter version without time
    /// - Returns: Formatted string like "Today", "Yesterday", "Mar 15", or "Feb 3, 2025"
    func toShortUserFriendlyString() -> String {
        let calendar = Calendar.current
        let now = Date()

        // Check if date is today
        if calendar.isDateInToday(self) {
            return "Today"
        }

        // Check if date is yesterday
        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }

        // Check if date is within current year
        if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }

        // Date is from a different year
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }

    /// Formats time only in 12-hour format
    /// - Returns: Time string like "3:45 PM"
    func toTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}

extension String {
    /// Converts ISO8601 date string to user-friendly format
    /// - Returns: Formatted string or original string if parsing fails
    func toUserFriendlyDate() -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: self) {
            return date.toUserFriendlyString()
        }
        return self
    }

    /// Converts ISO8601 date string to short user-friendly format
    /// - Returns: Formatted string or original string if parsing fails
    func toShortUserFriendlyDate() -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: self) {
            return date.toShortUserFriendlyString()
        }
        return self
    }
}
