//
//  AchievementNotificationView.swift
//  Brrow
//
//  View for showing achievement unlock notifications
//

import SwiftUI
import Combine

struct AchievementNotificationView: View {
    let achievement: AchievementData
    @State private var isVisible = false
    @State private var hasAppeared = false
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if isVisible {
                HStack(spacing: 16) {
                    // Achievement icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: achievement.categoryColor))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: achievement.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Achievement info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Achievement Unlocked!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text(achievement.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                            .lineLimit(1)
                        
                        Text(achievement.description)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .lineLimit(2)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.accentOrange)
                            
                            Text("\(achievement.points) points")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.Colors.accentOrange)
                        }
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .frame(width: 24, height: 24)
                            .background(Theme.Colors.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.background)
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                )
                .padding(.horizontal, 16)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 50)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            Spacer().frame(height: 100) // Safe area padding
        }
        .ignoresSafeArea()
        .allowsHitTesting(isVisible)
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                
                // Show with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isVisible = true
                    }
                    
                    // Auto dismiss after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        dismiss()
                    }
                }
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Achievement Notification Manager
class AchievementNotificationManager: ObservableObject {
    static let shared = AchievementNotificationManager()
    
    @Published var currentNotification: AchievementData?
    @Published var showNotification = false
    
    private var notificationQueue: [AchievementData] = []
    private var isProcessingQueue = false
    
    private init() {
        // Listen for achievement unlocks
        AchievementManager.shared.$newlyUnlockedAchievements
            .sink { [weak self] achievements in
                for unlocked in achievements {
                    // Convert UnlockedAchievement to AchievementData
                    let achievementData = AchievementData(
                        id: unlocked.id,
                        code: unlocked.code,
                        name: unlocked.name,
                        description: unlocked.description,
                        hint: nil,
                        icon: unlocked.icon,
                        points: unlocked.points,
                        difficulty: unlocked.difficulty,
                        type: "one_time",
                        category: "General",
                        categoryColor: "#2ABF5A",
                        isUnlocked: true,
                        isSecret: false,
                        unlockedAt: ISO8601DateFormatter().string(from: Date()),
                        progress: AchievementData.Progress(
                            current: 1,
                            target: 1,
                            percentage: 100
                        )
                    )
                    self?.queueNotification(achievementData)
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func queueNotification(_ achievement: AchievementData) {
        notificationQueue.append(achievement)
        processQueue()
    }
    
    private func processQueue() {
        guard !isProcessingQueue, !notificationQueue.isEmpty, !showNotification else {
            return
        }
        
        isProcessingQueue = true
        let achievement = notificationQueue.removeFirst()
        
        DispatchQueue.main.async {
            self.currentNotification = achievement
            self.showNotification = true
        }
        
        // Wait for notification to be dismissed before processing next
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isProcessingQueue = false
            if !self.showNotification {
                self.processQueue()
            }
        }
    }
    
    func dismissCurrentNotification() {
        showNotification = false
        currentNotification = nil
        isProcessingQueue = false
        
        // Process next in queue after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.processQueue()
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        AchievementNotificationView(
            achievement: AchievementData(
                id: 1,
                code: "first_listing",
                name: "First Steps",
                description: "Created your very first listing on Brrow!",
                hint: nil,
                icon: "plus.circle.fill",
                points: 25,
                difficulty: "Easy",
                type: "count",
                category: "Listing",
                categoryColor: "#2ABF5A",
                isUnlocked: true,
                isSecret: false,
                unlockedAt: "2025-01-26T10:00:00Z",
                progress: AchievementData.Progress(
                    current: 1,
                    target: 1,
                    percentage: 100
                )
            ),
            isPresented: .constant(true)
        )
    }
}