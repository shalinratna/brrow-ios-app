#!/bin/bash

# Final comprehensive test of all systems
echo "========================================="
echo "FINAL COMPREHENSIVE SYSTEM TEST"
echo "========================================="

BASE_URL="https://brrowapp.com"
AUTH_HEADER="X-User-API-ID: usr_687b4d8b25f075.49510878"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_status=$3
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/$endpoint" \
            -H "$AUTH_HEADER" \
            -H "Content-Type: application/json")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/$endpoint" \
            -H "$AUTH_HEADER" \
            -H "Content-Type: application/json" \
            -d '{}')
    fi
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✓${NC} $endpoint"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $endpoint (Got $response, Expected $expected_status)"
        ((FAILED++))
        return 1
    fi
}

# Function to test page
test_page() {
    local page=$1
    local expected_status=$2
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/$page")
    
    if [ "$response" = "$expected_status" ] || ([ "$expected_status" = "200|302" ] && ([ "$response" = "200" ] || [ "$response" = "302" ])); then
        echo -e "${GREEN}✓${NC} $page"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $page (Got $response, Expected $expected_status)"
        ((FAILED++))
        return 1
    fi
}

echo -e "\n${BLUE}=== CRITICAL API ENDPOINTS ===${NC}"
test_endpoint "POST" "api_login.php" "400"  # Expects credentials
test_endpoint "GET" "api_get_profile.php" "200"
test_endpoint "GET" "api_fetch_listings.php" "200"
test_endpoint "GET" "api_fetch_garage_sales.php" "200"
test_endpoint "GET" "fetch_conversations.php" "200"
test_endpoint "GET" "fetch_earnings_overview.php" "200"
test_endpoint "GET" "api_fetch_earnings_chart.php" "200"
test_endpoint "GET" "api_achievements_get_user.php" "200"
test_endpoint "POST" "api_analytics_simple.php" "200"
test_endpoint "GET" "api_fetch_user_listings.php?user_id=9" "200"
test_endpoint "GET" "api_fetch_user_rating.php?user_id=9" "200"
test_endpoint "GET" "api_get_featured_listings.php" "200"
test_endpoint "GET" "api_check_favorite.php?listing_id=1" "200"

echo -e "\n${BLUE}=== WEBSITE PAGES ===${NC}"
test_page "" "200"
test_page "index.php" "200"
test_page "login.php" "200"
test_page "register.php" "200"
test_page "listings.php" "200"
test_page "search_new.php" "200"
test_page "events.php" "200"
test_page "dashboard.php" "200|302"  # May redirect if not logged in
test_page "garage_sales.php" "200"
test_page "create_listing.php" "200|302"
test_page "create_garage_sale.php" "200|302"

echo -e "\n${BLUE}=== iOS APP CRITICAL FLOWS ===${NC}"

# Test login flow
echo -e "\n${YELLOW}Testing Login Flow${NC}"
login_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api_login.php" \
    -H "Content-Type: application/json" \
    -d '{"email":"shalin@brrowapp.com","password":"test123"}')
http_code=$(echo "$login_response" | grep "HTTP_CODE:" | cut -d':' -f2)
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓${NC} Login endpoint works"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Login endpoint failed (Status: $http_code)"
    ((FAILED++))
fi

# Test listing creation
echo -e "\n${YELLOW}Testing Listing Creation${NC}"
listing_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api_create_listing.php" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Item","description":"Test","price":10,"category":"Electronics","condition":"New","location":"SF"}')
http_code=$(echo "$listing_response" | grep "HTTP_CODE:" | cut -d':' -f2)
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓${NC} Listing creation works"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Listing creation failed (Status: $http_code)"
    ((FAILED++))
fi

# Test garage sale creation
echo -e "\n${YELLOW}Testing Garage Sale Creation${NC}"
gs_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api_create_garage_sale.php" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Sale","description":"Test","address":"123 Test St","location":"SF","latitude":37.7749,"longitude":-122.4194,"sale_date":"2025-03-01","start_time":"09:00:00","end_time":"16:00:00"}')
http_code=$(echo "$gs_response" | grep "HTTP_CODE:" | cut -d':' -f2)
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓${NC} Garage sale creation works"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Garage sale creation failed (Status: $http_code)"
    ((FAILED++))
fi

echo -e "\n${BLUE}=========================================${NC}"
echo -e "${BLUE}TEST RESULTS SUMMARY${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! System is fully operational.${NC}"
else
    echo -e "\n${YELLOW}⚠️ Some tests failed. Review the output above for details.${NC}"
fi

echo -e "${BLUE}=========================================${NC}"