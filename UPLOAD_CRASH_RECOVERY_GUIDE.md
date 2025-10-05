# Upload Crash Recovery & Persistence System

## Overview

Production-grade crash recovery system for image uploads in the Brrow iOS app. Automatically saves upload queue to persistent storage and resumes uploads after app crashes or restarts.

## Architecture

### Components

1. **UploadQueuePersistence** (`/Brrow/Services/UploadQueuePersistence.swift`)
   - Manages persistent storage of upload queue
   - Saves image data to Documents directory
   - Stores upload metadata in UserDefaults
   - Handles cleanup of expired/failed uploads

2. **FileUploadService+Persistence** (`/Brrow/Services/FileUploadService+Persistence.swift`)
   - Extension to FileUploadService with persistence methods
   - `uploadImageWithPersistence()` - Upload with crash recovery
   - `resumePendingUploads()` - Resume uploads after app launch

3. **BackgroundUploadTaskManager** (`/Brrow/Services/BackgroundUploadTaskManager.swift`)
   - Manages UIBackgroundTask to keep uploads alive when app backgrounds
   - Uses BGTaskScheduler for long-running uploads
   - Handles background session events

4. **UploadRecoveryBanner** (`/Brrow/Views/Components/UploadRecoveryBanner.swift`)
   - UI component to show upload recovery status
   - Displays progress and completion messages

5. **BrrowApp Integration** (`/Brrow/BrrowApp.swift`)
   - Checks for pending uploads on app launch
   - Automatically resumes uploads after initialization

## Data Models

### PersistedUploadItem
```swift
struct PersistedUploadItem: Codable {
    let id: String                     // Unique identifier
    let imageFileName: String          // File name in Documents directory
    let listingId: String?             // Associated listing ID (optional)
    let uploadType: UploadType         // Type of upload
    let progress: Double               // Upload progress (0.0 to 1.0)
    let timestamp: Date                // When queued
    let attemptCount: Int              // Number of attempts
    let metadata: [String: String]     // Additional metadata

    enum UploadType: String, Codable {
        case listing
        case profile
        case message
        case general
    }
}
```

## Usage Examples

### Basic Upload with Crash Recovery

```swift
// In your view model or service
import UIKit

func uploadListingImage(_ image: UIImage) async {
    do {
        let imageUrl = try await FileUploadService.shared.uploadImageWithPersistence(
            image,
            listingId: "listing_123",
            uploadType: .listing,
            metadata: [
                "category": "Electronics",
                "title": "iPhone 14 Pro"
            ]
        )

        print("✅ Image uploaded successfully: \(imageUrl)")
        // Use imageUrl in your listing

    } catch {
        print("❌ Upload failed: \(error)")
        // Image is saved in persistent queue and will be retried on app relaunch
    }
}
```

### Batch Upload with Crash Recovery

```swift
func uploadMultipleImages(_ images: [UIImage], listingId: String) async {
    do {
        let imageUrls = try await FileUploadService.shared.uploadMultipleImagesWithPersistence(
            images,
            listingId: listingId,
            metadata: ["batch": "true"]
        )

        print("✅ Uploaded \(imageUrls.count) images")

    } catch let error as FileUploadError {
        if case .multipleFailures(let message, let failedAttempts, let successfulUploads) = error {
            print("⚠️ Partial upload: \(successfulUploads) succeeded, \(failedAttempts) failed")
            print("📝 Message: \(message)")
            // Failed images are in persistent queue for retry
        }
    } catch {
        print("❌ Upload error: \(error)")
    }
}
```

### Profile Picture Upload

```swift
func uploadProfilePicture(_ image: UIImage) async {
    do {
        let profileUrl = try await FileUploadService.shared.uploadImageWithPersistence(
            image,
            listingId: nil, // No listing ID for profile pictures
            uploadType: .profile,
            metadata: [
                "userId": AuthManager.shared.currentUser?.apiId ?? ""
            ]
        )

        // Update user profile with new image URL
        await updateUserProfile(imageUrl: profileUrl)

    } catch {
        print("❌ Profile upload failed: \(error)")
    }
}
```

### Check Pending Uploads

```swift
// In your view or view model
func checkPendingUploads() {
    let stats = UploadQueuePersistence.shared.getQueueStatistics()

    print("📊 Upload Queue Statistics:")
    print("   Total: \(stats.total)")
    print("   Should Retry: \(stats.shouldRetry)")
    print("   Expired: \(stats.expired)")

    if stats.shouldRetry > 0 {
        showAlert(message: "You have \(stats.shouldRetry) pending uploads. They will resume automatically.")
    }
}
```

### Manual Resume

```swift
// Manually trigger upload resume (usually automatic on app launch)
Task {
    await FileUploadService.shared.resumePendingUploads()
}
```

### Clear All Pending Uploads

```swift
// Clear all pending uploads (e.g., on logout)
func handleLogout() {
    UploadQueuePersistence.shared.clearAllUploads()
    print("✅ Cleared all pending uploads")
}
```

## UI Integration

### Add Recovery Banner to Main Tab View

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Your tabs...
        }
        .withUploadRecoveryBanner() // Add this line
    }
}
```

### Custom Recovery UI

```swift
struct CustomUploadRecoveryView: View {
    @StateObject private var persistence = UploadQueuePersistence.shared

    var body: some View {
        VStack {
            if persistence.hasPendingUploads() {
                HStack {
                    if persistence.isRestoring {
                        ProgressView()
                        Text("Resuming \(persistence.pendingUploads.count) uploads...")
                    } else {
                        Text("\(persistence.pendingUploads.count) pending uploads")
                        Button("Resume Now") {
                            Task {
                                await FileUploadService.shared.resumePendingUploads()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}
```

## Configuration

### Upload Queue Limits

Edit in `UploadQueuePersistence.swift`:

```swift
private let maxStoredImages = 50          // Max images in queue
private let maxFileSize = 10 * 1024 * 1024 // 10MB per image
```

### Expiration & Retry Settings

```swift
// Uploads expire after 24 hours
var isExpired: Bool {
    let expirationInterval: TimeInterval = 24 * 60 * 60
    return Date().timeIntervalSince(timestamp) > expirationInterval
}

// Max 3 retry attempts
var shouldRetry: Bool {
    return attemptCount < 3 && !isExpired
}
```

### Background Task Duration

Edit in `BackgroundUploadTaskManager.swift`:

```swift
// Estimate upload duration based on data size
private func estimateUploadDuration(dataSize: Int) -> TimeInterval {
    let bytesPerSecond = 125_000.0 // 1 Mbps
    let estimatedSeconds = Double(dataSize) / bytesPerSecond
    return min(estimatedSeconds * 1.5, 25.0) // Cap at 25 seconds
}
```

## Storage Locations

### Image Storage
```
/Documents/PendingUploads/
    ├── <upload_id_1>.jpg
    ├── <upload_id_2>.jpg
    └── <upload_id_3>.jpg
```

### Metadata Storage
```
UserDefaults:
    - Key: "brrow_upload_queue_v1"
    - Value: JSON array of PersistedUploadItem
```

## Notifications

### Upload Events

```swift
// Listen for upload resume success
NotificationCenter.default.addObserver(
    forName: .uploadResumedSuccess,
    object: nil,
    queue: .main
) { notification in
    if let userInfo = notification.userInfo,
       let uploadId = userInfo["uploadId"] as? String,
       let listingId = userInfo["listingId"] as? String,
       let imageUrl = userInfo["imageUrl"] as? String {
        print("✅ Upload \(uploadId) resumed successfully")
        // Update your listing with the imageUrl
    }
}

// Listen for resume completion alert
NotificationCenter.default.addObserver(
    forName: .showUploadResumeAlert,
    object: nil,
    queue: .main
) { notification in
    if let userInfo = notification.userInfo,
       let message = userInfo["message"] as? String,
       let successCount = userInfo["successCount"] as? Int {
        print("📢 Resume complete: \(message)")
    }
}
```

## Error Handling

### Edge Cases Handled

1. **App crashes during upload**
   - Image and metadata saved to persistent storage
   - Upload resumes on next app launch
   - Progress tracked with attempt count

2. **Network failure**
   - Upload fails and increments attempt count
   - Retries up to 3 times
   - After 3 failures, upload is removed from queue

3. **Corrupted image data**
   - Detected when loading from disk
   - Upload removed from queue automatically
   - User not shown error (silent cleanup)

4. **Expired uploads (>24 hours old)**
   - Automatically cleaned up on app launch
   - Not retried
   - Freed from storage

5. **Storage full**
   - Oldest expired uploads removed first
   - If still full, oldest upload removed
   - New upload then added to queue

6. **Partial batch upload**
   - Returns successfully uploaded URLs
   - Failed uploads remain in queue
   - User notified of partial success

## Testing

### Simulate Crash During Upload

```swift
// In your test code
func testCrashRecovery() async {
    let testImage = UIImage(named: "test_image")!

    // Start upload with persistence
    Task {
        _ = try await FileUploadService.shared.uploadImageWithPersistence(
            testImage,
            listingId: "test_listing",
            uploadType: .listing
        )
    }

    // Wait a moment for upload to queue
    try? await Task.sleep(nanoseconds: 500_000_000)

    // Simulate crash by force-quitting app
    exit(0)

    // On next app launch:
    // - App checks for pending uploads
    // - Upload automatically resumes
    // - User sees recovery banner
}
```

### Debug Logging

Enable verbose logging:

```swift
// All persistence operations log with prefixes:
// 💾 [PERSISTENCE] - Save/load operations
// 🔄 [PERSISTENCE] - Resume operations
// ✅ [PERSISTENCE] - Success messages
// ❌ [PERSISTENCE] - Error messages
// 🧹 [PERSISTENCE] - Cleanup operations
```

### Print Queue Status

```swift
// Debug helper
UploadQueuePersistence.shared.printQueueStatus()

// Output:
// 📊 [PERSISTENCE] Upload Queue Status:
//    Total: 3
//    Expired: 0
//    Should Retry: 3
//    • abc-123-def
//      Type: listing
//      Progress: 45%
//      Attempts: 1
//      Age: 5m
```

## Best Practices

### 1. Use Persistence for All User-Initiated Uploads

```swift
// ✅ Good - Uses persistence
let url = try await FileUploadService.shared.uploadImageWithPersistence(image)

// ❌ Avoid - No crash recovery
let url = try await FileUploadService.shared.uploadImage(image)
```

### 2. Clear Queue on Logout

```swift
func logout() {
    // Clear auth token
    AuthManager.shared.logout()

    // Clear pending uploads
    UploadQueuePersistence.shared.clearAllUploads()
}
```

### 3. Show Upload Status to Users

```swift
// Add banner to show users their uploads are being recovered
.withUploadRecoveryBanner()
```

### 4. Handle Partial Failures Gracefully

```swift
do {
    let urls = try await uploadMultipleImagesWithPersistence(images)
    // All succeeded
} catch FileUploadError.multipleFailures(let message, let failed, let succeeded) {
    // Some succeeded, some failed
    // Failed uploads are in queue for retry
    showAlert(title: "Partial Upload", message: message)
}
```

### 5. Monitor Queue Size

```swift
// Periodically check queue size
let stats = UploadQueuePersistence.shared.getQueueStatistics()
if stats.total > 20 {
    print("⚠️ Large upload queue detected: \(stats.total) items")
    // Consider showing user a cleanup option
}
```

## Performance Considerations

### Memory Usage
- Images compressed to 85% JPEG quality for storage
- Max 10MB per image (further compressed if needed)
- Queue limited to 50 images max

### Disk Usage
- Stored in Documents directory (backed up to iCloud)
- Automatically cleaned after successful upload
- Expired uploads (>24 hours) auto-deleted
- Typical usage: ~50MB for 10 pending uploads

### Battery Impact
- Background uploads use efficient URLSession background tasks
- Limited to 30 seconds of background execution (iOS limit)
- Long uploads automatically scheduled for next app activation

### Network Usage
- Uploads use background session (cellular or WiFi)
- Respects system Low Data Mode
- Pauses on poor network conditions

## Troubleshooting

### Uploads Not Resuming

1. **Check authentication**
   ```swift
   // Uploads only resume if user is authenticated
   if !AuthManager.shared.isAuthenticated {
       print("User not authenticated, uploads won't resume")
   }
   ```

2. **Check queue**
   ```swift
   UploadQueuePersistence.shared.printQueueStatus()
   ```

3. **Check for errors**
   ```swift
   // Enable verbose logging
   print("Checking pending uploads...")
   FileUploadService.shared.checkPendingUploadsOnLaunch()
   ```

### Storage Issues

```swift
// Check storage directory
if let uploadDir = UploadQueuePersistence.shared.getUploadStorageDirectory() {
    print("Upload storage: \(uploadDir.path)")

    // Check if directory exists
    if FileManager.default.fileExists(atPath: uploadDir.path) {
        // List files
        if let files = try? FileManager.default.contentsOfDirectory(atPath: uploadDir.path) {
            print("Files: \(files)")
        }
    }
}
```

### Clear Corrupted Queue

```swift
// Nuclear option - clear everything and start fresh
UploadQueuePersistence.shared.clearAllUploads()

// Also clear UserDefaults
UserDefaults.standard.removeObject(forKey: "brrow_upload_queue_v1")
UserDefaults.standard.synchronize()
```

## Migration Guide

### From Old Upload System

```swift
// Before (no persistence)
func uploadImage(_ image: UIImage) async throws -> String {
    return try await FileUploadService.shared.uploadImage(image)
}

// After (with persistence)
func uploadImage(_ image: UIImage) async throws -> String {
    return try await FileUploadService.shared.uploadImageWithPersistence(
        image,
        listingId: currentListingId,
        uploadType: .listing
    )
}
```

### Update Existing Upload Flows

1. Replace `uploadImage()` with `uploadImageWithPersistence()`
2. Replace `uploadMultipleImages()` with `uploadMultipleImagesWithPersistence()`
3. Add `.withUploadRecoveryBanner()` to main views
4. Handle partial upload failures gracefully

## Production Checklist

- [ ] All image uploads use persistence methods
- [ ] Upload recovery banner added to main views
- [ ] Logout clears upload queue
- [ ] Error handling for partial batch failures
- [ ] Storage limits configured appropriately
- [ ] Background session identifier unique (`com.brrow.app.background-upload`)
- [ ] Info.plist includes background modes
- [ ] Testing completed for crash scenarios
- [ ] Monitoring/analytics for upload recovery added

## Support

For issues or questions:
- Check logs for `[PERSISTENCE]` prefixes
- Use `printQueueStatus()` for debugging
- Review notification observers for upload events

---

**Last Updated:** 2025-10-04
**Version:** 1.0
**Platform:** iOS 15.0+
