//
//  FileMessageView.swift
//  Brrow
//
//  File attachment display with download and preview support
//

import SwiftUI
import QuickLook

struct FileMessageView: View {
    let fileURL: String
    let fileName: String?
    let fileSize: Int64?
    let isFromCurrentUser: Bool

    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var localFileURL: URL?
    @State private var showPreview = false
    @State private var errorMessage: String?

    var body: some View {
        Button(action: {
            if let localURL = localFileURL {
                showPreview = true
            } else {
                downloadFile()
            }
        }) {
            HStack(spacing: 12) {
                // File icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isFromCurrentUser ? Color.white.opacity(0.2) : Theme.Colors.primary.opacity(0.1))
                        .frame(width: 48, height: 48)

                    if isDownloading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: isFromCurrentUser ? .white : Theme.Colors.primary))
                    } else {
                        Image(systemName: fileIcon)
                            .font(.system(size: 24))
                            .foregroundColor(isFromCurrentUser ? .white : Theme.Colors.primary)
                    }
                }

                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayFileName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFromCurrentUser ? .white : Theme.Colors.text)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(fileSizeText)
                            .font(.system(size: 12))
                            .foregroundColor(isFromCurrentUser ? .white.opacity(0.7) : Theme.Colors.secondaryText)

                        if isDownloading {
                            Text("\(Int(downloadProgress * 100))%")
                                .font(.system(size: 12))
                                .foregroundColor(isFromCurrentUser ? .white.opacity(0.7) : Theme.Colors.secondaryText)
                        }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Download/Open icon
                Image(systemName: localFileURL != nil ? "doc.text.magnifyingglass" : "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(isFromCurrentUser ? .white.opacity(0.7) : Theme.Colors.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isFromCurrentUser ? Theme.Colors.primary : Theme.Colors.surface)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPreview) {
            if let url = localFileURL {
                FilePreviewView(url: url)
            }
        }
        .onAppear {
            checkIfFileExists()
        }
    }

    private var displayFileName: String {
        if let fileName = fileName, !fileName.isEmpty {
            return fileName
        }
        // Extract from URL
        if let url = URL(string: fileURL) {
            return url.lastPathComponent
        }
        return "File"
    }

    private var fileSizeText: String {
        guard let fileSize = fileSize else { return "Unknown size" }

        let kb = Double(fileSize) / 1024
        let mb = kb / 1024

        if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }

    private var fileIcon: String {
        let ext = (displayFileName as NSString).pathExtension.lowercased()

        switch ext {
        case "pdf":
            return "doc.fill"
        case "doc", "docx":
            return "doc.text.fill"
        case "txt":
            return "doc.plaintext.fill"
        case "jpg", "jpeg", "png":
            return "photo.fill"
        case "mp4", "mov":
            return "video.fill"
        case "zip", "rar":
            return "doc.zipper"
        default:
            return "doc.fill"
        }
    }

    private func checkIfFileExists() {
        // Check if file already downloaded
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localPath = documentsPath.appendingPathComponent("Downloads/\(displayFileName)")

        if FileManager.default.fileExists(atPath: localPath.path) {
            localFileURL = localPath
        }
    }

    private func downloadFile() {
        guard let url = URL(string: fileURL) else {
            errorMessage = "Invalid URL"
            return
        }

        isDownloading = true
        errorMessage = nil

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    await MainActor.run {
                        errorMessage = "Download failed"
                        isDownloading = false
                    }
                    return
                }

                // Save to documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let downloadsFolder = documentsPath.appendingPathComponent("Downloads")

                // Create Downloads folder if it doesn't exist
                if !FileManager.default.fileExists(atPath: downloadsFolder.path) {
                    try FileManager.default.createDirectory(at: downloadsFolder, withIntermediateDirectories: true)
                }

                let localPath = downloadsFolder.appendingPathComponent(displayFileName)
                try data.write(to: localPath)

                await MainActor.run {
                    localFileURL = localPath
                    isDownloading = false
                    downloadProgress = 1.0

                    // Show preview after download
                    showPreview = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Download failed"
                    isDownloading = false
                }
                print("Download error: \(error)")
            }
        }
    }
}

// MARK: - File Preview View

struct FilePreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

// MARK: - File Data Model

struct FileMessageData: Codable {
    let url: String
    let fileName: String
    let fileSize: Int64
    let mimeType: String?
}
