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
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.dateFormat = "h:mm a"
            return "Today at \(timeFormatter.string(from: self))"
        }

        // Check if date is yesterday
        if calendar.isDateInYesterday(self) {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.dateFormat = "h:mm a"
            return "Yesterday at \(timeFormatter.string(from: self))"
        }

        // Check if date is within current year
        if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: self)
        }

        // Date is from a different year
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
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
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }

        // Date is from a different year
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }

    /// Formats time only in 12-hour format
    /// - Returns: Time string like "3:45 PM"
    func toTimeString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}

extension String {
    /// Converts ISO8601 date string to user-friendly format
    /// - Returns: Formatted string or original string if parsing fails
    func toUserFriendlyDate() -> String {
        // First try the most common backend format: "2025-10-13T23:01:01.620Z"
        let primaryFormatter = DateFormatter()
        primaryFormatter.locale = Locale(identifier: "en_US_POSIX")
        primaryFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        primaryFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = primaryFormatter.date(from: self) {
            return date.toUserFriendlyString()
        }

        // Try ISO8601 formatters
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: self) {
            return date.toUserFriendlyString()
        }

        // Try without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: self) {
            return date.toUserFriendlyString()
        }

        // Fallback: try other common formats
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",  // Microseconds with timezone
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // Milliseconds with timezone offset
            "yyyy-MM-dd'T'HH:mm:ssZ",         // No milliseconds with timezone
            "yyyy-MM-dd'T'HH:mm:ss'Z'",       // No milliseconds, Z literal
            "yyyy-MM-dd HH:mm:ss"             // Simple format
        ]

        for format in dateFormats {
            fallbackFormatter.dateFormat = format
            if let date = fallbackFormatter.date(from: self) {
                return date.toUserFriendlyString()
            }
        }

        // If all parsing fails, return original string
        return self
    }

    /// Converts ISO8601 date string to short user-friendly format
    /// - Returns: Formatted string or original string if parsing fails
    func toShortUserFriendlyDate() -> String {
        // First try the most common backend format: "2025-10-13T23:01:01.620Z"
        let primaryFormatter = DateFormatter()
        primaryFormatter.locale = Locale(identifier: "en_US_POSIX")
        primaryFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        primaryFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = primaryFormatter.date(from: self) {
            return date.toShortUserFriendlyString()
        }

        // Try ISO8601 formatters
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: self) {
            return date.toShortUserFriendlyString()
        }

        // Try without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: self) {
            return date.toShortUserFriendlyString()
        }

        // Fallback: try other common formats
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",  // Microseconds with timezone
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // Milliseconds with timezone offset
            "yyyy-MM-dd'T'HH:mm:ssZ",         // No milliseconds with timezone
            "yyyy-MM-dd'T'HH:mm:ss'Z'",       // No milliseconds, Z literal
            "yyyy-MM-dd HH:mm:ss"             // Simple format
        ]

        for format in dateFormats {
            fallbackFormatter.dateFormat = format
            if let date = fallbackFormatter.date(from: self) {
                return date.toShortUserFriendlyString()
            }
        }

        // If all parsing fails, return original string
        return self
    }
}
