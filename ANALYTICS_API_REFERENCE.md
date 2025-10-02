# Analytics API Reference - Quick Guide

## Base URL
```
https://brrow-backend-nodejs-production.up.railway.app
```

## Authentication
All admin endpoints require:
```
Authorization: Bearer <JWT_TOKEN>
```

---

## 📊 Admin Endpoints

### Platform Overview
Get high-level platform statistics.

```http
GET /api/analytics/overview
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_users": 1250,
    "active_users_30d": 450,
    "active_users_24h": 120,
    "total_listings": 3200,
    "active_listings": 2100,
    "total_transactions": 890,
    "completed_transactions": 750,
    "total_revenue": 12450.50,
    "platform_commission": 622.53
  }
}
```

---

### Revenue Analytics
Get revenue data over time.

```http
GET /api/analytics/revenue?start_date=2024-01-01&end_date=2024-12-31&interval=day
```

**Query Parameters:**
- `start_date` (optional): YYYY-MM-DD format, defaults to 30 days ago
- `end_date` (optional): YYYY-MM-DD format, defaults to today
- `interval` (optional): `day` | `week` | `month`, defaults to `day`

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_revenue": 50000.00,
      "platform_commission": 2500.00,
      "total_transactions": 450
    },
    "by_type": [
      {
        "type": "PURCHASE",
        "revenue": 30000.00,
        "commission": 1500.00,
        "count": 300
      },
      {
        "type": "RENTAL",
        "revenue": 20000.00,
        "commission": 1000.00,
        "count": 150
      }
    ],
    "time_series": [
      {
        "date": "2024-01-01",
        "platform_revenue": 125.50,
        "transaction_volume": 2510.00,
        "total_transactions": 15
      }
    ],
    "interval": "day"
  }
}
```

---

### User Growth Analytics
Get user signup and activity metrics.

```http
GET /api/analytics/users?start_date=2024-01-01&end_date=2024-12-31&interval=day
```

**Query Parameters:** Same as revenue endpoint

**Response:**
```json
{
  "success": true,
  "data": {
    "time_series": [
      {
        "date": "2024-01-01",
        "new_users": 15,
        "active_users": 320
      }
    ],
    "interval": "day"
  }
}
```

---

### Listing Analytics
Get listing metrics by category.

```http
GET /api/analytics/listings
```

**Response:**
```json
{
  "success": true,
  "data": {
    "by_category": [
      {
        "category_id": "cat-123",
        "category_name": "Electronics",
        "listing_count": 450,
        "average_price": 299.99,
        "transaction_count": 125
      }
    ]
  }
}
```

---

### Transaction Analytics
Get transaction metrics.

```http
GET /api/analytics/transactions?start_date=2024-01-01&end_date=2024-12-31
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_transactions": 450,
    "total_volume": 50000.00,
    "platform_commission": 2500.00,
    "by_type": [
      {
        "type": "PURCHASE",
        "revenue": 30000.00,
        "commission": 1500.00,
        "count": 300
      }
    ]
  }
}
```

---

### Top Users
Get top performing users.

```http
GET /api/analytics/top/users?limit=10&metric=revenue
```

**Query Parameters:**
- `limit` (optional): Number of results, defaults to 10
- `metric` (optional): `revenue` | `sales` | `listings`, defaults to `revenue`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "user": {
        "id": "user-123",
        "username": "topse ller",
        "profile_picture_url": "https://...",
        "average_rating": 4.8
      },
      "total_revenue": 5000.00,
      "total_sales": 45,
      "total_listings": 12,
      "average_rating": 4.8
    }
  ]
}
```

---

### Top Listings
Get most viewed listings.

```http
GET /api/analytics/top/listings?limit=10
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "listing-123",
      "title": "iPhone 15 Pro",
      "price": 999.00,
      "view_count": 1250,
      "favorite_count": 89,
      "transaction_count": 12,
      "category": "Electronics",
      "owner": { ... },
      "image": "https://..."
    }
  ]
}
```

---

### Top Categories
Get best-performing categories.

```http
GET /api/analytics/top/categories
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "category_id": "cat-123",
      "category_name": "Electronics",
      "listing_count": 450,
      "average_price": 299.99,
      "transaction_count": 125
    }
  ]
}
```

---

### Daily Metrics
Get raw daily metrics.

```http
GET /api/analytics/daily-metrics?start_date=2024-01-01&end_date=2024-12-31
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "metric-123",
      "date": "2024-01-01T00:00:00.000Z",
      "new_users": 15,
      "active_users": 320,
      "new_listings": 45,
      "total_transactions": 28,
      "transaction_volume": 5600.00,
      "platform_revenue": 280.00,
      "messages_sent": 450,
      "searches_performed": 890,
      "created_at": "2024-01-02T00:05:00.000Z"
    }
  ]
}
```

---

### Export to CSV

**Revenue Export**
```http
GET /api/analytics/export/revenue?start_date=2024-01-01&end_date=2024-12-31
```
Returns CSV file: `revenue-2024-01-01-to-2024-12-31.csv`

**User Export**
```http
GET /api/analytics/export/users?start_date=2024-01-01&end_date=2024-12-31
```
Returns CSV file: `users-2024-01-01-to-2024-12-31.csv`

**Transaction Export**
```http
GET /api/analytics/export/transactions?start_date=2024-01-01&end_date=2024-12-31
```
Returns CSV file: `transactions-2024-01-01-to-2024-12-31.csv`

---

### Admin Maintenance Endpoints

**Calculate Metrics**
```http
POST /api/analytics/calculate-metrics?date=2024-01-01
```

**Update User Analytics**
```http
POST /api/analytics/update-user-analytics/:userId
```

**Cleanup Old Events**
```http
POST /api/analytics/cleanup
```

---

## 👤 User Endpoints

### My Stats
Get analytics for the authenticated user.

```http
GET /api/analytics/my-stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_listings": 12,
    "active_listings": 8,
    "total_sales": 5,
    "total_purchases": 3,
    "total_rentals": 15,
    "total_earned": 450.00,
    "total_spent": 120.00,
    "profile_views": 234,
    "listing_views": 1205,
    "average_rating": 4.7,
    "response_rate": 0.95,
    "last_active": "2024-01-15T10:30:00.000Z"
  }
}
```

---

### Track Event
Track a custom analytics event.

```http
POST /api/analytics/track
Content-Type: application/json
```

**Request Body:**
```json
{
  "event_type": "custom_event",
  "metadata": {
    "custom_field": "value"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Event tracked successfully"
}
```

---

## 🧪 Testing with cURL

### Test Platform Overview (Admin)
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  https://brrow-backend-nodejs-production.up.railway.app/api/analytics/overview
```

### Test Revenue Report (Admin)
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  "https://brrow-backend-nodejs-production.up.railway.app/api/analytics/revenue?start_date=2024-01-01&end_date=2024-12-31&interval=week"
```

### Test My Stats (User)
```bash
curl -H "Authorization: Bearer YOUR_USER_TOKEN" \
  https://brrow-backend-nodejs-production.up.railway.app/api/analytics/my-stats
```

### Test Event Tracking (User)
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"event_type":"test_event","metadata":{"test":true}}' \
  https://brrow-backend-nodejs-production.up.railway.app/api/analytics/track
```

### Download CSV Export (Admin)
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  "https://brrow-backend-nodejs-production.up.railway.app/api/analytics/export/revenue?start_date=2024-01-01&end_date=2024-12-31" \
  -o revenue_report.csv
```

---

## 📱 iOS Integration Example

### Swift Model
```swift
struct PlatformAnalytics: Codable {
    let totalUsers: Int
    let activeUsers30d: Int
    let activeUsers24h: Int
    let totalListings: Int
    let activeListings: Int
    let totalTransactions: Int
    let completedTransactions: Int
    let totalRevenue: Double
    let platformCommission: Double

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case activeUsers30d = "active_users_30d"
        case activeUsers24h = "active_users_24h"
        case totalListings = "total_listings"
        case activeListings = "active_listings"
        case totalTransactions = "total_transactions"
        case completedTransactions = "completed_transactions"
        case totalRevenue = "total_revenue"
        case platformCommission = "platform_commission"
    }
}

struct AnalyticsResponse: Codable {
    let success: Bool
    let data: PlatformAnalytics
}
```

### API Client
```swift
class AnalyticsAPI {
    func getPlatformOverview() async throws -> PlatformAnalytics {
        let url = URL(string: "\(APIClient.baseURL)/api/analytics/overview")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AnalyticsResponse.self, from: data)
        return response.data
    }

    func getMyStats() async throws -> UserStats {
        let url = URL(string: "\(APIClient.baseURL)/api/analytics/my-stats")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(UserStatsResponse.self, from: data)
        return response.data
    }
}
```

---

## ⚠️ Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "error": "Error message here"
}
```

**Common HTTP Status Codes:**
- `200`: Success
- `400`: Bad Request (invalid parameters)
- `401`: Unauthorized (missing/invalid token)
- `403`: Forbidden (not admin)
- `500`: Server Error

---

## 🔐 Security Notes

1. **Admin Access**: Currently uses temporary bypass. Implement proper admin role check in production.
2. **Rate Limiting**: Apply rate limits to prevent abuse.
3. **Data Privacy**: All user data is anonymized in aggregated reports.
4. **Event Tracking**: Minimal user data is stored in events.

---

## 📊 Data Freshness

- **Platform Overview**: Real-time
- **Daily Metrics**: Updated once daily at midnight UTC
- **User Analytics**:
  - Recently active users: Daily at 2 AM UTC
  - All users: Weekly on Sunday at 3 AM UTC
- **Revenue Reports**: Real-time from transactions table
- **Top Lists**: Real-time

---

Last Updated: 2025-10-02
