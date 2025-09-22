using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Config
{
    // General Configuration
    public const string APP_NAME = "Brrow";
    public const string APP_VERSION = "1.0.0";

    // API Configuration
    public const string BASE_API_URL = "https://brrow-backend-nodejs-production.up.railway.app/api";
    public const int REQUEST_TIMEOUT = 30; // seconds
    public const int MAX_RETRY_ATTEMPTS = 3;

    // Bubbles Feature Flag
    public static bool ENABLE_BUBBLES = false; // Default disabled

    // Unity Integration Settings
    public static class Unity
    {
        public const bool ENABLE_DEBUG_LOGGING = true;
        public const bool ENABLE_PERFORMANCE_TRACKING = true;
        public const float NETWORK_TIMEOUT = 30f;
        public const int MAX_CONCURRENT_REQUESTS = 5;
    }

    // Bubbles Configuration
    public static class Bubbles
    {
        public const int MAX_POST_LENGTH = 500;
        public const int FEED_PAGE_SIZE = 20;
        public const float REFRESH_INTERVAL = 30f;
        public const int MAX_BUBBLES_PER_USER = 50;
        public const int MAX_CACHED_POSTS = 100;

        // Bubble Types
        public const string TYPE_PUBLIC = "public";
        public const string TYPE_PRIVATE = "private";
        public const string TYPE_INVITE_ONLY = "invite_only";

        // API Endpoints
        public const string ENDPOINT_LIST = "/bubbles/list";
        public const string ENDPOINT_JOIN = "/bubbles/{id}/join";
        public const string ENDPOINT_LEAVE = "/bubbles/{id}/leave";
        public const string ENDPOINT_POST = "/bubbles/{id}/post";
        public const string ENDPOINT_FEED = "/bubbles/{id}/feed";
        public const string ENDPOINT_DETAILS = "/bubbles/{id}/details";
        public const string ENDPOINT_CREATE = "/bubbles/create";
        public const string ENDPOINT_DELETE = "/bubbles/{id}/delete";
    }

    // Authentication Settings
    public static class Auth
    {
        public const float TOKEN_REFRESH_THRESHOLD = 300f; // 5 minutes before expiry
        public const int SESSION_TIMEOUT = 3600; // 1 hour in seconds
        public const string TOKEN_KEY = "auth_token";
        public const string USER_ID_KEY = "user_id";
        public const string USERNAME_KEY = "username";
    }

    // Caching Settings
    public static class Cache
    {
        public const float BUBBLE_LIST_CACHE_DURATION = 300f; // 5 minutes
        public const float FEED_CACHE_DURATION = 60f; // 1 minute
        public const float USER_DATA_CACHE_DURATION = 600f; // 10 minutes
        public const int MAX_CACHE_ENTRIES = 1000;
    }

    // UI Settings
    public static class UI
    {
        public const float ANIMATION_DURATION = 0.3f;
        public const float TOAST_DURATION = 3f;
        public const int MAX_VISIBLE_POSTS = 50;
        public const float AUTO_REFRESH_INTERVAL = 30f;
    }

    // Error Messages
    public static class ErrorMessages
    {
        public const string FEATURE_DISABLED = "This feature is currently disabled";
        public const string AUTH_REQUIRED = "Authentication required";
        public const string NETWORK_ERROR = "Network connection error";
        public const string PARSE_ERROR = "Data parsing error";
        public const string INVALID_INPUT = "Invalid input provided";
        public const string BUBBLE_NOT_FOUND = "Bubble not found";
        public const string PERMISSION_DENIED = "Permission denied";
        public const string CONTENT_TOO_LONG = "Content exceeds maximum length";
    }

    // Success Messages
    public static class SuccessMessages
    {
        public const string BUBBLE_JOINED = "Successfully joined bubble";
        public const string BUBBLE_LEFT = "Successfully left bubble";
        public const string POST_CREATED = "Post created successfully";
        public const string BUBBLE_CREATED = "Bubble created successfully";
        public const string FEED_REFRESHED = "Feed refreshed";
    }

    // Development Settings
    public static class Development
    {
        public const bool ENABLE_MOCK_DATA = false;
        public const bool ENABLE_ANALYTICS = true;
        public const bool ENABLE_CRASH_REPORTING = true;
        public const bool ENABLE_PERFORMANCE_MONITORING = true;

        // Debug specific settings
        #if UNITY_EDITOR || DEVELOPMENT_BUILD
        public const bool ENABLE_DEBUG_UI = true;
        public const bool ENABLE_VERBOSE_LOGGING = true;
        #else
        public const bool ENABLE_DEBUG_UI = false;
        public const bool ENABLE_VERBOSE_LOGGING = false;
        #endif
    }

    // Platform-specific settings
    public static class Platform
    {
        #if UNITY_IOS
        public const string PLATFORM_NAME = "iOS";
        public const bool SUPPORTS_NOTIFICATIONS = true;
        #elif UNITY_ANDROID
        public const string PLATFORM_NAME = "Android";
        public const bool SUPPORTS_NOTIFICATIONS = true;
        #elif UNITY_WEBGL
        public const string PLATFORM_NAME = "WebGL";
        public const bool SUPPORTS_NOTIFICATIONS = false;
        #else
        public const string PLATFORM_NAME = "Desktop";
        public const bool SUPPORTS_NOTIFICATIONS = false;
        #endif
    }

    // Runtime configuration methods
    public static void EnableBubbles(bool enabled)
    {
        ENABLE_BUBBLES = enabled;
        Debug.Log($"[CONFIG] Bubbles feature {(enabled ? "enabled" : "disabled")}");
    }

    public static bool IsBubblesEnabled()
    {
        return ENABLE_BUBBLES;
    }

    public static string GetFullApiUrl(string endpoint)
    {
        return BASE_API_URL + endpoint;
    }

    public static string GetBubbleEndpoint(string endpoint, string bubbleId = null)
    {
        if (!string.IsNullOrEmpty(bubbleId))
        {
            return endpoint.Replace("{id}", bubbleId);
        }
        return endpoint;
    }

    // Validation methods
    public static bool IsValidPostContent(string content)
    {
        return !string.IsNullOrEmpty(content) &&
               content.Length <= Bubbles.MAX_POST_LENGTH;
    }

    public static bool IsValidBubbleType(string type)
    {
        return type == Bubbles.TYPE_PUBLIC ||
               type == Bubbles.TYPE_PRIVATE ||
               type == Bubbles.TYPE_INVITE_ONLY;
    }
}