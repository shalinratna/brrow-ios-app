//
//  ChallengeCard.swift
//  Brrow
//
//  Card component for community challenges
//

import SwiftUI

struct Challenge {
    let id: String
    let title: String
    let description: String
    let reward: String
    let participantCount: Int
    let daysLeft: Int
    let isJoined: Bool
}

struct ChallengeCard: View {
    let challenge: CommunityChallenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(2)
                    
                    Text(challenge.description)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(3)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    
                    Text(challenge.reward)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(challenge.participantCount) joined")
                        .font(.system(size: 8))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Text(formatDaysLeft(challenge.endDate))
                        .font(.system(size: 8))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    // Join/leave challenge
                }) {
                    Text(challenge.progress > 0 ? "In Progress" : "Join")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(challenge.progress > 0 ? Theme.Colors.primary : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(challenge.progress > 0 ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .cornerRadius(8)
        .frame(width: 160)
    }
    
    private func formatDaysLeft(_ endDate: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        if days <= 0 {
            return "Ended"
        } else if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }
}

#Preview {
    ChallengeCard(challenge: CommunityChallenge(
        title: "Eco Warrior Week",
        description: "Borrow instead of buying for a whole week",
        reward: "50 Karma",
        participantCount: 234,
        endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        difficulty: CommunityChallenge.ChallengeDifficulty.medium,
        category: CommunityChallenge.ChallengeCategory.eco,
        progress: 0.0
    ))
}