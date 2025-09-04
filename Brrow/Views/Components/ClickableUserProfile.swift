//
//  ClickableUserProfile.swift
//  Brrow
//
//  Reusable clickable user profile component
//

import SwiftUI

struct ClickableUserProfile: View {
    let user: User
    let size: ProfileSize
    @State private var showingProfile = false
    
    enum ProfileSize {
        case small  // 40x40
        case medium // 50x50
        case large  // 60x60
        
        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 50
            case .large: return 60
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .body
            }
        }
    }
    
    var body: some View {
        Button(action: { showingProfile = true }) {
            HStack(spacing: 12) {
                // Profile Picture
                AsyncImage(url: URL(string: user.profilePicture ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: size.dimension * 0.8))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(user.username)
                            .font(size.fontSize.bold())
                            .foregroundColor(Theme.Colors.text)
                        
                        if user.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: size.dimension * 0.25))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let rating = user.listerRating, rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: size.dimension * 0.2))
                                .foregroundColor(.orange)
                            
                            Text("\(rating, specifier: "%.1f")")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                BasicUserProfileView(user: user)
                    .navigationBarItems(trailing: Button("Done") {
                        showingProfile = false
                    })
            }
        }
    }
}

// MARK: - Inline User Profile (No Navigation)
struct InlineUserProfile: View {
    let user: User
    let size: ClickableUserProfile.ProfileSize
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: user.profilePicture ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: size.dimension * 0.8))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
                
                Text(user.username)
                    .font(size.fontSize)
                    .foregroundColor(Theme.Colors.text)
                
                if user.verified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: size.dimension * 0.25))
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}