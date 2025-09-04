//
//  VideoCallView.swift
//  Brrow
//
//  Video calling interface
//

import SwiftUI
import AVFoundation

struct VideoCallView: View {
    let conversation: Conversation
    @Environment(\.presentationMode) var presentationMode
    @State private var isMuted = false
    @State private var isVideoOff = false
    @State private var callDuration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Video background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Top bar with user info and duration
                topBar
                
                Spacer()
                
                // Bottom controls
                bottomControls
            }
            .foregroundColor(.white)
        }
        .onAppear {
            startCallTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack {
                Text(conversation.otherUser.username)
                    .font(.headline)
                
                Text(formatDuration(callDuration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                // Switch camera
            }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var bottomControls: some View {
        HStack(spacing: 30) {
            // Mute button
            Button(action: {
                isMuted.toggle()
            }) {
                Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(isMuted ? Color.red : Color.white.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // End call button
            Button(action: {
                endCall()
            }) {
                Image(systemName: "phone.down.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            
            // Video toggle button
            Button(action: {
                isVideoOff.toggle()
            }) {
                Image(systemName: isVideoOff ? "video.slash.fill" : "video.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(isVideoOff ? Color.red : Color.white.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 50)
    }
    
    private func startCallTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            callDuration += 1
        }
    }
    
    private func endCall() {
        timer?.invalidate()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

