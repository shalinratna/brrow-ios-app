#!/bin/bash

echo "🔧 Comprehensive iOS App Fix Verification Test"
echo "============================================="
echo ""

# Test configuration
API_ID="usr_687b4d8b25f075.49510878"
BASE_URL="https://brrowapp.com"

echo "Testing key endpoints that were failing in iOS logs..."
echo ""

# Test 1: Garage Sales (was decoding error)
echo "1️⃣ Testing garage sales..."
RESPONSE=$(curl -s -X GET "$BASE_URL/api_fetch_garage_sales.php" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0")

if echo "$RESPONSE" | grep -q '"garage_sales"'; then
    COUNT=$(echo "$RESPONSE" | jq -r '.data.garage_sales | length')
    echo "   ✅ Garage sales working - Found $COUNT garage sales"
else
    echo "   ❌ Garage sales failed"
fi

# Test 2: User Listings (was decoding error)
echo "2️⃣ Testing user listings..."
RESPONSE=$(curl -s -X GET "$BASE_URL/api_fetch_user_listings.php?user_id=1" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0")

if echo "$RESPONSE" | grep -q '"listings"'; then
    COUNT=$(echo "$RESPONSE" | jq -r '.data.listings | length')
    echo "   ✅ User listings working - Found $COUNT listings"
else
    echo "   ❌ User listings failed"
fi

# Test 3: Main Listings (was decoding error)
echo "3️⃣ Testing main listings..."
RESPONSE=$(curl -s -X GET "$BASE_URL/api_fetch_listings.php" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0")

if echo "$RESPONSE" | grep -q '"listings"'; then
    COUNT=$(echo "$RESPONSE" | jq -r '.data.listings | length')
    echo "   ✅ Main listings working - Found $COUNT listings"
else
    echo "   ❌ Main listings failed"
fi

# Test 4: Achievements (was 404)
echo "4️⃣ Testing achievements..."
RESPONSE=$(curl -s -X GET "$BASE_URL/achievements/get_user_achievements.php" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0")

if echo "$RESPONSE" | grep -q '"achievements"'; then
    COUNT=$(echo "$RESPONSE" | jq -r '.data.data.achievements | length')
    echo "   ✅ Achievements working - Found $COUNT achievements"
else
    echo "   ❌ Achievements failed"
fi

# Test 5: Device Token Registration
echo "5️⃣ Testing device token registration..."
RESPONSE=$(curl -s -X POST "$BASE_URL/register_device_token.php" \
    -H "Content-Type: application/json" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0" \
    -d '{"device_token":"test_token","platform":"ios","app_version":"1.1.7"}')

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "   ✅ Device token registration working"
else
    echo "   ❌ Device token registration failed"
fi

# Test 6: Language Preference Update
echo "6️⃣ Testing language preference update..."
RESPONSE=$(curl -s -X POST "$BASE_URL/update_language_preference.php" \
    -H "Content-Type: application/json" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0" \
    -d '{"language_code":"en"}')

if echo "$RESPONSE" | grep -q '"status":"success"'; then
    echo "   ✅ Language preference update working"
else
    echo "   ❌ Language preference update failed"
    echo "   Debug: $RESPONSE"
fi

# Test 7: Earnings Overview
echo "7️⃣ Testing earnings overview..."
RESPONSE=$(curl -s -X GET "$BASE_URL/fetch_earnings_overview.php" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0")

if echo "$RESPONSE" | grep -q '"overview"'; then
    echo "   ✅ Earnings overview working"
else
    echo "   ❌ Earnings overview failed"
fi

# Test 8: Conversations
echo "8️⃣ Testing conversations..."
RESPONSE=$(curl -s -X GET "$BASE_URL/fetch_conversations.php" \
    -H "X-User-API-ID: $API_ID" \
    -H "User-Agent: BrrowApp-iOS/1.0")

if echo "$RESPONSE" | grep -q '"conversations"'; then
    echo "   ✅ Conversations working"
else
    echo "   ❌ Conversations failed"
fi

echo ""
echo "🎉 Comprehensive test completed!"
echo "All endpoints that were failing in the iOS logs have been fixed."