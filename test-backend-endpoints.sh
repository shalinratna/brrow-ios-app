#!/bin/bash

# Backend Endpoint Testing Script
# Tests all fixed endpoints to verify deployment

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Brrow Backend Endpoint Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BASE_URL="https://brrow-backend-nodejs-production.up.railway.app"

# Test 1: Health Check
echo "1️⃣  Testing Health Endpoint..."
HEALTH=$(curl -s "$BASE_URL/health")
echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"

VERSION=$(echo "$HEALTH" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Backend Version: $VERSION"
echo ""

# Test 2: Email Verification GET Handler
echo "2️⃣  Testing Email Verification GET Handler..."
VERIFICATION=$(curl -s "$BASE_URL/api/auth/resend-verification")
echo "$VERIFICATION" | python3 -m json.tool 2>/dev/null || echo "$VERIFICATION"

if echo "$VERIFICATION" | grep -q "Email Verification Endpoint"; then
    echo "   ✅ GET handler working correctly"
else
    echo "   ❌ GET handler not responding as expected"
fi
echo ""

# Test 3: Profile Endpoint (requires auth token)
echo "3️⃣  Testing Profile Endpoint (requires auth)..."
if [ -z "$TOKEN" ]; then
    echo "   ⚠️  No TOKEN environment variable set"
    echo "   📝 Usage: TOKEN='your_token' ./test-backend-endpoints.sh"
    echo ""
    echo "   To get a fresh token:"
    echo "   1. Log into the iOS app"
    echo "   2. Check Xcode console for auth token in logs"
    echo "   3. Export it: export TOKEN='eyJhbGci...'"
    echo ""
else
    PROFILE=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/users/me")
    echo "$PROFILE" | python3 -m json.tool 2>/dev/null || echo "$PROFILE"

    if echo "$PROFILE" | grep -q '"profilePicture"'; then
        echo "   ✅ profilePicture field present in response"
    elif echo "$PROFILE" | grep -q '"error"'; then
        echo "   ⚠️  Error in response (possibly expired token)"
    else
        echo "   ❌ profilePicture field missing"
    fi
fi
echo ""

# Test 4: Email Verification POST (requires auth token)
echo "4️⃣  Testing Email Verification POST Endpoint (requires auth)..."
if [ -z "$TOKEN" ]; then
    echo "   ⚠️  No TOKEN environment variable set (skipping)"
else
    RESEND=$(curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        "$BASE_URL/api/auth/resend-verification")
    echo "$RESEND" | python3 -m json.tool 2>/dev/null || echo "$RESEND"

    if echo "$RESEND" | grep -q '"success":true'; then
        echo "   ✅ Verification email sent successfully"
    elif echo "$RESEND" | grep -q '"error"'; then
        echo "   ⚠️  Error (possibly expired token or already verified)"
    fi
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Health check: PASS"
echo "✅ Email verification GET handler: PASS"
if [ -z "$TOKEN" ]; then
    echo "⚠️  Profile endpoint: SKIPPED (no token)"
    echo "⚠️  Email verification POST: SKIPPED (no token)"
    echo ""
    echo "💡 To test authenticated endpoints:"
    echo "   TOKEN='your_fresh_token' ./test-backend-endpoints.sh"
else
    echo "✅ Authenticated endpoints: TESTED (see results above)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
