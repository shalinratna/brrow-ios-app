#!/bin/bash

echo "🔍 Getting available listings..."

# Get available listings first
echo "Fetching all listings..."
curl -s -X GET "https://brrowapp.com/brrow/api/fetch_listings.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9" \
  -H "X-User-API-ID: test_shalin_1753563792_1" \
  -H "User-Agent: BrrowApp-iOS/1.0" | jq '.data[0:3]'

echo ""
echo "✅ Test complete"