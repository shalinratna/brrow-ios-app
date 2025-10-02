//
//  VoiceRecorderView.swift
//  Brrow
//
//  Hold-to-record voice message with waveform animation
//  Features: Hold to record, swipe to cancel, max 2 minutes, waveform visualization
//

import SwiftUI
import AVFoundation

struct VoiceRecorderView: View {
    @ObservedObject var viewModel: ChatDetailViewModel
    let conversationId: String
    @Binding var isRecording: Bool

    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var dragOffset: CGFloat = 0
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.3, count: 40)
    @State private var levelTimer: Timer?
    @State private var showCancelHint = false

    private let maxRecordingTime: TimeInterval = 120 // 2 minutes
    private let cancelThreshold: CGFloat = -100

    var body: some View {
        HStack(spacing: 0) {
            // Cancel zone (left side)
            cancelZone
                .frame(width: 100)
                .opacity(dragOffset < -20 ? 1.0 : 0.0)

            Spacer()

            // Recording UI
            recordingInterface
                .offset(x: max(dragOffset, cancelThreshold))

            Spacer()
        }
        .frame(height: 80)
        .background(Theme.Colors.surface)
        .onAppear {
            startRecording()
        }
        .onDisappear {
            cleanup()
        }
    }

    // MARK: - Cancel Zone
    private var cancelZone: some View {
        VStack {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("Release to Cancel")
                .font(.caption)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(), value: dragOffset)
    }

    // MARK: - Recording Interface
    private var recordingInterface: some View {
        HStack(spacing: 16) {
            // Microphone button
            microphoneButton

            // Waveform visualization
            waveformView

            // Time display
            timeDisplay

            // Send button
            sendButton
        }
        .padding(.horizontal, 16)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    dragOffset = gesture.translation.width
                    showCancelHint = dragOffset < -30
                }
                .onEnded { gesture in
                    if dragOffset < cancelThreshold {
                        cancelRecording()
                    } else {
                        sendRecording()
                    }
                }
        )
    }

    // MARK: - Microphone Button
    private var microphoneButton: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 50, height: 50)
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)

            Image(systemName: "mic.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }

    // MARK: - Waveform Visualization
    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(audioLevels.count, 30), id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.primary)
                    .frame(width: 3, height: audioLevels[index] * 40)
                    .animation(.easeInOut(duration: 0.1), value: audioLevels[index])
            }
        }
        .frame(height: 40)
    }

    // MARK: - Time Display
    private var timeDisplay: some View {
        Text(formatTime(recordingTime))
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(recordingTime > maxRecordingTime * 0.9 ? .red : Theme.Colors.text)
    }

    // MARK: - Send Button
    private var sendButton: some View {
        Button(action: sendRecording) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(Theme.Colors.primary)
        }
    }

    // MARK: - Recording Logic

    private func startRecording() {
        isRecording = true
        recordingTime = 0

        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else {
                print("❌ Microphone permission denied")
                cancelRecording()
                return
            }

            DispatchQueue.main.async {
                viewModel.startVoiceRecording()

                // Start recording timer
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    recordingTime += 0.1

                    // Auto-stop at max time
                    if recordingTime >= maxRecordingTime {
                        sendRecording()
                    }
                }

                // Start audio level animation
                levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    updateAudioLevels()
                }
            }
        }
    }

    private func updateAudioLevels() {
        // Simulate audio levels (in production, use actual audio metering)
        audioLevels.removeFirst()
        let randomLevel = CGFloat.random(in: 0.2...1.0)
        audioLevels.append(randomLevel)
    }

    private func sendRecording() {
        cleanup()

        viewModel.stopVoiceRecording { audioURL in
            if let url = audioURL {
                viewModel.sendVoiceMessage(url, to: conversationId)
                print("✅ Voice message sent")
            } else {
                print("❌ Failed to get audio URL")
            }
        }

        isRecording = false
    }

    private func cancelRecording() {
        cleanup()
        viewModel.cancelVoiceRecording()
        isRecording = false
        print("🚫 Recording cancelled")
    }

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Player View
struct AudioPlayerView: View {
    let audioURL: String
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 1
    @State private var audioPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    @State private var waveformData: [CGFloat] = Array(repeating: 0.5, count: 40)

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Theme.Colors.primary)
            }

            // Waveform progress
            VStack(alignment: .leading, spacing: 4) {
                waveformProgressView

                // Time labels
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)

                    Spacer()

                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 200)
        .onAppear {
            loadAudio()
        }
        .onDisappear {
            stopPlayback()
        }
    }

    // MARK: - Waveform Progress View
    private var waveformProgressView: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<waveformData.count, id: \.self) { index in
                    let progress = currentTime / duration
                    let barProgress = CGFloat(index) / CGFloat(waveformData.count)
                    let isPlayed = barProgress <= progress

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlayed ? Theme.Colors.primary : Color.gray.opacity(0.3))
                        .frame(width: 2, height: waveformData[index] * 30)
                }
            }
        }
        .frame(height: 30)
    }

    // MARK: - Audio Playback Logic

    private func loadAudio() {
        guard let url = URL(string: audioURL) else {
            print("❌ Invalid audio URL: \(audioURL)")
            return
        }

        // Download and cache audio file
        Task {
            do {
                let (localURL, _) = try await URLSession.shared.download(from: url)
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationURL = documentsPath.appendingPathComponent("temp_audio.m4a")

                // Remove old file if exists
                try? FileManager.default.removeItem(at: destinationURL)

                // Copy downloaded file
                try FileManager.default.copyItem(at: localURL, to: destinationURL)

                await MainActor.run {
                    setupAudioPlayer(url: destinationURL)
                }
            } catch {
                print("❌ Failed to download audio: \(error)")
            }
        }
    }

    private func setupAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 1
            generateWaveformData()
        } catch {
            print("❌ Failed to setup audio player: \(error)")
        }
    }

    private func generateWaveformData() {
        // Generate random waveform data (in production, use actual audio analysis)
        waveformData = (0..<40).map { _ in CGFloat.random(in: 0.3...1.0) }
    }

    private func togglePlayback() {
        guard let player = audioPlayer else { return }

        if isPlaying {
            player.pause()
            timer?.invalidate()
            timer = nil
        } else {
            player.play()
            startTimer()
        }

        isPlaying.toggle()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentTime = audioPlayer?.currentTime ?? 0

            // Stop when finished
            if currentTime >= duration {
                stopPlayback()
            }
        }
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        timer?.invalidate()
        timer = nil
        isPlaying = false
        currentTime = 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
