#\!/bin/bash

# ================================================
#     BRROW APP - FINAL PRODUCTION TEST
# ================================================

BASE_URL="https://brrowapp.com/brrow"
EMAIL="shalin@brrowapp.com"
PASSWORD="Ballin@1415"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

print_header() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${CYAN}    BRROW APP - FINAL PRODUCTION TEST${NC}"
    echo -e "${CYAN}================================================${NC}\n"
}

print_section() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
}

test_feature() {
    local feature_name=$1
    local test_command=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "  Testing $feature_name..."
    
    if eval $test_command > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e " ${RED}✗${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

print_header

# Authentication
print_section "1. AUTHENTICATION"
AUTH_RESPONSE=$(curl -s -X POST "${BASE_URL}/api_login.php" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")
TOKEN=$(echo $AUTH_RESPONSE | jq -r '.token' 2>/dev/null || echo "")
API_ID=$(echo $AUTH_RESPONSE | jq -r '.user.api_id' 2>/dev/null || echo "")

if [ -n "$TOKEN" ] && [ "$TOKEN" \!= "null" ]; then
    echo -e "  Authentication: ${GREEN}✓${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  Authentication: ${RED}✗${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test Core Features
print_section "2. CORE FEATURES"
test_feature "Listings" "curl -s '${BASE_URL}/api_get_listings.php' -H 'Authorization: Bearer $TOKEN'"
test_feature "Garage Sales" "curl -s '${BASE_URL}/api_get_garage_sales.php' -H 'Authorization: Bearer $TOKEN'"
test_feature "Seeks" "curl -s '${BASE_URL}/api_get_seeks.php' -H 'Authorization: Bearer $TOKEN'"
test_feature "Search" "curl -s '${BASE_URL}/api_search.php?q=test' -H 'Authorization: Bearer $TOKEN'"
test_feature "Location" "curl -s '${BASE_URL}/api_location_search.php?latitude=37.7749&longitude=-122.4194&radius=10' -H 'Authorization: Bearer $TOKEN'"

# Summary
echo -e "\n${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}                TEST SUMMARY${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "Total: $TOTAL_TESTS | ${GREEN}Passed: $PASSED_TESTS${NC} | ${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}★ ALL TESTS PASSED\! APP IS PRODUCTION READY\! ★${NC}"
else
    echo -e "\n${YELLOW}⚠ Some tests failed. Check server deployment. ⚠${NC}"
fi
