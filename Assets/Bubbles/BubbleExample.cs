using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Example usage of BubbleHandler for Unity integration
/// This demonstrates proper patterns and usage conventions
/// </summary>
public class BubbleExample : MonoBehaviour
{
    [Header("Example Configuration")]
    public bool runExampleOnStart = false;
    public string testBubbleId = "";
    public string testPostContent = "Hello from Unity!";

    private List<BubbleGroup> currentBubbles = new List<BubbleGroup>();
    private List<BubblePost> currentFeed = new List<BubblePost>();

    void Start()
    {
        if (runExampleOnStart && Config.ENABLE_BUBBLES)
        {
            StartCoroutine(RunBubbleExample());
        }
    }

    /// <summary>
    /// Complete example workflow showing all BubbleHandler methods
    /// This follows Unity best practices and the SeekHandler pattern
    /// </summary>
    public IEnumerator RunBubbleExample()
    {
        Debug.Log("[BUBBLE_EXAMPLE] Starting bubble example workflow...");

        // Check if BubbleHandler is available and enabled
        if (BubbleHandler.Instance == null)
        {
            Debug.LogError("[BUBBLE_EXAMPLE] BubbleHandler not found!");
            yield break;
        }

        if (!BubbleHandler.Instance.IsEnabled())
        {
            Debug.LogWarning("[BUBBLE_EXAMPLE] Bubbles feature is disabled");
            yield break;
        }

        // Example: Set authentication token (normally from login system)
        string exampleToken = "your-jwt-token-here";
        BubbleHandler.Instance.SetAuthToken(exampleToken);

        if (!BubbleHandler.Instance.IsAuthenticated())
        {
            Debug.LogError("[BUBBLE_EXAMPLE] Authentication required");
            yield break;
        }

        // Step 1: Fetch available bubbles
        yield return StartCoroutine(ExampleFetchBubbles());

        // Step 2: Join a bubble (if we have one)
        if (currentBubbles.Count > 0 && string.IsNullOrEmpty(testBubbleId))
        {
            testBubbleId = currentBubbles[0].id;
        }

        if (!string.IsNullOrEmpty(testBubbleId))
        {
            yield return StartCoroutine(ExampleJoinBubble(testBubbleId));

            // Step 3: Get bubble feed
            yield return StartCoroutine(ExampleGetBubbleFeed(testBubbleId));

            // Step 4: Post to bubble
            yield return StartCoroutine(ExamplePostToBubble(testBubbleId, testPostContent));

            // Step 5: Refresh feed to see our new post
            yield return StartCoroutine(ExampleRefreshFeed(testBubbleId));
        }

        Debug.Log("[BUBBLE_EXAMPLE] Example workflow completed!");
    }

    /// <summary>
    /// Example: Fetch and display available bubbles
    /// </summary>
    public IEnumerator ExampleFetchBubbles()
    {
        Debug.Log("[BUBBLE_EXAMPLE] Fetching bubbles...");
        bool completed = false;
        bool hasError = false;

        yield return BubbleHandler.Instance.FetchBubbles(
            // Success callback
            (bubbles) => {
                currentBubbles = bubbles;
                Debug.Log($"[BUBBLE_EXAMPLE] Successfully fetched {bubbles.Count} bubbles:");
                foreach (var bubble in bubbles)
                {
                    Debug.Log($"  - {bubble.name} ({bubble.type}) - {bubble.memberCount} members");
                }
                completed = true;
            },
            // Error callback
            (error) => {
                Debug.LogError($"[BUBBLE_EXAMPLE] Failed to fetch bubbles: {error}");
                hasError = true;
                completed = true;
            }
        );

        // Wait for completion
        yield return new WaitUntil(() => completed);

        if (hasError)
        {
            Debug.LogError("[BUBBLE_EXAMPLE] Cannot continue without bubble list");
        }
    }

    /// <summary>
    /// Example: Join a specific bubble
    /// </summary>
    public IEnumerator ExampleJoinBubble(string bubbleId)
    {
        Debug.Log($"[BUBBLE_EXAMPLE] Joining bubble: {bubbleId}");
        bool completed = false;
        bool hasError = false;

        yield return BubbleHandler.Instance.JoinBubble(
            bubbleId,
            // Success callback
            () => {
                Debug.Log($"[BUBBLE_EXAMPLE] Successfully joined bubble: {bubbleId}");
                completed = true;
            },
            // Error callback
            (error) => {
                Debug.LogError($"[BUBBLE_EXAMPLE] Failed to join bubble: {error}");
                hasError = true;
                completed = true;
            }
        );

        // Wait for completion
        yield return new WaitUntil(() => completed);
    }

    /// <summary>
    /// Example: Get and display bubble feed
    /// </summary>
    public IEnumerator ExampleGetBubbleFeed(string bubbleId)
    {
        Debug.Log($"[BUBBLE_EXAMPLE] Getting feed for bubble: {bubbleId}");
        bool completed = false;
        bool hasError = false;

        yield return BubbleHandler.Instance.GetBubbleFeed(
            bubbleId,
            // Success callback
            (posts) => {
                currentFeed = posts;
                Debug.Log($"[BUBBLE_EXAMPLE] Successfully retrieved {posts.Count} posts:");
                foreach (var post in posts)
                {
                    Debug.Log($"  - {post.username}: {post.content.Substring(0, Mathf.Min(50, post.content.Length))}...");
                }
                completed = true;
            },
            // Error callback
            (error) => {
                Debug.LogError($"[BUBBLE_EXAMPLE] Failed to get feed: {error}");
                hasError = true;
                completed = true;
            }
        );

        // Wait for completion
        yield return new WaitUntil(() => completed);
    }

    /// <summary>
    /// Example: Post content to bubble
    /// </summary>
    public IEnumerator ExamplePostToBubble(string bubbleId, string content)
    {
        Debug.Log($"[BUBBLE_EXAMPLE] Posting to bubble: {bubbleId}");
        bool completed = false;
        bool hasError = false;

        // Validate content length
        if (!Config.IsValidPostContent(content))
        {
            Debug.LogError($"[BUBBLE_EXAMPLE] Invalid post content (length: {content.Length}/{Config.Bubbles.MAX_POST_LENGTH})");
            yield break;
        }

        yield return BubbleHandler.Instance.PostToBubble(
            bubbleId,
            content,
            // Success callback
            () => {
                Debug.Log($"[BUBBLE_EXAMPLE] Successfully posted to bubble: {bubbleId}");
                completed = true;
            },
            // Error callback
            (error) => {
                Debug.LogError($"[BUBBLE_EXAMPLE] Failed to post: {error}");
                hasError = true;
                completed = true;
            }
        );

        // Wait for completion
        yield return new WaitUntil(() => completed);
    }

    /// <summary>
    /// Example: Refresh feed to see updates
    /// </summary>
    public IEnumerator ExampleRefreshFeed(string bubbleId)
    {
        Debug.Log($"[BUBBLE_EXAMPLE] Refreshing feed for bubble: {bubbleId}");
        bool completed = false;

        yield return BubbleHandler.Instance.RefreshFeed(
            bubbleId,
            // Success callback
            (posts) => {
                currentFeed = posts;
                Debug.Log($"[BUBBLE_EXAMPLE] Feed refreshed - now showing {posts.Count} posts");
                completed = true;
            },
            // Error callback
            (error) => {
                Debug.LogError($"[BUBBLE_EXAMPLE] Failed to refresh feed: {error}");
                completed = true;
            }
        );

        // Wait for completion
        yield return new WaitUntil(() => completed);
    }

    /// <summary>
    /// Public method to manually trigger bubble list fetch
    /// </summary>
    public void FetchBubblesButton()
    {
        if (Config.ENABLE_BUBBLES && BubbleHandler.Instance != null)
        {
            StartCoroutine(ExampleFetchBubbles());
        }
        else
        {
            Debug.LogWarning("[BUBBLE_EXAMPLE] Bubbles not available");
        }
    }

    /// <summary>
    /// Public method to manually join a bubble
    /// </summary>
    public void JoinBubbleButton()
    {
        if (!string.IsNullOrEmpty(testBubbleId))
        {
            StartCoroutine(ExampleJoinBubble(testBubbleId));
        }
        else
        {
            Debug.LogWarning("[BUBBLE_EXAMPLE] No bubble ID specified");
        }
    }

    /// <summary>
    /// Public method to manually post to bubble
    /// </summary>
    public void PostToBubbleButton()
    {
        if (!string.IsNullOrEmpty(testBubbleId) && !string.IsNullOrEmpty(testPostContent))
        {
            StartCoroutine(ExamplePostToBubble(testBubbleId, testPostContent));
        }
        else
        {
            Debug.LogWarning("[BUBBLE_EXAMPLE] Missing bubble ID or content");
        }
    }

    /// <summary>
    /// Public method to manually refresh feed
    /// </summary>
    public void RefreshFeedButton()
    {
        if (!string.IsNullOrEmpty(testBubbleId))
        {
            StartCoroutine(ExampleRefreshFeed(testBubbleId));
        }
        else
        {
            Debug.LogWarning("[BUBBLE_EXAMPLE] No bubble ID specified");
        }
    }

    /// <summary>
    /// Handle authentication token from external login system
    /// </summary>
    public void SetAuthenticationToken(string token)
    {
        if (BubbleHandler.Instance != null)
        {
            BubbleHandler.Instance.SetAuthToken(token);
            Debug.Log("[BUBBLE_EXAMPLE] Authentication token updated");
        }
    }

    /// <summary>
    /// Clear authentication on logout
    /// </summary>
    public void ClearAuthentication()
    {
        if (BubbleHandler.Instance != null)
        {
            BubbleHandler.Instance.ClearAuthToken();
            Debug.Log("[BUBBLE_EXAMPLE] Authentication cleared");
        }
    }

    // Unity Editor Debug Info
    #if UNITY_EDITOR
    [Header("Debug Info")]
    [SerializeField] private bool showDebugInfo = true;

    void OnGUI()
    {
        if (!showDebugInfo) return;

        GUILayout.BeginArea(new Rect(10, 10, 300, 400));
        GUILayout.Label("Brrow Bubbles Debug", GUI.skin.box);

        GUILayout.Label($"Feature Enabled: {Config.ENABLE_BUBBLES}");
        GUILayout.Label($"Handler Available: {BubbleHandler.Instance != null}");
        if (BubbleHandler.Instance != null)
        {
            GUILayout.Label($"Authenticated: {BubbleHandler.Instance.IsAuthenticated()}");
        }
        GUILayout.Label($"Current Bubbles: {currentBubbles.Count}");
        GUILayout.Label($"Current Feed: {currentFeed.Count}");

        GUILayout.Space(10);

        if (GUILayout.Button("Fetch Bubbles"))
        {
            FetchBubblesButton();
        }

        if (GUILayout.Button("Join Test Bubble"))
        {
            JoinBubbleButton();
        }

        if (GUILayout.Button("Post to Bubble"))
        {
            PostToBubbleButton();
        }

        if (GUILayout.Button("Refresh Feed"))
        {
            RefreshFeedButton();
        }

        GUILayout.EndArea();
    }
    #endif
}