//
//  StoryDetailCard.swift
//  Brrow
//
//  Card component for story details
//

import SwiftUI

struct Story {
    let id: String
    let username: String
    let profilePicture: String
    let image: String
    let caption: String
    let timeAgo: String
}

struct StoryDetailCard: View {
    let story: BrrowStory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: story.imageUrl ?? story.thumbnailUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(String(story.username.prefix(1)).uppercased())
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.username)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(formatTimeAgo(story.timestamp))
                        .font(.system(size: 8))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            if !story.caption.isEmpty {
                Text(story.caption)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
            }
        }
        .frame(width: 140)
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

