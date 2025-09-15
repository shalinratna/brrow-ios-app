# 🐛 PEST Control System Setup Guide

## Problem Error Solution Tracking for Brrow

### ✅ What is PEST?
PEST is our comprehensive error handling and debugging system that:
- **Catches all errors** before users see them
- **Sends error reports to Discord** for real-time monitoring
- **Automatically recovers** from common errors
- **Retries failed network requests** with exponential backoff
- **Provides user-friendly error messages**

### ✅ PEST is Fully Configured!

#### Your Discord Webhooks:
- **Main iOS Errors**: Configured ✅
- **Backend Errors**: Separate channel ✅
- **Performance Issues**: Dedicated monitoring ✅

#### Test Your Webhooks:
1. **In the iOS App**:
   - Go to Settings → Developer (Debug builds only)
   - Tap "Test PEST Webhooks"
   - Check your Discord channels for test messages

2. **Backend Server**:
   - Errors automatically sent to backend webhook
   - Test with: `curl -X POST http://localhost:3002/api/test/pest`

### 📊 What Gets Reported?

#### Discord Reports Include:
- **Error Type & Description**
- **File, Function & Line Number**
- **Device Info** (iPhone model, iOS version)
- **Network Status**
- **User Context** (logged in user, current screen)
- **Timestamp**
- **Severity Level** (🟢 Low, 🟡 Medium, 🟠 High, 🔴 Critical)

### 🎯 How to Use PEST in Code

#### 1. Wrap Risky Operations
```swift
// Instead of:
let data = try await apiCall()

// Use:
let data = await PESTCatchAsync(
    context: "Fetching user data",
    default: []
) {
    try await apiCall()
}
```

#### 2. Report Errors Manually
```swift
PESTReport(error, context: "Custom operation failed", severity: .high)
```

#### 3. Use Safe API Calls
```swift
// All API calls now have safe versions:
let result = await APIClient.shared.safeFetchListings()
switch result {
case .success(let listings):
    // Handle success
case .failure(let error):
    // Error already reported to PEST
}
```

### 🔄 Automatic Features

#### Network Error Recovery
- Automatically retries failed requests 3 times
- Exponential backoff (2s, 4s, 8s)
- Shows offline banner when no internet

#### Token Refresh
- Automatically refreshes expired auth tokens
- Retries request after refresh

#### Cache Management
- Clears corrupted cache on decode errors
- Manages memory warnings automatically

#### Crash Reporting
- Captures uncaught exceptions
- Reports previous session crashes on app launch

### 📱 User Experience

#### Error Messages
Users see friendly messages instead of technical errors:
- ❌ "URLError Code -1009"
- ✅ "Please check your internet connection"

#### Recovery Actions
- "Try Again" button for retryable errors
- Automatic retry for network issues
- Silent recovery when possible

### 🔍 Severity Levels

| Level | Emoji | Discord Color | User Alert | Auto-Recovery |
|-------|-------|--------------|------------|---------------|
| Low | 💚 | Green | No | No |
| Medium | 💛 | Yellow | Toast | Yes |
| High | 🧡 | Orange | Toast | Yes |
| Critical | ❤️ | Red | Alert Dialog | Yes |

### 📈 Discord Message Format

```
🐛 PEST Control Bot

🟡 BrrowAPIError (401)

```swift
Unauthorized: Invalid or expired token
```

📍 Context: API Request Failed: /api/listings
📁 File: APIClient.swift:234
🔧 Function: fetchListings()
⚡ Severity: High
💻 Device: Shalin's iPhone
📱 iOS: 18.4
🕐 Time: 2025-09-15 10:48:35
```

### 🛠️ Configuration Options

Edit `PESTConfig.swift` to customize:
```swift
// Feature Toggles
static let enableDiscordLogging = true
static let enableLocalLogging = true
static let enableCrashReporting = true
static let enableNetworkRetry = true
static let enableAutoRecovery = true

// Thresholds
static let discordMinimumSeverity: PESTSeverity = .medium
static let maxRetryAttempts = 3
```

### 📝 Testing PEST

#### iOS App Testing:
1. Open the app in Debug mode
2. Go to **Settings → Developer**
3. Use the test buttons:
   - **Test All Discord Webhooks**: Tests all configured webhooks
   - **Test Low/Medium/High/Critical Error**: Send specific severity levels
   - **Simulate Performance Issue**: Test performance monitoring
   - **Trigger Backend Error Test**: Test backend integration

#### Backend Testing:
```bash
# The backend PEST is already integrated!
# Errors are automatically captured and sent to Discord
# Test by triggering any API error
```

#### Manual Code Test:
```swift
// Add this anywhere in your code to test
PESTControlSystem.shared.captureError(
    NSError(domain: "TestError", code: 0),
    context: "Manual Test",
    severity: .medium
)
```

### 🎉 You're Protected!

With PEST configured, your app will:
- Never crash unexpectedly
- Automatically recover from errors
- Report all issues to Discord
- Provide great user experience

No more debugging on edu wifi - all errors come straight to Discord! 🚀