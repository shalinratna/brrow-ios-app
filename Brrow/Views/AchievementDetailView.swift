//
//  AchievementDetailView.swift
//  Brrow
//
//  Created by Assistant on 7/26/25.
//

import SwiftUI

struct AchievementDetailView: View {
    let achievement: AchievementData
    @State private var animateIcon = false
    @State private var animateProgress = false
    @State private var confettiCounter = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: achievement.categoryColor).opacity(0.1),
                    Color(hex: "#FFFFFF")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Achievement icon and status
                        achievementIconSection
                        
                        // Achievement info
                        achievementInfoSection
                        
                        // Progress section (if not unlocked)
                        if !achievement.isUnlocked {
                            progressSection
                        }
                        
                        // Unlock criteria
                        unlockCriteriaSection
                        
                        // Similar achievements
                        if !achievement.isSecret {
                            similarAchievementsSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateIcon = true
            }
            if achievement.isUnlocked {
                // Trigger celebration animation
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
                    confettiCounter = 1
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        ZStack {
            // Gradient header
            LinearGradient(
                colors: [
                    Color(hex: achievement.categoryColor),
                    Color(hex: achievement.categoryColor).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .background(Circle().fill(Color.black.opacity(0.1)))
                }
                
                Spacer()
                
                Text(achievement.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
            }
            .padding()
        }
        .frame(height: 100)
    }
    
    // MARK: - Achievement Icon Section
    private var achievementIconSection: some View {
        VStack(spacing: 16) {
            // Large icon
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? LinearGradient(
                                colors: [Color(hex: achievement.categoryColor), Color(hex: achievement.categoryColor).opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1 : 0.8)
                    .opacity(animateIcon ? 1 : 0)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 50))
                    .foregroundColor(achievement.isUnlocked ? .white : .gray)
                    .scaleEffect(animateIcon ? 1 : 0.5)
                    .rotationEffect(.degrees(animateIcon && achievement.isUnlocked ? 360 : 0))
                
                // Progress ring for locked achievements
                if !achievement.isUnlocked && achievement.progress.percentage > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(achievement.progress.percentage) / 100)
                        .stroke(
                            Color(hex: achievement.categoryColor),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 116, height: 116)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(animateIcon ? 1 : 0)
                }
            }
            
            // Status badge
            HStack(spacing: 6) {
                Image(systemName: achievement.isUnlocked ? "lock.open.fill" : "lock.fill")
                    .font(.caption)
                Text(achievement.isUnlocked ? "UNLOCKED" : "LOCKED")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(achievement.isUnlocked ? Color(hex: achievement.categoryColor) : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(achievement.isUnlocked ? Color(hex: achievement.categoryColor).opacity(0.1) : Color.gray.opacity(0.1))
            )
            
            if let unlockedAt = achievement.unlockedAt, achievement.isUnlocked {
                Text("Unlocked on \(formatDate(unlockedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Achievement Info Section
    private var achievementInfoSection: some View {
        VStack(spacing: 20) {
            // Name and points
            VStack(spacing: 8) {
                Text(achievement.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(achievement.points) points")
                            .fontWeight(.semibold)
                    }
                    
                    // Difficulty
                    HStack(spacing: 4) {
                        Circle()
                            .fill(achievement.difficultyColor)
                            .frame(width: 8, height: 8)
                        Text(achievement.difficulty.capitalized)
                            .fontWeight(.medium)
                            .foregroundColor(achievement.difficultyColor)
                    }
                }
                .font(.subheadline)
            }
            
            // Description
            Text(achievement.displayDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Hint (if locked and not secret)
            if !achievement.isUnlocked && !achievement.isSecret, let hint = achievement.hint {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text(hint)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            Text("Progress")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Current")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(achievement.progress.current) / \(achievement.progress.target)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: achievement.categoryColor), Color(hex: achievement.categoryColor).opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * (Double(achievement.progress.percentage) / 100),
                                height: 16
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateProgress)
                        
                        // Percentage text
                        Text("\(achievement.progress.percentage)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: geometry.size.width, alignment: .center)
                    }
                }
                .frame(height: 16)
                .onAppear {
                    animateProgress = true
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: achievement.categoryColor).opacity(0.05))
            )
        }
    }
    
    // MARK: - Unlock Criteria Section
    private var unlockCriteriaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to unlock")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                criteriaRow(icon: "target", text: "Type: \(achievement.type.capitalized)")
                
                if achievement.type == "progressive" || achievement.type == "milestone" {
                    criteriaRow(icon: "flag.checkered", text: "Goal: Reach \(achievement.progress.target)")
                }
                
                criteriaRow(icon: "star.fill", text: "Reward: \(achievement.points) points")
                
                if achievement.difficulty == "legendary" {
                    criteriaRow(icon: "crown.fill", text: "This is a legendary achievement!", color: .purple)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
        }
    }
    
    private func criteriaRow(icon: String, text: String, color: Color = .primary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color == .primary ? Color(hex: achievement.categoryColor) : color)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(color)
            Spacer()
        }
    }
    
    // MARK: - Similar Achievements Section
    private var similarAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Similar achievements")
                .font(.headline)
            
            Text("More achievements in \(achievement.category)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // This would show related achievements from the same category
            // For now, just a placeholder
            HStack {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.gray.opacity(0.3))
                        )
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        
        return displayFormatter.string(from: date)
    }
}

#Preview {
    AchievementDetailView(
        achievement: AchievementData(
            id: 1,
            code: "first_listing",
            name: "First Listing",
            description: "Create your first listing on Brrow",
            hint: "Share something with your community",
            icon: "plus.circle.fill",
            points: 50,
            difficulty: "easy",
            type: "single",
            category: "Getting Started",
            categoryColor: "#2ABF5A",
            isUnlocked: false,
            isSecret: false,
            unlockedAt: nil,
            progress: AchievementData.Progress(current: 0, target: 1, percentage: 0)
        )
    )
}