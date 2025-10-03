//
//  VideoPicker.swift
//  Brrow
//
//  Video picker with compression and thumbnail generation
//

import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

struct VideoPicker: UIViewControllerRepresentable {
    let onVideoSelected: (URL, UIImage?) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            guard let result = results.first else { return }

            // Load video
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                if let error = error {
                    print("Error loading video: \(error)")
                    return
                }

                guard let url = url else {
                    print("No video URL")
                    return
                }

                // Copy to temp directory
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")

                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)

                    // Generate thumbnail
                    let thumbnail = self.generateThumbnail(for: tempURL)

                    // Compress video in background
                    Task {
                        if let compressedURL = await VideoCompressor.shared.compressVideo(tempURL) {
                            DispatchQueue.main.async {
                                self.parent.onVideoSelected(compressedURL, thumbnail)
                            }
                        } else {
                            // Use original if compression fails
                            DispatchQueue.main.async {
                                self.parent.onVideoSelected(tempURL, thumbnail)
                            }
                        }
                    }
                } catch {
                    print("Error copying video: \(error)")
                }
            }
        }

        private func generateThumbnail(for url: URL) -> UIImage? {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true

            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                print("Error generating thumbnail: \(error)")
                return nil
            }
        }
    }
}

// MARK: - Video Compressor

actor VideoCompressor {
    static let shared = VideoCompressor()

    private let maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB

    func compressVideo(_ inputURL: URL) async -> URL? {
        // Check original file size
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: inputURL.path)[.size] as? Int64 else {
            return nil
        }

        print("Original video size: \(fileSize / 1024 / 1024)MB")

        // If already under limit, return original
        if fileSize <= maxFileSize {
            print("Video already under size limit")
            return inputURL
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")

        // Remove existing file if any
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let asset = AVAsset(url: inputURL)

        // Get video track
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }

        // Determine export preset based on file size
        let exportPreset: String
        if fileSize > 100 * 1024 * 1024 { // Over 100MB
            exportPreset = AVAssetExportPresetMediumQuality
        } else {
            exportPreset = AVAssetExportPreset1280x720 // 720p
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: exportPreset) else {
            return nil
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        return await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    if let compressedSize = try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64 {
                        print("Compressed video size: \(compressedSize / 1024 / 1024)MB")
                    }
                    continuation.resume(returning: outputURL)
                case .failed, .cancelled:
                    print("Compression failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: nil)
                default:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func generateThumbnail(for url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }

    func getVideoDuration(for url: URL) async -> TimeInterval? {
        let asset = AVAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return nil
        }
    }
}
