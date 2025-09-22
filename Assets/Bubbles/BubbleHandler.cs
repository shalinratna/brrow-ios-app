using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;

[System.Serializable]
public class BubbleGroup
{
    public string id;
    public string name;
    public string description;
    public string ownerId;
    public string type;
    public DateTime createdAt;
    public int memberCount;
}

[System.Serializable]
public class BubblePost
{
    public string id;
    public string groupId;
    public string userId;
    public string content;
    public string username;
    public DateTime createdAt;
}

[System.Serializable]
public class BubbleFeed
{
    public bool success;
    public List<BubblePost> posts;
    public int totalCount;
}

public class BubbleHandler : MonoBehaviour
{
    private static BubbleHandler instance;
    public static BubbleHandler Instance => instance;

    [Header("Bubble Configuration")]
    public string baseApiUrl = "https://brrow-backend-nodejs-production.up.railway.app/api/bubbles";

    private string authToken;

    void Awake()
    {
        // Feature flag check
        if (!Config.ENABLE_BUBBLES)
        {
            Debug.Log("[BUBBLES] Feature disabled - BubbleHandler inactive");
            gameObject.SetActive(false);
            return;
        }

        if (instance == null)
        {
            instance = this;
            DontDestroyOnLoad(gameObject);
            Debug.Log("[BUBBLES] BubbleHandler initialized");
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public void SetAuthToken(string token)
    {
        authToken = token;
        Debug.Log("[BUBBLES] Auth token set");
    }

    // FETCH BUBBLES
    public IEnumerator FetchBubbles(Action<List<BubbleGroup>> onComplete, Action<string> onError)
    {
        if (!Config.ENABLE_BUBBLES)
        {
            Debug.LogWarning("[BUBBLES] Feature disabled - cannot fetch bubbles");
            onError?.Invoke("Bubbles feature is disabled");
            yield break;
        }

        if (string.IsNullOrEmpty(authToken))
        {
            Debug.LogError("[BUBBLES] Auth token not set");
            onError?.Invoke("Authentication required");
            yield break;
        }

        Debug.Log("[BUBBLES] Fetching bubbles from API...");

        using (UnityWebRequest request = UnityWebRequest.Get($"{baseApiUrl}/list"))
        {
            request.SetRequestHeader("Authorization", $"Bearer {authToken}");
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                try
                {
                    Debug.Log($"[BUBBLES] Fetch response: {request.downloadHandler.text}");
                    var response = JsonUtility.FromJson<BubbleListResponse>(request.downloadHandler.text);
                    Debug.Log($"[BUBBLES] Successfully fetched {response.bubbles?.Count ?? 0} bubbles");
                    onComplete?.Invoke(response.bubbles ?? new List<BubbleGroup>());
                }
                catch (Exception e)
                {
                    Debug.LogError($"[BUBBLES] Parse error: {e.Message}");
                    onError?.Invoke($"Parse error: {e.Message}");
                }
            }
            else
            {
                Debug.LogError($"[BUBBLES] Fetch request failed: {request.error}");
                onError?.Invoke($"Request failed: {request.error}");
            }
        }
    }

    // JOIN BUBBLE
    public IEnumerator JoinBubble(string bubbleId, Action onComplete, Action<string> onError)
    {
        if (!Config.ENABLE_BUBBLES)
        {
            Debug.LogWarning("[BUBBLES] Feature disabled - cannot join bubble");
            onError?.Invoke("Bubbles feature is disabled");
            yield break;
        }

        if (string.IsNullOrEmpty(authToken))
        {
            Debug.LogError("[BUBBLES] Auth token not set");
            onError?.Invoke("Authentication required");
            yield break;
        }

        if (string.IsNullOrEmpty(bubbleId))
        {
            Debug.LogError("[BUBBLES] Bubble ID required");
            onError?.Invoke("Bubble ID is required");
            yield break;
        }

        Debug.Log($"[BUBBLES] Joining bubble: {bubbleId}");

        using (UnityWebRequest request = UnityWebRequest.Post($"{baseApiUrl}/{bubbleId}/join", "{}"))
        {
            request.SetRequestHeader("Authorization", $"Bearer {authToken}");
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                Debug.Log($"[BUBBLES] Successfully joined bubble: {bubbleId}");
                onComplete?.Invoke();
            }
            else
            {
                Debug.LogError($"[BUBBLES] Join failed for bubble {bubbleId}: {request.error}");
                onError?.Invoke($"Join failed: {request.error}");
            }
        }
    }

    // POST TO BUBBLE
    public IEnumerator PostToBubble(string bubbleId, string content, Action onComplete, Action<string> onError)
    {
        if (!Config.ENABLE_BUBBLES)
        {
            Debug.LogWarning("[BUBBLES] Feature disabled - cannot post to bubble");
            onError?.Invoke("Bubbles feature is disabled");
            yield break;
        }

        if (string.IsNullOrEmpty(authToken))
        {
            Debug.LogError("[BUBBLES] Auth token not set");
            onError?.Invoke("Authentication required");
            yield break;
        }

        if (string.IsNullOrEmpty(bubbleId))
        {
            Debug.LogError("[BUBBLES] Bubble ID required");
            onError?.Invoke("Bubble ID is required");
            yield break;
        }

        if (string.IsNullOrEmpty(content))
        {
            Debug.LogError("[BUBBLES] Content required");
            onError?.Invoke("Content is required");
            yield break;
        }

        if (content.Length > Config.Bubbles.MAX_POST_LENGTH)
        {
            Debug.LogError($"[BUBBLES] Content too long: {content.Length}/{Config.Bubbles.MAX_POST_LENGTH}");
            onError?.Invoke($"Content exceeds maximum length of {Config.Bubbles.MAX_POST_LENGTH} characters");
            yield break;
        }

        Debug.Log($"[BUBBLES] Posting to bubble {bubbleId}: {content.Substring(0, Math.Min(50, content.Length))}...");

        var postData = new { content = content };
        string jsonData = JsonUtility.ToJson(postData);

        using (UnityWebRequest request = UnityWebRequest.Post($"{baseApiUrl}/{bubbleId}/post", jsonData))
        {
            request.SetRequestHeader("Authorization", $"Bearer {authToken}");
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                Debug.Log($"[BUBBLES] Successfully posted to bubble: {bubbleId}");
                onComplete?.Invoke();
            }
            else
            {
                Debug.LogError($"[BUBBLES] Post failed for bubble {bubbleId}: {request.error}");
                onError?.Invoke($"Post failed: {request.error}");
            }
        }
    }

    // GET BUBBLE FEED
    public IEnumerator GetBubbleFeed(string bubbleId, Action<List<BubblePost>> onComplete, Action<string> onError)
    {
        if (!Config.ENABLE_BUBBLES)
        {
            Debug.LogWarning("[BUBBLES] Feature disabled - cannot get bubble feed");
            onError?.Invoke("Bubbles feature is disabled");
            yield break;
        }

        if (string.IsNullOrEmpty(authToken))
        {
            Debug.LogError("[BUBBLES] Auth token not set");
            onError?.Invoke("Authentication required");
            yield break;
        }

        if (string.IsNullOrEmpty(bubbleId))
        {
            Debug.LogError("[BUBBLES] Bubble ID required");
            onError?.Invoke("Bubble ID is required");
            yield break;
        }

        Debug.Log($"[BUBBLES] Getting feed for bubble: {bubbleId}");

        using (UnityWebRequest request = UnityWebRequest.Get($"{baseApiUrl}/{bubbleId}/feed"))
        {
            request.SetRequestHeader("Authorization", $"Bearer {authToken}");
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                try
                {
                    Debug.Log($"[BUBBLES] Feed response: {request.downloadHandler.text}");
                    var response = JsonUtility.FromJson<BubbleFeed>(request.downloadHandler.text);
                    Debug.Log($"[BUBBLES] Successfully retrieved {response.posts?.Count ?? 0} posts from bubble {bubbleId}");
                    onComplete?.Invoke(response.posts ?? new List<BubblePost>());
                }
                catch (Exception e)
                {
                    Debug.LogError($"[BUBBLES] Feed parse error: {e.Message}");
                    onError?.Invoke($"Parse error: {e.Message}");
                }
            }
            else
            {
                Debug.LogError($"[BUBBLES] Feed request failed for bubble {bubbleId}: {request.error}");
                onError?.Invoke($"Request failed: {request.error}");
            }
        }
    }

    // REFRESH FEED (Additional utility method)
    public IEnumerator RefreshFeed(string bubbleId, Action<List<BubblePost>> onComplete, Action<string> onError)
    {
        Debug.Log($"[BUBBLES] Refreshing feed for bubble: {bubbleId}");
        yield return GetBubbleFeed(bubbleId, onComplete, onError);
    }

    // GET BUBBLE DETAILS (Additional utility method)
    public IEnumerator GetBubbleDetails(string bubbleId, Action<BubbleGroup> onComplete, Action<string> onError)
    {
        if (!Config.ENABLE_BUBBLES)
        {
            Debug.LogWarning("[BUBBLES] Feature disabled - cannot get bubble details");
            onError?.Invoke("Bubbles feature is disabled");
            yield break;
        }

        if (string.IsNullOrEmpty(authToken))
        {
            Debug.LogError("[BUBBLES] Auth token not set");
            onError?.Invoke("Authentication required");
            yield break;
        }

        if (string.IsNullOrEmpty(bubbleId))
        {
            Debug.LogError("[BUBBLES] Bubble ID required");
            onError?.Invoke("Bubble ID is required");
            yield break;
        }

        Debug.Log($"[BUBBLES] Getting details for bubble: {bubbleId}");

        using (UnityWebRequest request = UnityWebRequest.Get($"{baseApiUrl}/{bubbleId}/details"))
        {
            request.SetRequestHeader("Authorization", $"Bearer {authToken}");
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                try
                {
                    Debug.Log($"[BUBBLES] Details response: {request.downloadHandler.text}");
                    var response = JsonUtility.FromJson<BubbleDetailsResponse>(request.downloadHandler.text);
                    Debug.Log($"[BUBBLES] Successfully retrieved details for bubble {bubbleId}");
                    onComplete?.Invoke(response.bubble);
                }
                catch (Exception e)
                {
                    Debug.LogError($"[BUBBLES] Details parse error: {e.Message}");
                    onError?.Invoke($"Parse error: {e.Message}");
                }
            }
            else
            {
                Debug.LogError($"[BUBBLES] Details request failed for bubble {bubbleId}: {request.error}");
                onError?.Invoke($"Request failed: {request.error}");
            }
        }
    }

    // UTILITY: Clear auth token on logout
    public void ClearAuthToken()
    {
        authToken = null;
        Debug.Log("[BUBBLES] Auth token cleared");
    }

    // UTILITY: Check if feature is enabled
    public bool IsEnabled()
    {
        return Config.ENABLE_BUBBLES;
    }

    // UTILITY: Check if authenticated
    public bool IsAuthenticated()
    {
        return !string.IsNullOrEmpty(authToken);
    }
}

[System.Serializable]
public class BubbleListResponse
{
    public bool success;
    public List<BubbleGroup> bubbles;
}

[System.Serializable]
public class BubbleDetailsResponse
{
    public bool success;
    public BubbleGroup bubble;
}

[System.Serializable]
public class BubblePostData
{
    public string content;
}