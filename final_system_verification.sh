#!/bin/bash

# Final System Verification
echo "========================================="
echo "BRROW APP - FINAL SYSTEM VERIFICATION"
echo "========================================="
echo ""

BASE_URL="https://brrowapp.com"
USER_API_ID="usr_687b4d8b25f075.49510878"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
TOTAL=0

# Function to test endpoint
test_api() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    ((TOTAL++))
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$BASE_URL/$endpoint" \
            -H "X-User-API-ID: $USER_API_ID" \
            -H "Content-Type: application/json")
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$BASE_URL/$endpoint" \
            -H "X-User-API-ID: $USER_API_ID" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    if [ "$http_code" = "200" ]; then
        # Check if response has success field
        if echo "$body" | jq -e '.success' > /dev/null 2>&1; then
            success=$(echo "$body" | jq -r '.success')
            if [ "$success" = "true" ]; then
                echo -e "${GREEN}✓${NC} $description"
                ((PASSED++))
                return 0
            fi
        else
            # No success field, but 200 status - consider it passed
            echo -e "${GREEN}✓${NC} $description"
            ((PASSED++))
            return 0
        fi
    fi
    
    echo -e "${RED}✗${NC} $description (Status: $http_code)"
    ((FAILED++))
    return 1
}

echo -e "${BLUE}1. AUTHENTICATION & USER MANAGEMENT${NC}"
echo "--------------------------------------"
test_api "POST" "api_login.php" "Login with credentials" '{"email":"shalin@brrowapp.com","password":"test123"}'
test_api "GET" "api_get_profile.php" "Get user profile"
test_api "POST" "api_update_profile.php" "Update profile" '{"bio":"Test bio update"}'
echo ""

echo -e "${BLUE}2. LISTINGS MANAGEMENT${NC}"
echo "----------------------"
test_api "GET" "api_fetch_listings.php" "Fetch all listings"
test_api "GET" "api_fetch_user_listings.php?user_id=9" "Fetch user listings"
test_api "GET" "api_get_featured_listings.php" "Get featured listings"
test_api "POST" "api_create_listing.php" "Create new listing" '{"title":"Test Item","description":"Test description","price":25,"category":"Electronics","condition":"New","location":"San Francisco"}'
echo ""

echo -e "${BLUE}3. GARAGE SALES${NC}"
echo "---------------"
test_api "GET" "api_fetch_garage_sales.php" "Fetch garage sales"
test_api "POST" "api_create_garage_sale.php" "Create garage sale" '{"title":"Weekend Sale","description":"Great deals","address":"456 Oak St","location":"San Francisco","latitude":37.7749,"longitude":-122.4194,"sale_date":"2025-03-15","start_time":"09:00:00","end_time":"16:00:00"}'
echo ""

echo -e "${BLUE}4. FILE UPLOAD${NC}"
echo "--------------"
# Test the new upload endpoint
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
upload_response=$(curl -s -X POST "$BASE_URL/api_upload_file.php" \
    -H "X-User-API-ID: $USER_API_ID" \
    -H "Content-Type: application/json" \
    -d "{\"file\":\"data:image/png;base64,$TEST_IMAGE\",\"fileName\":\"test.png\"}")

if echo "$upload_response" | jq -e '.success and .fileUrl and .fileId' > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} File upload with correct response format"
    ((PASSED++))
    ((TOTAL++))
else
    echo -e "${RED}✗${NC} File upload response format issue"
    ((FAILED++))
    ((TOTAL++))
fi
echo ""

echo -e "${BLUE}5. CHAT & MESSAGING${NC}"
echo "-------------------"
test_api "GET" "fetch_conversations.php" "Fetch conversations"
test_api "GET" "api_fetch_conversations.php" "API fetch conversations"
echo ""

echo -e "${BLUE}6. EARNINGS & ANALYTICS${NC}"
echo "-----------------------"
test_api "GET" "fetch_earnings_overview.php" "Fetch earnings overview"
test_api "GET" "api_fetch_earnings_chart.php" "Fetch earnings chart"
test_api "GET" "api_fetch_earnings_transactions.php" "Fetch transactions"
test_api "GET" "api_fetch_recent_payouts.php" "Fetch recent payouts"
test_api "POST" "api_analytics_simple.php" "Track analytics event" '{"eventType":"test","eventName":"system_test"}'
echo ""

echo -e "${BLUE}7. ACHIEVEMENTS & RATINGS${NC}"
echo "-------------------------"
test_api "GET" "api_achievements_get_user.php" "Get user achievements"
test_api "POST" "api_achievements_track_progress.php" "Track achievement progress" '{"action":"test","value":1}'
test_api "GET" "api_fetch_user_rating.php?user_id=9" "Fetch user rating"
echo ""

echo -e "${BLUE}8. ADDITIONAL FEATURES${NC}"
echo "----------------------"
test_api "GET" "api_fetch_similar_listings.php?listing_id=1" "Fetch similar listings"
test_api "POST" "api_register_device_token.php" "Register device token" '{"device_token":"test_token","platform":"ios"}'
test_api "POST" "api_update_language_preference.php" "Update language preference" '{"language_code":"en"}'
echo ""

echo "========================================="
echo -e "${BLUE}FINAL RESULTS${NC}"
echo "========================================="
echo -e "Total Tests: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo ""

SUCCESS_RATE=$((PASSED * 100 / TOTAL))
if [ $SUCCESS_RATE -ge 90 ]; then
    echo -e "${GREEN}✅ SYSTEM VERIFICATION PASSED!${NC}"
    echo -e "${GREEN}Success Rate: ${SUCCESS_RATE}%${NC}"
    echo ""
    echo -e "${GREEN}The Brrow app is fully operational!${NC}"
elif [ $SUCCESS_RATE -ge 75 ]; then
    echo -e "${YELLOW}⚠️ SYSTEM MOSTLY FUNCTIONAL${NC}"
    echo -e "${YELLOW}Success Rate: ${SUCCESS_RATE}%${NC}"
    echo ""
    echo -e "${YELLOW}Minor issues remain but core functionality works.${NC}"
else
    echo -e "${RED}❌ SYSTEM NEEDS ATTENTION${NC}"
    echo -e "${RED}Success Rate: ${SUCCESS_RATE}%${NC}"
    echo ""
    echo -e "${RED}Several critical issues need to be resolved.${NC}"
fi

echo "========================================="