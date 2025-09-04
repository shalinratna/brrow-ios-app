//
//  AnalyticsEvent.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation

struct AnalyticsEvent: Codable {
    let eventName: String
    let eventType: String
    let userId: String?
    let sessionId: String?
    let timestamp: String?
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case eventName
        case eventType
        case userId
        case sessionId
        case timestamp
        case metadata
    }
    
    init(eventName: String, eventType: String, userId: String? = nil, sessionId: String? = nil, timestamp: String? = nil, metadata: [String: Any]? = nil) {
        self.eventName = eventName
        self.eventType = eventType
        self.userId = userId
        self.sessionId = sessionId
        self.timestamp = timestamp ?? ISO8601DateFormatter().string(from: Date())
        self.metadata = metadata
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(eventType, forKey: .eventType)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        
        // Handle metadata encoding manually since it's a dictionary of Any
        if let metadata = metadata {
            let jsonData = try JSONSerialization.data(withJSONObject: metadata)
            let jsonString = String(data: jsonData, encoding: .utf8)
            try container.encodeIfPresent(jsonString, forKey: .metadata)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventName = try container.decode(String.self, forKey: .eventName)
        eventType = try container.decode(String.self, forKey: .eventType)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        
        // Handle metadata decoding manually
        if let jsonString = try container.decodeIfPresent(String.self, forKey: .metadata),
           let jsonData = jsonString.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            metadata = jsonObject
        } else {
            metadata = nil
        }
    }
}