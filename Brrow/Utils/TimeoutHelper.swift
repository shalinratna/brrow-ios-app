//
//  TimeoutHelper.swift
//  Brrow
//
//  Helper for managing async task timeouts
//

import Foundation

// Timeout error
struct TimeoutError: Error {
    let message: String
}

// Async timeout wrapper
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the main operation
        group.addTask {
            try await operation()
        }
        
        // Add timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError(message: "Operation timed out after \(seconds) seconds")
        }
        
        // Return first to complete, cancel the rest
        guard let result = try await group.next() else {
            throw TimeoutError(message: "No result returned")
        }
        
        group.cancelAll()
        return result
    }
}

// Extension for quick timeout on tasks
extension Task where Success: Sendable, Failure == Error {
    func timeout(seconds: TimeInterval) async throws -> Success {
        try await withTimeout(seconds: seconds) {
            try await self.value
        }
    }
}