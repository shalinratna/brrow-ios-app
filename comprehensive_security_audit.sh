#!/bin/bash

echo "========================================="
echo "COMPREHENSIVE SECURITY & PROFESSIONALISM AUDIT"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "1. CHECKING FOR EXPOSED SENSITIVE FILES"
echo "----------------------------------------"
SENSITIVE_FILES=(
    ".env"
    "config.php"
    ".git/config"
    "composer.json"
    "package.json"
    ".htpasswd"
    "phpinfo.php"
    "info.php"
    "test.php"
    "debug.php"
    ".DS_Store"
    "Thumbs.db"
    "error_log"
    "access_log"
    ".gitignore"
    "composer.lock"
    "package-lock.json"
    "wp-config.php"
    "database.sql"
    "backup.sql"
    ".ssh"
    "id_rsa"
    "id_rsa.pub"
)

for FILE in "${SENSITIVE_FILES[@]}"; do
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" "https://brrowapp.com/$FILE")
    if [ "$STATUS" == "200" ]; then
        echo -e "${RED}❌ CRITICAL: $FILE is publicly accessible!${NC}"
    elif [ "$STATUS" == "403" ]; then
        echo -e "${GREEN}✅ $FILE is protected (403 Forbidden)${NC}"
    fi
done

echo ""
echo "2. CHECKING DIRECTORY LISTING"
echo "------------------------------"
DIRS=("uploads" "api" "includes" "config" "admin" "private" "backup" "logs" "tmp" "cache")
for DIR in "${DIRS[@]}"; do
    RESPONSE=$(curl -s "https://brrowapp.com/brrow/$DIR/" | head -20)
    if echo "$RESPONSE" | grep -q "Index of"; then
        echo -e "${RED}❌ Directory listing enabled for /$DIR/${NC}"
    else
        echo -e "${GREEN}✅ /$DIR/ protected${NC}"
    fi
done

echo ""
echo "3. CHECKING SQL INJECTION POINTS"
echo "---------------------------------"
# Test common injection points
URLS=(
    "https://brrowapp.com/brrow/api/fetch_listings.php?id=1'"
    "https://brrowapp.com/brrow/api/get_profile.php?user_id=1'"
    "https://brrowapp.com/brrow/api/search.php?q=test'"
)

for URL in "${URLS[@]}"; do
    RESPONSE=$(curl -s "$URL" 2>/dev/null | head -100)
    if echo "$RESPONSE" | grep -qi "sql\|syntax\|mysql\|postgresql\|error in your SQL"; then
        echo -e "${RED}❌ Possible SQL injection vulnerability: ${URL}${NC}"
    else
        echo -e "${GREEN}✅ No obvious SQL errors in response${NC}"
    fi
done

echo ""
echo "4. CHECKING API AUTHENTICATION"
echo "-------------------------------"
# Test if APIs require authentication
PROTECTED_APIS=(
    "update_profile.php"
    "create_listing.php"
    "delete_listing.php"
    "admin_moderation.php"
)

for API in "${PROTECTED_APIS[@]}"; do
    RESPONSE=$(curl -s -X POST "https://brrowapp.com/brrow/api/$API" \
        -H "Content-Type: application/json" \
        -d '{"test":"data"}' 2>/dev/null)
    
    if echo "$RESPONSE" | grep -qi "unauthorized\|auth.*required\|401\|403"; then
        echo -e "${GREEN}✅ $API requires authentication${NC}"
    else
        echo -e "${YELLOW}⚠️  Check if $API properly validates auth${NC}"
    fi
done

echo ""
echo "5. CHECKING FILE UPLOAD SECURITY"
echo "---------------------------------"
# Check if upload endpoints validate file types
UPLOAD_TEST=$(curl -s -X POST "https://brrowapp.com/brrow/api/upload_file.php" \
    -F "file=@/etc/passwd" 2>/dev/null | head -50)

if echo "$UPLOAD_TEST" | grep -qi "not allowed\|invalid.*type\|forbidden"; then
    echo -e "${GREEN}✅ File upload validates file types${NC}"
else
    echo -e "${YELLOW}⚠️  Verify file upload restrictions${NC}"
fi

echo ""
echo "6. CHECKING HTTPS/SSL CONFIGURATION"
echo "------------------------------------"
# Check if HTTP redirects to HTTPS
HTTP_CHECK=$(curl -I -s "http://brrowapp.com" | grep -i "location:")
if echo "$HTTP_CHECK" | grep -q "https://"; then
    echo -e "${GREEN}✅ HTTP redirects to HTTPS${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP may not redirect to HTTPS${NC}"
fi

# Check SSL certificate
SSL_CHECK=$(curl -I -s "https://brrowapp.com" 2>&1)
if echo "$SSL_CHECK" | grep -qi "certificate\|ssl"; then
    echo -e "${YELLOW}⚠️  Check SSL certificate validity${NC}"
else
    echo -e "${GREEN}✅ SSL appears to be working${NC}"
fi

echo ""
echo "7. CHECKING ERROR HANDLING"
echo "---------------------------"
# Test error pages
ERROR_TEST=$(curl -s "https://brrowapp.com/brrow/api/nonexistent.php")
if echo "$ERROR_TEST" | grep -qi "fatal error\|warning\|notice\|stack trace\|line [0-9]"; then
    echo -e "${RED}❌ PHP errors are exposed!${NC}"
else
    echo -e "${GREEN}✅ PHP errors appear hidden${NC}"
fi

echo ""
echo "8. CHECKING HEADERS SECURITY"
echo "-----------------------------"
HEADERS=$(curl -I -s "https://brrowapp.com")

# Check security headers
if echo "$HEADERS" | grep -qi "x-frame-options"; then
    echo -e "${GREEN}✅ X-Frame-Options header present${NC}"
else
    echo -e "${YELLOW}⚠️  Missing X-Frame-Options header${NC}"
fi

if echo "$HEADERS" | grep -qi "x-content-type-options"; then
    echo -e "${GREEN}✅ X-Content-Type-Options header present${NC}"
else
    echo -e "${YELLOW}⚠️  Missing X-Content-Type-Options header${NC}"
fi

if echo "$HEADERS" | grep -qi "strict-transport-security"; then
    echo -e "${GREEN}✅ HSTS header present${NC}"
else
    echo -e "${YELLOW}⚠️  Missing Strict-Transport-Security header${NC}"
fi

echo ""
echo "9. CHECKING DATABASE CREDENTIALS"
echo "---------------------------------"
# Check if config files with DB credentials are accessible
CONFIG_FILES=(
    "brrow/api/config.php"
    "brrow/config/config.php"
    "includes/config.php"
    "config/database.php"
)

for FILE in "${CONFIG_FILES[@]}"; do
    RESPONSE=$(curl -s "https://brrowapp.com/$FILE" 2>/dev/null | head -20)
    if echo "$RESPONSE" | grep -qi "DB_PASS\|password.*=\|mysql_connect\|postgresql"; then
        echo -e "${RED}❌ CRITICAL: Database credentials may be exposed in $FILE${NC}"
    fi
done

echo ""
echo "10. CHECKING FOR DEBUG/TEST FILES"
echo "----------------------------------"
TEST_FILES=(
    "test.php"
    "debug.php"
    "phpinfo.php"
    "info.php"
    "test.html"
    "debug.html"
    "admin/test.php"
    "api/test.php"
)

for FILE in "${TEST_FILES[@]}"; do
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" "https://brrowapp.com/brrow/$FILE")
    if [ "$STATUS" == "200" ]; then
        echo -e "${YELLOW}⚠️  Test/debug file accessible: $FILE${NC}"
    fi
done

echo ""
echo "========================================="
echo "SUMMARY OF CRITICAL ISSUES TO FIX:"
echo "========================================="
echo ""
echo "🔴 CRITICAL (Fix immediately):"
echo "  - Remove or protect all test/debug files"
echo "  - Ensure PHP source code never displays"
echo "  - Hide all error messages in production"
echo "  - Protect sensitive configuration files"
echo ""
echo "🟡 IMPORTANT (Fix soon):"
echo "  - Add missing security headers"
echo "  - Implement rate limiting on all APIs"
echo "  - Add CAPTCHA to prevent bot attacks"
echo "  - Implement proper session management"
echo ""
echo "🟢 RECOMMENDATIONS:"
echo "  - Use prepared statements for all SQL"
echo "  - Implement CSP (Content Security Policy)"
echo "  - Add request signing for API calls"
echo "  - Regular security audits"
echo "  - Keep all dependencies updated"
echo "========================================="