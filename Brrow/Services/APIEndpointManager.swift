import Foundation
import Network

/// Manages API endpoints with automatic failover and health checking
class APIEndpointManager: ObservableObject {
    static let shared = APIEndpointManager()
    
    @Published var currentEndpoint: String = ""
    @Published var isUsingBackup = false
    
    private let primaryEndpoint = "https://brrowapp.com"
    private let backupEndpoint = "https://brrow-backend-production.up.railway.app"
    
    private var endpoints: [Endpoint] = []
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "EndpointManager")
    
    struct Endpoint {
        let url: String
        let priority: Int
        var isHealthy: Bool = true
        var lastChecked: Date = Date()
        var responseTime: TimeInterval = 0
    }
    
    init() {
        // Initialize endpoints
        endpoints = [
            Endpoint(url: primaryEndpoint, priority: 1),
            Endpoint(url: backupEndpoint, priority: 2)
        ]
        
        // Set initial endpoint
        currentEndpoint = primaryEndpoint
        
        // Start network monitoring
        startNetworkMonitoring()
        
        // Check endpoint health on startup
        Task {
            await checkAllEndpoints()
        }
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Task {
                    await self.checkAllEndpoints()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    /// Get the best available endpoint
    func getBestEndpoint() async -> String {
        // Quick check if current endpoint is healthy
        if let current = endpoints.first(where: { $0.url == currentEndpoint }),
           current.isHealthy,
           Date().timeIntervalSince(current.lastChecked) < 60 { // Use cached result for 1 minute
            return currentEndpoint
        }
        
        // Check all endpoints
        await checkAllEndpoints()
        
        // Return the best healthy endpoint
        if let best = endpoints.filter({ $0.isHealthy }).sorted(by: { $0.priority < $1.priority }).first {
            DispatchQueue.main.async {
                self.currentEndpoint = best.url
                self.isUsingBackup = (best.url == self.backupEndpoint)
            }
            return best.url
        }
        
        // If no endpoints are healthy, return primary (app will show offline mode)
        return primaryEndpoint
    }
    
    /// Check health of all endpoints
    private func checkAllEndpoints() async {
        await withTaskGroup(of: (String, Bool, TimeInterval).self) { group in
            for i in 0..<endpoints.count {
                let endpoint = endpoints[i]
                group.addTask {
                    return await self.checkEndpointHealth(endpoint.url)
                }
            }
            
            for await (url, isHealthy, responseTime) in group {
                if let index = endpoints.firstIndex(where: { $0.url == url }) {
                    endpoints[index].isHealthy = isHealthy
                    endpoints[index].lastChecked = Date()
                    endpoints[index].responseTime = responseTime
                }
            }
        }
        
        // Update current endpoint if needed
        if let current = endpoints.first(where: { $0.url == currentEndpoint }),
           !current.isHealthy {
            // Switch to backup
            if let backup = endpoints.filter({ $0.isHealthy }).sorted(by: { $0.priority < $1.priority }).first {
                DispatchQueue.main.async {
                    self.currentEndpoint = backup.url
                    self.isUsingBackup = (backup.url == self.backupEndpoint)
                    
                    // Log the switch
                    print("🔄 Switched to \(self.isUsingBackup ? "backup" : "primary") endpoint: \(backup.url)")
                }
            }
        }
    }
    
    /// Check if a specific endpoint is healthy
    private func checkEndpointHealth(_ endpoint: String) async -> (String, Bool, TimeInterval) {
        let url = URL(string: "\(endpoint)/test_php_simple.php")!
        let startTime = Date()
        
        do {
            let request = URLRequest(url: url, timeoutInterval: 5)
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["success"] as? Bool == true {
                return (endpoint, true, responseTime)
            }
        } catch {
            print("❌ Endpoint \(endpoint) health check failed: \(error)")
        }
        
        return (endpoint, false, 999)
    }
    
    /// Report endpoint failure (called when a request fails)
    func reportEndpointFailure(_ endpoint: String) {
        if let index = endpoints.firstIndex(where: { $0.url == endpoint }) {
            endpoints[index].isHealthy = false
            
            Task {
                // Try to find a better endpoint
                _ = await getBestEndpoint()
            }
        }
    }
    
    /// Get status for UI display
    func getStatus() -> String {
        if isUsingBackup {
            return "Using backup server (Railway)"
        } else {
            return "Connected to primary server"
        }
    }
    
    /// Force refresh endpoint health
    func refreshEndpoints() async {
        await checkAllEndpoints()
    }
}

// MARK: - Updated APIClient Integration
extension APIClient {
    /// Get base URL with automatic failover
    func getBaseURL() async -> String {
        return await APIEndpointManager.shared.getBestEndpoint()
    }
    
    /// Make request with automatic failover
    func makeRequest<T: Decodable>(_ endpoint: String, 
                                   method: String = "GET", 
                                   body: Data? = nil) async throws -> T {
        let baseURL = await getBaseURL()
        let url = URL(string: "\(baseURL)/\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                return try JSONDecoder().decode(T.self, from: data)
            } else {
                // Report failure and try backup
                APIEndpointManager.shared.reportEndpointFailure(baseURL)
                
                // Retry with backup endpoint
                let backupURL = await getBaseURL()
                if backupURL != baseURL {
                    return try await makeRequest(endpoint, method: method, body: body)
                }
                
                throw APIError.serverError
            }
        } catch {
            // Report failure
            APIEndpointManager.shared.reportEndpointFailure(baseURL)
            throw error
        }
    }
}