#!/bin/bash

# Quick Pre-Release Test Script
# Run this before opening Xcode to verify backend is ready

echo "🧪 Brrow Pre-Release Quick Test"
echo "================================"
echo ""

# 1. Backend Health Check
echo "1️⃣  Checking backend health..."
HEALTH=$(curl -s "https://brrow-backend-nodejs-production.up.railway.app/health" | python3 -m json.tool 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Backend is healthy"
    echo "$HEALTH" | grep -E "status|version|database"
else
    echo "❌ Backend health check failed"
    exit 1
fi

echo ""

# 2. Email Verification Endpoint
echo "2️⃣  Checking email verification endpoint..."
EMAIL_VERIFY=$(curl -s -o /dev/null -w "%{http_code}" "https://brrow-backend-nodejs-production.up.railway.app/api/auth/resend-verification")

if [ "$EMAIL_VERIFY" = "200" ]; then
    echo "✅ Email verification endpoint ready (HTTP 200)"
else
    echo "❌ Email verification endpoint returned HTTP $EMAIL_VERIFY"
fi

echo ""

# 3. Kill stale build processes
echo "3️⃣  Cleaning up old build processes..."
XCODE_PROCS=$(ps aux | grep -i xcodebuild | grep -v grep | wc -l | tr -d ' ')

if [ "$XCODE_PROCS" -gt 0 ]; then
    echo "⚠️  Found $XCODE_PROCS running xcodebuild processes"
    echo "   Killing them..."
    killall xcodebuild 2>/dev/null
    echo "✅ Cleaned up"
else
    echo "✅ No stale processes found"
fi

echo ""

# 4. Check git status
echo "4️⃣  Checking git status..."
if git diff --quiet; then
    echo "✅ No uncommitted changes"
else
    echo "⚠️  You have uncommitted changes:"
    git status --short
fi

echo ""

# 5. Recent commits
echo "5️⃣  Recent fixes (last 5 commits)..."
git log --oneline -5

echo ""
echo "================================"
echo "🚀 Ready to test!"
echo ""
echo "Next steps:"
echo "1. Open Brrow.xcworkspace (not .xcodeproj!)"
echo "2. Clean build folder: ⌘+Shift+K"
echo "3. Build and run: ⌘+R"
echo "4. Monitor console for debug logs"
echo ""
echo "📋 See PRE_RELEASE_TESTING_CHECKLIST.md for full test plan"
