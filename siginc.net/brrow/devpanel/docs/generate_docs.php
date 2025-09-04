<?php
function generateDocumentation($section) {
    switch($section) {
        case 'ios':
            generateIOSDocumentation();
            break;
        case 'php':
            generatePHPDocumentation();
            break;
        case 'api':
            generateAPIDocumentation();
            break;
        case 'database':
            generateDatabaseDocumentation();
            break;
        case 'architecture':
            generateArchitectureDocumentation();
            break;
    }
}

function generateIOSDocumentation() {
    ?>
    <h2 class="section-header">iOS/Swift App Documentation</h2>
    
    <div class="alert alert-info">
        <strong>Quick Start:</strong> The Brrow iOS app is built with SwiftUI and follows MVVM architecture.
    </div>
    
    <h3 class="section-header">Core Components</h3>
    
    <!-- APIClient -->
    <div class="function-card">
        <h4>📡 APIClient</h4>
        <p><strong>Location:</strong> <code>/Brrow/Services/APIClient.swift</code></p>
        <p><strong>Purpose:</strong> Centralized network layer for all API communications</p>
        
        <h5>Key Functions:</h5>
        
        <div class="mb-3">
            <code><strong>createListing</strong></code>
            <span class="return-type">-> AnyPublisher&lt;Listing, Error&gt;</span>
            <p>Creates a new listing with images</p>
            <div>
                <span class="param-badge">title: String</span>
                <span class="param-badge">description: String</span>
                <span class="param-badge">price: Double</span>
                <span class="param-badge">images: [UIImage]</span>
            </div>
            <pre class="code-block"><code class="language-swift">func createListing(
    title: String,
    description: String, 
    price: Double,
    priceType: PriceType,
    category: String,
    location: Location,
    images: [UIImage]
) -> AnyPublisher&lt;Listing, Error&gt;</code></pre>
        </div>
        
        <div class="mb-3">
            <code><strong>fetchListings</strong></code>
            <span class="return-type">-> AnyPublisher&lt;[Listing], Error&gt;</span>
            <p>Fetches marketplace listings with filters</p>
            <div>
                <span class="param-badge">searchQuery: String?</span>
                <span class="param-badge">category: String?</span>
                <span class="param-badge">location: Location?</span>
                <span class="param-badge">radius: Double</span>
            </div>
        </div>
        
        <div class="mb-3">
            <code><strong>uploadFileData</strong></code>
            <span class="return-type">async throws -> UploadResponse</span>
            <p>Uploads images to server with entity context</p>
            <div>
                <span class="param-badge">imageData: Data</span>
                <span class="param-badge">entityType: String</span>
                <span class="param-badge">entityId: String</span>
            </div>
            <pre class="code-block"><code class="language-swift">// Example usage:
let response = try await apiClient.uploadFileData(
    imageData,
    entityType: "listings",
    entityId: listingId
)</code></pre>
        </div>
    </div>
    
    <!-- AuthManager -->
    <div class="function-card">
        <h4>🔐 AuthManager</h4>
        <p><strong>Location:</strong> <code>/Brrow/Services/AuthManager.swift</code></p>
        <p><strong>Purpose:</strong> Manages user authentication, sessions, and tokens</p>
        
        <h5>Key Properties:</h5>
        <div class="mb-3">
            <code><strong>currentUser</strong></code>
            <span class="return-type">@Published User?</span>
            <p>Current authenticated user object</p>
        </div>
        
        <div class="mb-3">
            <code><strong>isAuthenticated</strong></code>
            <span class="return-type">Bool</span>
            <p>Returns true if user is logged in</p>
        </div>
        
        <h5>Key Functions:</h5>
        <div class="mb-3">
            <code><strong>signIn</strong></code>
            <span class="return-type">async throws -> User</span>
            <div>
                <span class="param-badge">email: String</span>
                <span class="param-badge">password: String</span>
            </div>
        </div>
        
        <div class="mb-3">
            <code><strong>signInWithApple</strong></code>
            <span class="return-type">async throws -> User</span>
            <p>Handles Apple Sign In flow</p>
        </div>
    </div>
    
    <!-- ImageCacheManager -->
    <div class="function-card">
        <h4>🖼️ ImageCacheManager</h4>
        <p><strong>Location:</strong> <code>/Brrow/Services/ImageCacheManager.swift</code></p>
        <p><strong>Purpose:</strong> Advanced image caching with memory and disk storage</p>
        
        <h5>Key Functions:</h5>
        <div class="mb-3">
            <code><strong>loadImage</strong></code>
            <span class="return-type">async throws -> UIImage</span>
            <p>Loads image from cache or network</p>
            <div>
                <span class="param-badge">from: String (URL)</span>
            </div>
            <pre class="code-block"><code class="language-swift">// Caching flow:
// 1. Check memory cache (instant)
// 2. Check disk cache (fast)  
// 3. Download from network (slower)
// 4. Store in both caches</code></pre>
        </div>
    </div>
    
    <!-- ViewModels -->
    <div class="function-card">
        <h4>📱 Key ViewModels</h4>
        
        <h5>CreateListingViewModel</h5>
        <p><strong>Location:</strong> <code>/Brrow/ViewModels/CreateListingViewModel.swift</code></p>
        <ul>
            <li>Handles listing creation flow</li>
            <li>Manages image processing and upload</li>
            <li>Validates input data</li>
        </ul>
        
        <h5>MarketplaceViewModel</h5>
        <p><strong>Location:</strong> <code>/Brrow/ViewModels/MarketplaceViewModel.swift</code></p>
        <ul>
            <li>Manages marketplace listings</li>
            <li>Handles search and filters</li>
            <li>Implements infinite scroll</li>
        </ul>
        
        <h5>ListingDetailViewModel</h5>
        <p><strong>Location:</strong> <code>/Brrow/ViewModels/ListingDetailViewModel.swift</code></p>
        <ul>
            <li>Manages listing detail data</li>
            <li>Handles favorites and offers</li>
            <li>Loads seller information</li>
        </ul>
    </div>
    
    <!-- Data Models -->
    <div class="function-card">
        <h4>📊 Data Models</h4>
        <p><strong>Location:</strong> <code>/Brrow/Models/</code></p>
        
        <h5>Core Models:</h5>
        <pre class="code-block"><code class="language-swift">struct Listing: Codable {
    let id: Int
    let listingId: String  // Format: lst_xxxxx
    let title: String
    let description: String
    let price: Double
    let priceType: PriceType
    let category: String
    let location: Location
    let images: [String]  // URLs
    let ownerId: Int
    let status: String
    let createdAt: Date
}

struct User: Codable {
    let id: Int
    let apiId: String  // Format: usr_xxxxx
    let username: String
    let email: String
    let profilePicture: String?
    let rating: Double?
    let isVerified: Bool
}

enum PriceType: String, Codable {
    case free = "free"
    case fixed = "fixed"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}</code></pre>
    </div>
    
    <!-- Image Upload System -->
    <div class="function-card">
        <h4>📤 Image Upload System</h4>
        <p><strong>Location:</strong> <code>/Brrow/Services/HighQualityImageProcessor.swift</code></p>
        
        <h5>Upload Flow:</h5>
        <ol>
            <li><strong>Selection:</strong> User picks images from photo library</li>
            <li><strong>Processing:</strong> Images resized to max 1200px, JPEG quality 0.8</li>
            <li><strong>Upload:</strong> Base64 encoded and sent to server</li>
            <li><strong>Storage:</strong> Server stores at <code>/uploads/{entity_type}/{entity_id}/</code></li>
            <li><strong>Response:</strong> Returns URLs for image and thumbnail</li>
        </ol>
        
        <pre class="code-block"><code class="language-swift">// Image processing example
let processor = HighQualityImageProcessor()
let processedImages = try await processor.processImages(
    selectedImages,
    for: .listing,
    progress: { progress in
        print("Progress: \(progress)")
    }
)

// Upload to server
let urls = try await processor.uploadProcessedImages(
    processedImages,
    to: "api_upload_file.php",
    entityType: "listings",
    entityId: listingId
)</code></pre>
    </div>
    <?php
}

function generatePHPDocumentation() {
    ?>
    <h2 class="section-header">PHP/Backend Documentation</h2>
    
    <div class="alert alert-info">
        <strong>Server Environment:</strong> PHP 8.0+, PostgreSQL 13+, Apache with mod_rewrite
    </div>
    
    <h3 class="section-header">API Endpoints</h3>
    
    <!-- Authentication -->
    <div class="function-card">
        <h4>🔐 Authentication Endpoints</h4>
        
        <div class="mb-3">
            <code><strong>POST /api_signin.php</strong></code>
            <p>User login with email/password</p>
            <div>Request Body:</div>
            <pre class="code-block"><code class="language-json">{
    "email": "user@example.com",
    "password": "securepassword"
}</code></pre>
            <div>Response:</div>
            <pre class="code-block"><code class="language-json">{
    "success": true,
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
        "id": 1,
        "api_id": "usr_xxxxx",
        "username": "johndoe",
        "email": "user@example.com"
    }
}</code></pre>
        </div>
        
        <div class="mb-3">
            <code><strong>POST /api_signup.php</strong></code>
            <p>Register new user account</p>
            <div>Request Body:</div>
            <pre class="code-block"><code class="language-json">{
    "username": "johndoe",
    "email": "user@example.com",
    "password": "securepassword"
}</code></pre>
        </div>
        
        <div class="mb-3">
            <code><strong>POST /api_signin_with_apple.php</strong></code>
            <p>Apple Sign In integration</p>
            <div>Request Body:</div>
            <pre class="code-block"><code class="language-json">{
    "apple_user_id": "xxxxx",
    "email": "user@privaterelay.appleid.com",
    "full_name": "John Doe",
    "identity_token": "xxxxx"
}</code></pre>
        </div>
    </div>
    
    <!-- Listings -->
    <div class="function-card">
        <h4>📦 Listing Management</h4>
        
        <div class="mb-3">
            <code><strong>POST /api_create_listing_with_images.php</strong></code>
            <p>Create listing with multiple images</p>
            <div>Headers:</div>
            <pre class="code-block"><code>Authorization: Bearer {token}
X-User-API-ID: usr_xxxxx</code></pre>
            <div>Request Body:</div>
            <pre class="code-block"><code class="language-json">{
    "title": "Mountain Bike",
    "description": "Great condition bike",
    "price": 50,
    "price_type": "daily",
    "category": "Sports Equipment",
    "location": {
        "latitude": 37.7749,
        "longitude": -122.4194
    },
    "images": [
        "data:image/jpeg;base64,/9j/4AAQ...",
        "data:image/jpeg;base64,/9j/4AAQ..."
    ]
}</code></pre>
        </div>
        
        <div class="mb-3">
            <code><strong>GET /api_fetch_listings.php</strong></code>
            <p>Fetch marketplace listings</p>
            <div>Query Parameters:</div>
            <ul>
                <li><code>search</code> - Search query</li>
                <li><code>category</code> - Filter by category</li>
                <li><code>lat/lng</code> - Location coordinates</li>
                <li><code>radius</code> - Search radius in miles</li>
                <li><code>page</code> - Page number</li>
                <li><code>limit</code> - Results per page</li>
            </ul>
        </div>
    </div>
    
    <!-- File Upload -->
    <div class="function-card">
        <h4>📤 File Upload System</h4>
        <p><strong>Location:</strong> <code>/brrow/includes/upload_handler_v2.php</code></p>
        
        <div class="mb-3">
            <code><strong>POST /api_upload_file.php</strong></code>
            <p>Upload images with entity context</p>
            <div>Request Body:</div>
            <pre class="code-block"><code class="language-json">{
    "image": "iVBORw0KGgoAAAANS...",  // Base64
    "entity_type": "listings",
    "entity_id": "lst_abc123",
    "media_type": "image",
    "fileName": "image_1.jpg"
}</code></pre>
            
            <div>Server Processing:</div>
            <pre class="code-block"><code class="language-php">// File storage structure:
/uploads/
├── listings/
│   └── lst_abc123/
│       ├── listing_lst_abc123_20250903T104500Z.jpg
│       └── thumbnails/
│           └── thumb_listing_lst_abc123_20250903T104500Z.jpg
├── users/
│   └── usr_xxxxx/
│       └── profile_images/
│           └── profile.jpg
└── seeks/
    └── seek_xxxxx/
        └── seek_xxxxx_20250903T104500Z.jpg</code></pre>
        </div>
    </div>
    
    <!-- Database Functions -->
    <div class="function-card">
        <h4>🗄️ Database Functions</h4>
        <p><strong>Location:</strong> <code>/brrow/includes/db_functions.php</code></p>
        
        <h5>Key Functions:</h5>
        <pre class="code-block"><code class="language-php">// Get database connection
function getDBConnection() {
    $host = $_ENV['DB_HOST'] ?? 'localhost';
    $dbname = $_ENV['DB_NAME'] ?? 'brrowapp_main';
    $user = $_ENV['DB_USER'] ?? 'brrowapp_admin';
    $password = $_ENV['DB_PASSWORD'];
    
    $dsn = "pgsql:host=$host;dbname=$dbname";
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    return $pdo;
}

// Generate unique IDs
function generateListingId() {
    return 'lst_' . uniqid() . '.' . mt_rand(10000000, 99999999);
}

function generateUserId() {
    return 'usr_' . uniqid() . '.' . mt_rand(10000000, 99999999);
}</code></pre>
    </div>
    <?php
}

function generateAPIDocumentation() {
    ?>
    <h2 class="section-header">API Documentation</h2>
    
    <div class="alert alert-warning">
        <strong>Base URL:</strong> https://brrowapp.com/
        <br>
        <strong>Authentication:</strong> JWT Bearer Token required for most endpoints
    </div>
    
    <h3 class="section-header">API Response Format</h3>
    
    <div class="function-card">
        <h4>Standard Response Structure</h4>
        <pre class="code-block"><code class="language-json">// Success Response
{
    "success": true,
    "data": { ... },
    "message": "Operation successful"
}

// Error Response  
{
    "success": false,
    "error": "Error description",
    "code": "ERROR_CODE"
}</code></pre>
    </div>
    
    <h3 class="section-header">Complete Endpoint Reference</h3>
    
    <div class="function-card">
        <h4>📋 All Available Endpoints</h4>
        
        <table class="table">
            <thead>
                <tr>
                    <th>Method</th>
                    <th>Endpoint</th>
                    <th>Description</th>
                    <th>Auth Required</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><span class="badge bg-success">POST</span></td>
                    <td><code>/api_signin.php</code></td>
                    <td>User login</td>
                    <td>No</td>
                </tr>
                <tr>
                    <td><span class="badge bg-success">POST</span></td>
                    <td><code>/api_signup.php</code></td>
                    <td>User registration</td>
                    <td>No</td>
                </tr>
                <tr>
                    <td><span class="badge bg-primary">GET</span></td>
                    <td><code>/api_fetch_listings.php</code></td>
                    <td>Get marketplace listings</td>
                    <td>Optional</td>
                </tr>
                <tr>
                    <td><span class="badge bg-success">POST</span></td>
                    <td><code>/api_create_listing_with_images.php</code></td>
                    <td>Create new listing</td>
                    <td>Yes</td>
                </tr>
                <tr>
                    <td><span class="badge bg-warning">PUT</span></td>
                    <td><code>/api_update_listing.php</code></td>
                    <td>Update listing</td>
                    <td>Yes</td>
                </tr>
                <tr>
                    <td><span class="badge bg-danger">DELETE</span></td>
                    <td><code>/api_delete_listing.php</code></td>
                    <td>Delete listing</td>
                    <td>Yes</td>
                </tr>
                <tr>
                    <td><span class="badge bg-success">POST</span></td>
                    <td><code>/api_upload_file.php</code></td>
                    <td>Upload image</td>
                    <td>Yes</td>
                </tr>
                <tr>
                    <td><span class="badge bg-primary">GET</span></td>
                    <td><code>/api_user_profile.php</code></td>
                    <td>Get user profile</td>
                    <td>Yes</td>
                </tr>
                <tr>
                    <td><span class="badge bg-success">POST</span></td>
                    <td><code>/api_send_message.php</code></td>
                    <td>Send chat message</td>
                    <td>Yes</td>
                </tr>
                <tr>
                    <td><span class="badge bg-primary">GET</span></td>
                    <td><code>/api_fetch_conversations.php</code></td>
                    <td>Get user conversations</td>
                    <td>Yes</td>
                </tr>
            </tbody>
        </table>
    </div>
    <?php
}

function generateDatabaseDocumentation() {
    ?>
    <h2 class="section-header">Database Schema</h2>
    
    <div class="alert alert-info">
        <strong>Database:</strong> PostgreSQL 13+
        <br>
        <strong>Schema:</strong> public
    </div>
    
    <h3 class="section-header">Core Tables</h3>
    
    <div class="function-card">
        <h4>👤 users</h4>
        <p>Stores user account information</p>
        <pre class="code-block"><code class="language-sql">CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    api_id VARCHAR(50) UNIQUE NOT NULL, -- Format: usr_xxxxx
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    profile_picture_url TEXT,
    bio TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    apple_user_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);</code></pre>
    </div>
    
    <div class="function-card">
        <h4>📦 listings</h4>
        <p>Marketplace listings</p>
        <pre class="code-block"><code class="language-sql">CREATE TABLE listings (
    id SERIAL PRIMARY KEY,
    listing_id VARCHAR(100) UNIQUE NOT NULL, -- Format: lst_xxxxx
    owner_id INTEGER REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) DEFAULT 0,
    price_type VARCHAR(20), -- free, fixed, daily, weekly, monthly
    category VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending_review',
    location_lat DECIMAL(10,7),
    location_lng DECIMAL(10,7),
    address TEXT,
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);</code></pre>
    </div>
    
    <div class="function-card">
        <h4>🖼️ listing_images</h4>
        <p>Images associated with listings</p>
        <pre class="code-block"><code class="language-sql">CREATE TABLE listing_images (
    id SERIAL PRIMARY KEY,
    listing_id VARCHAR(100) REFERENCES listings(listing_id),
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    width INTEGER,
    height INTEGER,
    file_size INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);</code></pre>
    </div>
    
    <div class="function-card">
        <h4>💬 conversations</h4>
        <p>Chat conversations between users</p>
        <pre class="code-block"><code class="language-sql">CREATE TABLE conversations (
    conversation_id SERIAL PRIMARY KEY,
    participant1_id INTEGER REFERENCES users(user_id),
    participant2_id INTEGER REFERENCES users(user_id),
    listing_id VARCHAR(100) REFERENCES listings(listing_id),
    last_message_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);</code></pre>
    </div>
    
    <div class="function-card">
        <h4>📨 messages</h4>
        <p>Individual chat messages</p>
        <pre class="code-block"><code class="language-sql">CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(conversation_id),
    sender_id INTEGER REFERENCES users(user_id),
    content TEXT NOT NULL,
    media_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);</code></pre>
    </div>
    <?php
}

function generateArchitectureDocumentation() {
    ?>
    <h2 class="section-header">System Architecture</h2>
    
    <div class="alert alert-success">
        <strong>Architecture Pattern:</strong> Client-Server with RESTful API
    </div>
    
    <h3 class="section-header">System Overview</h3>
    
    <div class="function-card">
        <h4>🏗️ Architecture Diagram</h4>
        <pre class="code-block"><code>┌─────────────────────────────────────────────────────┐
│                   iOS App (SwiftUI)                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │   Views    │  │ ViewModels │  │  Services  │    │
│  └────────────┘  └────────────┘  └────────────┘    │
└─────────────────────────┬───────────────────────────┘
                          │ HTTPS/JSON
                          ▼
┌─────────────────────────────────────────────────────┐
│                    API Layer (PHP)                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │    Auth    │  │  Business  │  │   Upload   │    │
│  │  Endpoints │  │   Logic    │  │  Handler   │    │
│  └────────────┘  └────────────┘  └────────────┘    │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                Database (PostgreSQL)                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │   Users    │  │  Listings  │  │  Messages  │    │
│  └────────────┘  └────────────┘  └────────────┘    │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│              File Storage (Server FS)                │
│         /uploads/listings/, /uploads/users/          │
└─────────────────────────────────────────────────────┘</code></pre>
    </div>
    
    <h3 class="section-header">Data Flow</h3>
    
    <div class="function-card">
        <h4>📊 Listing Creation Flow</h4>
        <ol>
            <li><strong>User Input:</strong> User fills form in CreateListingView</li>
            <li><strong>Validation:</strong> CreateListingViewModel validates data</li>
            <li><strong>Image Processing:</strong> HighQualityImageProcessor resizes images</li>
            <li><strong>API Call:</strong> APIClient sends data to server</li>
            <li><strong>Server Processing:</strong>
                <ul>
                    <li>Validate JWT token</li>
                    <li>Generate listing_id</li>
                    <li>Store in database</li>
                    <li>Process and save images</li>
                </ul>
            </li>
            <li><strong>Response:</strong> Return listing object with URLs</li>
            <li><strong>UI Update:</strong> Navigate to listing detail</li>
        </ol>
    </div>
    
    <h3 class="section-header">Security</h3>
    
    <div class="function-card">
        <h4>🔒 Security Measures</h4>
        
        <h5>Authentication:</h5>
        <ul>
            <li>JWT tokens with 30-day expiration</li>
            <li>Bcrypt password hashing</li>
            <li>Apple Sign In integration</li>
        </ul>
        
        <h5>File Upload Security:</h5>
        <ul>
            <li>MIME type validation</li>
            <li>File size limits (10MB images, 100MB videos)</li>
            <li>No PHP execution in upload directories</li>
            <li>.htaccess protection</li>
        </ul>
        
        <h5>API Security:</h5>
        <ul>
            <li>Bearer token authentication</li>
            <li>Rate limiting</li>
            <li>Input validation and sanitization</li>
            <li>Prepared statements for SQL queries</li>
        </ul>
    </div>
    
    <h3 class="section-header">Performance Optimizations</h3>
    
    <div class="function-card">
        <h4>⚡ Performance Features</h4>
        
        <h5>iOS App:</h5>
        <ul>
            <li>Image caching (memory + disk)</li>
            <li>Lazy loading with infinite scroll</li>
            <li>Background uploads</li>
            <li>Optimistic UI updates</li>
        </ul>
        
        <h5>Server:</h5>
        <ul>
            <li>Database indexing on key columns</li>
            <li>Thumbnail generation</li>
            <li>CDN-ready URL structure</li>
            <li>Efficient pagination</li>
        </ul>
    </div>
    <?php
}
?>