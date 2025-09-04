import SwiftUI

struct UserBadgeView: View {
    let badgeType: String?
    let size: BadgeSize
    
    enum BadgeSize {
        case small  // 16pt
        case medium // 20pt
        case large  // 24pt
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 24
            }
        }
    }
    
    var body: some View {
        if let badge = badgeType, let type = CreatorBadgeType(rawValue: badge) {
            Image(systemName: type.icon)
                .font(.system(size: size.iconSize))
                .foregroundColor(Color(hex: type.color))
        }
    }
}

// MARK: - Username with Badge View
struct UsernameWithBadge: View {
    let username: String
    let badgeType: String?
    let fontSize: CGFloat
    let badgeSize: UserBadgeView.BadgeSize
    
    init(username: String, badgeType: String?, fontSize: CGFloat = 16, badgeSize: UserBadgeView.BadgeSize = .small) {
        self.username = username
        self.badgeType = badgeType
        self.fontSize = fontSize
        self.badgeSize = badgeSize
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(username)
                .font(.system(size: fontSize, weight: .medium))
            
            UserBadgeView(badgeType: badgeType, size: badgeSize)
        }
    }
}

// MARK: - Preview
struct UserBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            UsernameWithBadge(username: "john_creator", badgeType: "creator")
            UsernameWithBadge(username: "verified_user", badgeType: "verified")
            UsernameWithBadge(username: "business_pro", badgeType: "business")
            UsernameWithBadge(username: "regular_user", badgeType: nil)
        }
        .padding()
    }
}