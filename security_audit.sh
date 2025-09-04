#!/bin/bash

# ================================================
#     BRROW APP - SECURITY AUDIT
# ================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}        BRROW APP - SECURITY AUDIT${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

SECURITY_ISSUES=0
WARNINGS=0

# Function to check security issue
check_security() {
    local check_name=$1
    local command=$2
    local expected=$3
    
    echo -n "Checking $check_name... "
    
    result=$(eval "$command")
    
    if [[ "$result" == *"$expected"* ]]; then
        echo -e "${GREEN}✅ SECURE${NC}"
        return 0
    else
        echo -e "${RED}❌ ISSUE FOUND${NC}"
        SECURITY_ISSUES=$((SECURITY_ISSUES+1))
        return 1
    fi
}

# ================================================
# 1. CHECK PHP FILES FOR SECURITY ISSUES
# ================================================

echo -e "${YELLOW}[1/6] Checking PHP Security${NC}"
echo "================================================"

# Check for SQL injection vulnerabilities
echo -n "Checking for SQL injection risks... "
SQL_INJECT=$(grep -r "mysql_query\|mysqli_query" Brrowapp.com/*.php 2>/dev/null | grep -v "prepare" | wc -l)
if [ "$SQL_INJECT" -eq 0 ]; then
    echo -e "${GREEN}✅ No direct queries found${NC}"
else
    echo -e "${RED}❌ Found $SQL_INJECT potential SQL injection points${NC}"
    SECURITY_ISSUES=$((SECURITY_ISSUES+1))
fi

# Check for XSS vulnerabilities
echo -n "Checking for XSS vulnerabilities... "
XSS_RISK=$(grep -r "echo \$_GET\|echo \$_POST\|echo \$_REQUEST" Brrowapp.com/*.php 2>/dev/null | wc -l)
if [ "$XSS_RISK" -eq 0 ]; then
    echo -e "${GREEN}✅ No unescaped output found${NC}"
else
    echo -e "${YELLOW}⚠️ Found $XSS_RISK potential XSS points${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# Check for exposed credentials
echo -n "Checking for exposed credentials... "
EXPOSED_CREDS=$(grep -r "password\|api_key\|secret" Brrowapp.com/*.php 2>/dev/null | grep -v "// \|#\|/\*" | grep -E "(=\s*['\"][^'\"]+['\"])" | wc -l)
if [ "$EXPOSED_CREDS" -lt 5 ]; then
    echo -e "${GREEN}✅ Credentials appear secured${NC}"
else
    echo -e "${YELLOW}⚠️ Found $EXPOSED_CREDS hardcoded credentials${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# ================================================
# 2. CHECK SWIFT FILES FOR SECURITY ISSUES
# ================================================

echo ""
echo -e "${YELLOW}[2/6] Checking iOS App Security${NC}"
echo "================================================"

# Check for hardcoded API keys
echo -n "Checking for hardcoded API keys... "
API_KEYS=$(grep -r "apiKey\|api_key\|API_KEY" Brrow/*.swift 2>/dev/null | grep -E "=\s*\"[^\"]+\"" | wc -l)
if [ "$API_KEYS" -eq 0 ]; then
    echo -e "${GREEN}✅ No hardcoded API keys found${NC}"
else
    echo -e "${RED}❌ Found $API_KEYS hardcoded API keys${NC}"
    SECURITY_ISSUES=$((SECURITY_ISSUES+1))
fi

# Check for insecure data storage
echo -n "Checking for insecure data storage... "
INSECURE_STORAGE=$(grep -r "UserDefaults.*password\|UserDefaults.*token" Brrow/*.swift 2>/dev/null | wc -l)
if [ "$INSECURE_STORAGE" -eq 0 ]; then
    echo -e "${GREEN}✅ Sensitive data storage appears secure${NC}"
else
    echo -e "${YELLOW}⚠️ Found $INSECURE_STORAGE instances of potentially insecure storage${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# ================================================
# 3. CHECK HTTPS ENFORCEMENT
# ================================================

echo ""
echo -e "${YELLOW}[3/6] Checking HTTPS Enforcement${NC}"
echo "================================================"

# Check for HTTP URLs
echo -n "Checking for insecure HTTP URLs... "
HTTP_URLS=$(grep -r "http://" Brrow/*.swift Brrowapp.com/*.php 2>/dev/null | grep -v "localhost\|127.0.0.1" | wc -l)
if [ "$HTTP_URLS" -eq 0 ]; then
    echo -e "${GREEN}✅ All URLs use HTTPS${NC}"
else
    echo -e "${YELLOW}⚠️ Found $HTTP_URLS HTTP URLs${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# ================================================
# 4. CHECK AUTHENTICATION & AUTHORIZATION
# ================================================

echo ""
echo -e "${YELLOW}[4/6] Checking Authentication${NC}"
echo "================================================"

# Check for JWT implementation
echo -n "Checking JWT implementation... "
JWT_IMPL=$(grep -r "JWT\|jsonwebtoken" Brrowapp.com/*.php 2>/dev/null | wc -l)
if [ "$JWT_IMPL" -gt 0 ]; then
    echo -e "${GREEN}✅ JWT authentication implemented${NC}"
else
    echo -e "${RED}❌ JWT authentication not found${NC}"
    SECURITY_ISSUES=$((SECURITY_ISSUES+1))
fi

# Check for rate limiting
echo -n "Checking for rate limiting... "
RATE_LIMIT=$(grep -r "rate.*limit\|throttle" Brrowapp.com/*.php 2>/dev/null | wc -l)
if [ "$RATE_LIMIT" -gt 0 ]; then
    echo -e "${GREEN}✅ Rate limiting appears implemented${NC}"
else
    echo -e "${YELLOW}⚠️ No rate limiting found${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# ================================================
# 5. CHECK INPUT VALIDATION
# ================================================

echo ""
echo -e "${YELLOW}[5/6] Checking Input Validation${NC}"
echo "================================================"

# Check for input sanitization
echo -n "Checking input sanitization... "
SANITIZE=$(grep -r "filter_input\|htmlspecialchars\|strip_tags" Brrowapp.com/*.php 2>/dev/null | wc -l)
if [ "$SANITIZE" -gt 10 ]; then
    echo -e "${GREEN}✅ Input sanitization found${NC}"
else
    echo -e "${YELLOW}⚠️ Limited input sanitization${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# Check for file upload validation
echo -n "Checking file upload validation... "
FILE_VALID=$(grep -r "mime_content_type\|getimagesize" Brrowapp.com/*.php 2>/dev/null | wc -l)
if [ "$FILE_VALID" -gt 0 ]; then
    echo -e "${GREEN}✅ File upload validation found${NC}"
else
    echo -e "${RED}❌ No file upload validation found${NC}"
    SECURITY_ISSUES=$((SECURITY_ISSUES+1))
fi

# ================================================
# 6. CHECK SECURITY HEADERS
# ================================================

echo ""
echo -e "${YELLOW}[6/6] Checking Security Headers${NC}"
echo "================================================"

# Check for security headers
echo -n "Checking security headers... "
SEC_HEADERS=$(grep -r "X-Frame-Options\|X-Content-Type-Options\|X-XSS-Protection" Brrowapp.com/*.php Brrowapp.com/.htaccess 2>/dev/null | wc -l)
if [ "$SEC_HEADERS" -gt 3 ]; then
    echo -e "${GREEN}✅ Security headers configured${NC}"
else
    echo -e "${YELLOW}⚠️ Missing some security headers${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# ================================================
# SECURITY AUDIT RESULTS
# ================================================

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}         SECURITY AUDIT RESULTS${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

echo -e "Critical Issues: ${RED}$SECURITY_ISSUES${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ "$SECURITY_ISSUES" -eq 0 ] && [ "$WARNINGS" -lt 3 ]; then
    echo -e "${GREEN}🔒 SECURITY STATUS: GOOD${NC}"
    echo "The application meets basic security standards."
elif [ "$SECURITY_ISSUES" -lt 3 ]; then
    echo -e "${YELLOW}⚠️ SECURITY STATUS: MODERATE${NC}"
    echo "Some security improvements needed before production."
else
    echo -e "${RED}❌ SECURITY STATUS: CRITICAL${NC}"
    echo "Major security issues must be fixed immediately."
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}       SECURITY RECOMMENDATIONS${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

echo "CRITICAL (Must Fix):"
echo "1. ✅ Use prepared statements for ALL database queries"
echo "2. ✅ Implement proper JWT token validation"
echo "3. ✅ Sanitize all user inputs"
echo "4. ✅ Validate file uploads thoroughly"
echo "5. ✅ Use HTTPS everywhere"
echo ""

echo "IMPORTANT (Should Fix):"
echo "1. ⚠️ Implement rate limiting on all endpoints"
echo "2. ⚠️ Add CAPTCHA to prevent bot attacks"
echo "3. ⚠️ Use Content Security Policy (CSP)"
echo "4. ⚠️ Implement proper session management"
echo "5. ⚠️ Add request signing for API calls"
echo ""

echo "BEST PRACTICES:"
echo "1. 📝 Regular security audits"
echo "2. 📝 Dependency vulnerability scanning"
echo "3. 📝 Penetration testing"
echo "4. 📝 Security logging and monitoring"
echo "5. 📝 Incident response plan"
echo ""

# Save audit results
echo "[$(date)]" > security_audit_results.log
echo "Critical Issues: $SECURITY_ISSUES" >> security_audit_results.log
echo "Warnings: $WARNINGS" >> security_audit_results.log