#\!/bin/bash

# Test all critical endpoints that were failing in iOS decoding
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo5LCJhcGlfaWQiOiJ0ZXN0X3NoYWxpbl8xNzUzNTYzNzkyXzEiLCJlbWFpbCI6InNoYWxpbkBicnJvd2FwcC5jb20iLCJleHAiOjE3NTUyMzQ1NzUsImlhdCI6MTc1NDYyOTc3NX0.fl84fptfU055XJpKoTKS0KbiK1rm1OYlygBaE9xV1qc"

echo "=== Final iOS Decoding Test ==="
echo

# 1. Test Garage Sales (critical - was returning empty arrays)
echo "1. Testing garage sales endpoint..."
RESPONSE=$(curl -s "https://brrowapp.com/api/fetch_garage_sales.php" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN")

echo "Structure check:"
echo "$RESPONSE" | jq -r 'keys[]' 2>/dev/null | head -5
echo "Success: $(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)"
echo "Garage sales count: $(echo "$RESPONSE" | jq -r '.garage_sales | length' 2>/dev/null)"
echo

# 2. Test User Listings 
echo "2. Testing user listings endpoint..."
RESPONSE=$(curl -s "https://brrowapp.com/api/fetch_user_listings.php" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN")

echo "Structure check:"
echo "$RESPONSE" | jq -r 'keys[]' 2>/dev/null | head -5
echo "Success: $(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)"
echo "Data exists: $(echo "$RESPONSE" | jq -r '.data \!= null' 2>/dev/null)"
echo

# 3. Test Main Listings
echo "3. Testing main listings endpoint..."
RESPONSE=$(curl -s "https://brrowapp.com/api/fetch_listings.php" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN")

echo "Structure check:"
echo "$RESPONSE" | jq -r 'keys[]' 2>/dev/null | head -5
echo "Success: $(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)"
echo "Data exists: $(echo "$RESPONSE" | jq -r '.data \!= null' 2>/dev/null)"
echo

# 4. Test Earnings Overview
echo "4. Testing earnings overview endpoint..."
RESPONSE=$(curl -s "https://brrowapp.com/api/fetch_earnings_overview.php" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN")

echo "Structure check:"
echo "$RESPONSE" | jq -r 'keys[]' 2>/dev/null | head -5
echo "Success: $(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)"
echo "Data exists: $(echo "$RESPONSE" | jq -r '.data \!= null' 2>/dev/null)"
echo "Overview exists: $(echo "$RESPONSE" | jq -r '.data.overview \!= null' 2>/dev/null)"
echo

# 5. Test Earnings Transactions (direct array)
echo "5. Testing earnings transactions endpoint..."
RESPONSE=$(curl -s "https://brrowapp.com/api/fetch_earnings_transactions.php" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN")

echo "Response type: $(echo "$RESPONSE" | jq -r 'type' 2>/dev/null)"
echo "Is array: $(echo "$RESPONSE" | jq -r '. | type == "array"' 2>/dev/null)"
echo

# 6. Test Earnings Chart (direct array)
echo "6. Testing earnings chart endpoint..."
RESPONSE=$(curl -s "https://brrowapp.com/api/fetch_earnings_chart.php" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN")

echo "Response type: $(echo "$RESPONSE" | jq -r 'type' 2>/dev/null)"
echo "Is array: $(echo "$RESPONSE" | jq -r '. | type == "array"' 2>/dev/null)"
echo "Array length: $(echo "$RESPONSE" | jq -r 'length' 2>/dev/null)"
echo

# 7. Test Achievements
echo "7. Testing achievements endpoint..."
RESPONSE=$(curl -s "https://brrowapp.com/api/achievements_get_user.php" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN")

echo "Structure check:"
echo "$RESPONSE" | jq -r 'keys[]' 2>/dev/null | head -5
echo "Success: $(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)"
echo "Data exists: $(echo "$RESPONSE" | jq -r '.data \!= null' 2>/dev/null)"
echo "Level exists: $(echo "$RESPONSE" | jq -r '.data.level \!= null' 2>/dev/null)"
echo

# 8. Test Language Preference
echo "8. Testing language preference endpoint..."
RESPONSE=$(curl -s -X POST "https://brrowapp.com/api/update_language_preference.php" \
    -H "Content-Type: application/json" \
    -H "X-User-API-ID: test_shalin_1753563792_1" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"language": "en"}')

echo "Structure check:"
echo "$RESPONSE" | jq -r 'keys[]' 2>/dev/null | head -5
echo "Success: $(echo "$RESPONSE" | jq -r '.success' 2>/dev/null)"
echo "Message exists: $(echo "$RESPONSE" | jq -r '.message \!= null' 2>/dev/null)"
echo

echo "=== Test Complete ==="
echo "All endpoints have been tested with the exact structures iOS expects."
echo "Check above output for any 'null' or 'false' values that indicate problems."
EOF < /dev/null