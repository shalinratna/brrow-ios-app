# Brrow Bubbles Unity Client Integration

## 🎯 Overview
Complete Unity client system for Brrow Bubbles feature, providing seamless integration with the Brrow backend API for social group functionality within Unity applications.

## 📁 File Structure
```
Assets/
├── Bubbles/
│   ├── BubbleHandler.cs      # Main API client handler
│   ├── BubbleExample.cs      # Example usage and patterns
│   └── README_UNITY_BUBBLES.md
└── Scripts/
    └── Config.cs             # Configuration and feature flags
```

## 🚀 Quick Start

### 1. Feature Flag Configuration
```csharp
// Enable bubbles feature
Config.EnableBubbles(true);

// Check if enabled
if (Config.IsBubblesEnabled()) {
    // Proceed with bubbles functionality
}
```

### 2. Basic Setup
```csharp
// Set authentication token (from your login system)
BubbleHandler.Instance.SetAuthToken("your-jwt-token");

// Verify handler is ready
if (BubbleHandler.Instance.IsAuthenticated()) {
    // Ready to use bubbles API
}
```

### 3. Core Operations

#### Fetch Available Bubbles
```csharp
StartCoroutine(BubbleHandler.Instance.FetchBubbles(
    (bubbles) => {
        // Handle success
        foreach (var bubble in bubbles) {
            Debug.Log($"Bubble: {bubble.name} ({bubble.memberCount} members)");
        }
    },
    (error) => {
        // Handle error
        Debug.LogError($"Failed to fetch bubbles: {error}");
    }
));
```

#### Join a Bubble
```csharp
StartCoroutine(BubbleHandler.Instance.JoinBubble(
    bubbleId,
    () => {
        // Successfully joined
        Debug.Log("Joined bubble successfully!");
    },
    (error) => {
        // Handle error
        Debug.LogError($"Failed to join: {error}");
    }
));
```

#### Post to Bubble
```csharp
string content = "Hello from Unity!";
if (Config.IsValidPostContent(content)) {
    StartCoroutine(BubbleHandler.Instance.PostToBubble(
        bubbleId,
        content,
        () => {
            // Post created successfully
            Debug.Log("Post created!");
        },
        (error) => {
            // Handle error
            Debug.LogError($"Failed to post: {error}");
        }
    ));
}
```

#### Get Bubble Feed
```csharp
StartCoroutine(BubbleHandler.Instance.GetBubbleFeed(
    bubbleId,
    (posts) => {
        // Handle feed data
        foreach (var post in posts) {
            Debug.Log($"{post.username}: {post.content}");
        }
    },
    (error) => {
        // Handle error
        Debug.LogError($"Failed to get feed: {error}");
    }
));
```

## 🔧 API Reference

### BubbleHandler Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `SetAuthToken(string)` | Set JWT authentication token | token | void |
| `FetchBubbles(Action<List<BubbleGroup>>, Action<string>)` | Get available bubbles | onSuccess, onError | IEnumerator |
| `JoinBubble(string, Action, Action<string>)` | Join a bubble | bubbleId, onSuccess, onError | IEnumerator |
| `PostToBubble(string, string, Action, Action<string>)` | Post content | bubbleId, content, onSuccess, onError | IEnumerator |
| `GetBubbleFeed(string, Action<List<BubblePost>>, Action<string>)` | Get bubble feed | bubbleId, onSuccess, onError | IEnumerator |
| `RefreshFeed(string, Action<List<BubblePost>>, Action<string>)` | Refresh feed | bubbleId, onSuccess, onError | IEnumerator |
| `GetBubbleDetails(string, Action<BubbleGroup>, Action<string>)` | Get bubble details | bubbleId, onSuccess, onError | IEnumerator |
| `ClearAuthToken()` | Clear authentication | none | void |
| `IsEnabled()` | Check if feature enabled | none | bool |
| `IsAuthenticated()` | Check if authenticated | none | bool |

### Data Models

#### BubbleGroup
```csharp
public class BubbleGroup {
    public string id;
    public string name;
    public string description;
    public string ownerId;
    public string type;          // "public", "private", "invite_only"
    public DateTime createdAt;
    public int memberCount;
}
```

#### BubblePost
```csharp
public class BubblePost {
    public string id;
    public string groupId;
    public string userId;
    public string content;
    public string username;
    public DateTime createdAt;
}
```

## ⚙️ Configuration Options

### Feature Flags
```csharp
Config.ENABLE_BUBBLES = true/false;    // Main feature toggle
```

### Bubble Settings
```csharp
Config.Bubbles.MAX_POST_LENGTH = 500;      // Maximum post length
Config.Bubbles.FEED_PAGE_SIZE = 20;        // Feed pagination size
Config.Bubbles.REFRESH_INTERVAL = 30f;     // Auto refresh interval
Config.Bubbles.MAX_BUBBLES_PER_USER = 50;  // User bubble limit
Config.Bubbles.MAX_CACHED_POSTS = 100;     // Cache limit
```

### Validation Methods
```csharp
Config.IsValidPostContent(string content);  // Validate post content
Config.IsValidBubbleType(string type);      // Validate bubble type
```

## 🔒 Security & Authentication

### Token Management
- JWT tokens are securely stored in BubbleHandler
- Tokens are automatically included in all API requests
- Use `ClearAuthToken()` on user logout
- Check `IsAuthenticated()` before API calls

### Error Handling
- All methods include comprehensive error callbacks
- Network timeouts are handled automatically
- Feature flag checks prevent unauthorized access
- Input validation prevents malformed requests

## 🎮 Unity Integration Patterns

### Singleton Pattern
- BubbleHandler uses singleton pattern via `Instance`
- DontDestroyOnLoad ensures persistence across scenes
- Automatic initialization and cleanup

### Coroutine Management
- All API calls return IEnumerator for coroutine usage
- Non-blocking operations maintain smooth gameplay
- Proper error handling in all coroutines

### Logging Convention
- All logs prefixed with `[BUBBLES]`
- Different log levels: Log, Warning, Error
- Debug information available in development builds

### Scene Integration
```csharp
public class GameManager : MonoBehaviour {
    void Start() {
        // Initialize bubbles on game start
        if (Config.ENABLE_BUBBLES && BubbleHandler.Instance != null) {
            // Set auth token from saved login
            BubbleHandler.Instance.SetAuthToken(PlayerPrefs.GetString("auth_token"));
        }
    }

    void OnApplicationPause(bool pauseStatus) {
        // Clear sensitive data when app is paused
        if (pauseStatus) {
            BubbleHandler.Instance?.ClearAuthToken();
        }
    }
}
```

## 🧪 Testing & Development

### Example Usage
- See `BubbleExample.cs` for complete implementation examples
- Debug UI available in Unity Editor for testing
- Manual testing buttons for all operations

### Debug Features
- Editor-only debug GUI
- Comprehensive logging
- Feature flag runtime toggle
- Mock data support in development

## 🔗 Backend Integration

### API Endpoints
- **Base URL**: `https://brrow-backend-nodejs-production.up.railway.app/api/bubbles`
- **Authentication**: Bearer JWT token required
- **Rate Limiting**: Built-in protection for all operations

### Supported Operations
- ✅ List bubbles with pagination and filtering
- ✅ Join/leave bubbles with permission checks
- ✅ Create posts with content validation
- ✅ Get feed with real-time updates
- ✅ Bubble details and member management
- ✅ Activity logging and monitoring

## 📱 Platform Support

### Unity Platforms
- ✅ iOS (with notification support)
- ✅ Android (with notification support)
- ✅ WebGL (limited notification support)
- ✅ Desktop (Windows, Mac, Linux)

### Feature Compatibility
- All platforms support core bubbles functionality
- Notifications available on mobile platforms
- WebGL has limited local storage for tokens

## 🚨 Important Notes

### Feature Flag System
- **ALWAYS** check `Config.ENABLE_BUBBLES` before any bubbles operation
- Feature can be disabled remotely for maintenance
- Graceful degradation when feature is disabled

### Error Handling Best Practices
- Never ignore error callbacks
- Always validate input before API calls
- Provide user-friendly error messages
- Log errors for debugging but don't expose sensitive data

### Performance Considerations
- Use pagination for large bubble lists
- Cache feed data appropriately
- Limit concurrent API requests
- Implement proper loading states

## 🔧 Troubleshooting

### Common Issues

#### "Feature disabled" errors
- Check `Config.ENABLE_BUBBLES` is true
- Verify backend has bubbles feature enabled
- Ensure proper Unity configuration

#### Authentication failures
- Verify JWT token is valid and not expired
- Check token format (Bearer prefix)
- Ensure user has proper permissions

#### Network errors
- Check internet connectivity
- Verify API base URL is correct
- Check for firewall/proxy issues

### Debug Commands
```csharp
// Check feature status
Debug.Log($"Bubbles enabled: {Config.ENABLE_BUBBLES}");
Debug.Log($"Handler available: {BubbleHandler.Instance != null}");
Debug.Log($"Authenticated: {BubbleHandler.Instance?.IsAuthenticated()}");

// Test connectivity
StartCoroutine(BubbleHandler.Instance.FetchBubbles(
    (bubbles) => Debug.Log("✅ API connection successful"),
    (error) => Debug.Log($"❌ API connection failed: {error}")
));
```

---

## 📄 License & Support

This Unity integration is part of the Brrow platform. For support and updates, contact the development team.

**Last Updated**: September 2024
**Version**: 1.0.0
**Compatible Unity Version**: 2021.3 LTS+