//
//  MediaViewerViews.swift
//  Brrow
//
//  Helper views for displaying media in chat
//

import SwiftUI
import AVKit

// MARK: - Image Viewer View
struct ImageViewerView: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero
    @GestureState private var isInteracting: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .updating($isInteracting) { _, state, _ in
                                    state = true
                                }
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { value in
                                    withAnimation(.spring()) {
                                        scale = min(max(lastScale * value, 1), 4)
                                        lastScale = scale
                                        
                                        // Reset position if zoomed out
                                        if scale == 1 {
                                            offset = .zero
                                            lastStoredOffset = .zero
                                        }
                                    }
                                },
                            DragGesture()
                                .updating($isInteracting) { _, state, _ in
                                    state = true
                                }
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastStoredOffset.width + value.translation.width,
                                        height: lastStoredOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { value in
                                    lastStoredOffset = offset
                                }
                        )
                    )
            } placeholder: {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let videoUrl: String
    @State private var showingVideoPlayer = false
    
    var body: some View {
        ZStack {
            // Video thumbnail placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Video")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
                .onTapGesture {
                    showingVideoPlayer = true
                }
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            VideoPlayerView(videoUrl: videoUrl)
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let videoUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Controls overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            if let url = URL(string: videoUrl) {
                player = AVPlayer(url: url)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// MARK: - Size Limit Alert View
struct SizeLimitAlertView: View {
    let currentSize: Int
    let limit: Int
    let onUpgrade: () -> Void
    @Binding var isPresented: Bool
    
    private var currentMB: String {
        String(format: "%.1f", Double(currentSize) / (1024 * 1024))
    }
    
    private var limitMB: String {
        String(format: "%.0f", Double(limit) / (1024 * 1024))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.Colors.accentOrange)
            
            Text("File Size Limit Exceeded")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text("Your file (\(currentMB)MB) exceeds your current limit of \(limitMB)MB.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    TierLimitView(tier: "Free", limit: "3MB", isActive: limit == 3 * 1024 * 1024)
                    TierLimitView(tier: "Green", limit: "5MB", isActive: limit == 5 * 1024 * 1024)
                    TierLimitView(tier: "Gold", limit: "20MB", isActive: limit == 20 * 1024 * 1024)
                }
                
                Text("Upgrade to send larger files")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            
            HStack(spacing: 16) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(22)
                }
                
                Button(action: {
                    onUpgrade()
                    isPresented = false
                }) {
                    Text("Upgrade")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.Colors.primary)
                        .cornerRadius(22)
                }
            }
            .padding(.horizontal)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(40)
    }
}

// MARK: - Tier Limit View
struct TierLimitView: View {
    let tier: String
    let limit: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(tier)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? Theme.Colors.primary : Theme.Colors.secondaryText)
            
            Text(limit)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isActive ? Theme.Colors.primary : Theme.Colors.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActive ? Theme.Colors.primary.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Theme.Colors.primary : Color.clear, lineWidth: 2)
        )
    }
}