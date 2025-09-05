//
//  BrrowStickers.swift
//  Brrow
//
//  iMessage Sticker Pack Integration
//

import SwiftUI
import Messages

// MARK: - Sticker Pack Configuration
struct BrrowStickerPack {
    static let stickerIdentifiers = [
        "brrow_handshake",
        "brrow_money_exchange", 
        "brrow_location_pin",
        "brrow_calendar_check",
        "brrow_thumbs_up",
        "brrow_heart_community",
        "brrow_tools_share",
        "brrow_bike_lending",
        "brrow_camera_borrow",
        "brrow_kitchen_appliance",
        "brrow_sports_equipment",
        "brrow_garden_tools",
        "brrow_electronics_gadgets",
        "brrow_books_share",
        "brrow_celebration_thanks",
        "brrow_question_mark",
        "brrow_exclamation_available",
        "brrow_clock_urgent",
        "brrow_star_rating",
        "brrow_shield_trust"
    ]
    
    static let stickerDescriptions = [
        "brrow_handshake": "Deal made! 🤝",
        "brrow_money_exchange": "Payment sent 💸",
        "brrow_location_pin": "Meet here 📍",
        "brrow_calendar_check": "Date confirmed ✅",
        "brrow_thumbs_up": "Approved! 👍",
        "brrow_heart_community": "Love this community ❤️",
        "brrow_tools_share": "Tools to share 🔧",
        "brrow_bike_lending": "Bike available 🚲",
        "brrow_camera_borrow": "Need camera 📷",
        "brrow_kitchen_appliance": "Kitchen gear 🍳",
        "brrow_sports_equipment": "Sports stuff ⚽",
        "brrow_garden_tools": "Garden tools 🌱",
        "brrow_electronics_gadgets": "Tech gadgets 📱",
        "brrow_books_share": "Books to lend 📚",
        "brrow_celebration_thanks": "Thanks! 🎉",
        "brrow_question_mark": "Question? ❓",
        "brrow_exclamation_available": "Available now! ⚡",
        "brrow_clock_urgent": "Need ASAP ⏰",
        "brrow_star_rating": "5 stars! ⭐",
        "brrow_shield_trust": "Trusted member 🛡️"
    ]
}

// MARK: - Sticker Generator for iMessage
class BrrowStickerGenerator {
    static let shared = BrrowStickerGenerator()
    private init() {}
    
    func generateSticker(for identifier: String, size: CGSize = CGSize(width: 206, height: 206)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Create gradient background
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [
                                        UIColor(red: 0.165, green: 0.749, blue: 0.353, alpha: 1.0).cgColor,
                                        UIColor(red: 0.659, green: 0.902, blue: 0.690, alpha: 1.0).cgColor
                                    ] as CFArray,
                                    locations: nil)!
            
            // Draw background circle
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let radius = min(size.width, size.height) / 2 - 10
            
            context.cgContext.drawRadialGradient(gradient,
                                               startCenter: center,
                                               startRadius: 0,
                                               endCenter: center,
                                               endRadius: radius,
                                               options: [])
            
            // Draw icon based on identifier
            drawIcon(for: identifier, in: context.cgContext, size: size)
        }
    }
    
    private func drawIcon(for identifier: String, in context: CGContext, size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let iconSize: CGFloat = 80
        
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(6)
        
        switch identifier {
        case "brrow_handshake":
            // Draw handshake icon
            drawHandshake(in: context, center: CGPoint(x: centerX, y: centerY), size: iconSize)
            
        case "brrow_money_exchange":
            // Draw money exchange icon
            drawMoneyExchange(in: context, center: CGPoint(x: centerX, y: centerY), size: iconSize)
            
        case "brrow_location_pin":
            // Draw location pin
            drawLocationPin(in: context, center: CGPoint(x: centerX, y: centerY), size: iconSize)
            
        case "brrow_heart_community":
            // Draw heart
            drawHeart(in: context, center: CGPoint(x: centerX, y: centerY), size: iconSize)
            
        case "brrow_thumbs_up":
            // Draw thumbs up
            drawThumbsUp(in: context, center: CGPoint(x: centerX, y: centerY), size: iconSize)
            
        default:
            // Default brrow logo
            drawBrrowLogo(in: context, center: CGPoint(x: centerX, y: centerY), size: iconSize)
        }
    }
    
    private func drawHandshake(in context: CGContext, center: CGPoint, size: CGFloat) {
        // Simplified handshake drawing
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: center.x - size/3, y: center.y - size/4, width: size/6, height: size/2))
        path.addEllipse(in: CGRect(x: center.x + size/6, y: center.y - size/4, width: size/6, height: size/2))
        context.addPath(path)
        context.fillPath()
    }
    
    private func drawMoneyExchange(in context: CGContext, center: CGPoint, size: CGFloat) {
        // Draw dollar sign
        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x - size/4, y: center.y - size/3))
        path.addCurve(to: CGPoint(x: center.x + size/4, y: center.y),
                     control1: CGPoint(x: center.x + size/6, y: center.y - size/4),
                     control2: CGPoint(x: center.x - size/6, y: center.y - size/8))
        path.addCurve(to: CGPoint(x: center.x - size/4, y: center.y + size/3),
                     control1: CGPoint(x: center.x + size/6, y: center.y + size/8),
                     control2: CGPoint(x: center.x - size/6, y: center.y + size/4))
        context.addPath(path)
        context.strokePath()
        
        // Vertical line
        context.move(to: CGPoint(x: center.x, y: center.y - size/2))
        context.addLine(to: CGPoint(x: center.x, y: center.y + size/2))
        context.strokePath()
    }
    
    private func drawLocationPin(in context: CGContext, center: CGPoint, size: CGFloat) {
        // Draw location pin shape
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: center.x - size/4, y: center.y - size/3, width: size/2, height: size/2))
        path.move(to: CGPoint(x: center.x, y: center.y + size/6))
        path.addLine(to: CGPoint(x: center.x, y: center.y + size/2))
        context.addPath(path)
        context.fillPath()
    }
    
    private func drawHeart(in context: CGContext, center: CGPoint, size: CGFloat) {
        // Draw heart shape
        let path = CGMutablePath()
        let heartWidth = size * 0.8
        let heartHeight = size * 0.7
        
        path.move(to: CGPoint(x: center.x, y: center.y + heartHeight/3))
        path.addCurve(to: CGPoint(x: center.x - heartWidth/2, y: center.y - heartHeight/4),
                     control1: CGPoint(x: center.x - heartWidth/4, y: center.y + heartHeight/6),
                     control2: CGPoint(x: center.x - heartWidth/2, y: center.y))
        path.addCurve(to: CGPoint(x: center.x, y: center.y - heartHeight/3),
                     control1: CGPoint(x: center.x - heartWidth/2, y: center.y - heartHeight/2),
                     control2: CGPoint(x: center.x - heartWidth/4, y: center.y - heartHeight/3))
        path.addCurve(to: CGPoint(x: center.x + heartWidth/2, y: center.y - heartHeight/4),
                     control1: CGPoint(x: center.x + heartWidth/4, y: center.y - heartHeight/3),
                     control2: CGPoint(x: center.x + heartWidth/2, y: center.y - heartHeight/2))
        path.addCurve(to: CGPoint(x: center.x, y: center.y + heartHeight/3),
                     control1: CGPoint(x: center.x + heartWidth/2, y: center.y),
                     control2: CGPoint(x: center.x + heartWidth/4, y: center.y + heartHeight/6))
        context.addPath(path)
        context.fillPath()
    }
    
    private func drawThumbsUp(in context: CGContext, center: CGPoint, size: CGFloat) {
        // Draw simplified thumbs up
        let path = CGMutablePath()
        // Thumb
        path.addEllipse(in: CGRect(x: center.x - size/6, y: center.y - size/2, width: size/3, height: size/4))
        // Hand
        path.addRect(CGRect(x: center.x - size/4, y: center.y - size/4, width: size/2, height: size/2))
        context.addPath(path)
        context.fillPath()
    }
    
    private func drawBrrowLogo(in context: CGContext, center: CGPoint, size: CGFloat) {
        // Draw Brrow logo (circular arrows)
        let path = CGMutablePath()
        let radius = size / 3
        
        // First circle arrow
        path.addArc(center: CGPoint(x: center.x - radius/2, y: center.y), 
                   radius: radius/2, 
                   startAngle: 0, 
                   endAngle: .pi * 1.5, 
                   clockwise: false)
        
        // Second circle arrow
        path.addArc(center: CGPoint(x: center.x + radius/2, y: center.y), 
                   radius: radius/2, 
                   startAngle: .pi/2, 
                   endAngle: .pi * 2, 
                   clockwise: false)
        
        context.addPath(path)
        context.strokePath()
    }
}

// MARK: - Message Extension for Brrow Stickers
@available(iOS 10.0, *)
extension MSMessagesAppViewController {
    func sendBrrowSticker(identifier: String, conversation: MSConversation) {
        guard let sticker = BrrowStickerGenerator.shared.generateSticker(for: identifier) else { return }
        
        let layout = MSMessageTemplateLayout()
        layout.image = sticker
        layout.caption = BrrowStickerPack.stickerDescriptions[identifier] ?? "Brrow"
        
        let message = MSMessage()
        message.layout = layout
        message.url = URL(string: "https://brrow-backend-nodejs-production.up.railway.app/sticker/\(identifier)")
        
        conversation.insert(message) { error in
            if let error = error {
                print("Failed to send sticker: \(error)")
            }
        }
    }
}

// MARK: - Sticker Integration Helper
class BrrowStickerIntegration {
    static let shared = BrrowStickerIntegration()
    private init() {}
    
    func createStickerPack() -> [UIImage] {
        return BrrowStickerPack.stickerIdentifiers.compactMap { identifier in
            BrrowStickerGenerator.shared.generateSticker(for: identifier)
        }
    }
    
    func getStickerFor(category: BrrowStickerCategory) -> String? {
        switch category {
        case .greeting: return "brrow_handshake"
        case .payment: return "brrow_money_exchange"
        case .location: return "brrow_location_pin"
        case .appreciation: return "brrow_heart_community"
        case .approval: return "brrow_thumbs_up"
        case .urgent: return "brrow_clock_urgent"
        case .available: return "brrow_exclamation_available"
        case .question: return "brrow_question_mark"
        }
    }
}

enum BrrowStickerCategory {
    case greeting
    case payment
    case location
    case appreciation
    case approval
    case urgent
    case available
    case question
}