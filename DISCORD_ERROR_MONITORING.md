# Discord Error Monitoring - PEST System

**Status**: ✅ ACTIVE
**Last Updated**: October 15, 2025
**Webhook**: Discord #backend-errors channel

---

## 🎯 What Gets Reported

All backend errors are automatically sent to Discord with rich details. You no longer need to check Railway logs manually.

### Error Severity Levels

#### 🔴 **CRITICAL** (Red)
- **Prisma Validation Errors** (`PrismaClientValidationError`)
  - Missing required fields (like `updated_at`)
  - Invalid data types
  - Schema constraint violations
- **Database Connection Failures**
- **Authentication System Failures**

**Example Discord Message:**
```
🔴 Backend Error: PrismaClientValidationError
🔴 PRISMA VALIDATION ERROR - POST /api/messages/listing
Severity: CRITICAL
Argument `updated_at` is missing
```

#### 🟠 **HIGH** (Orange)
- **500 Internal Server Errors**
- **Unhandled Exceptions**
- **Third-party API Failures** (Stripe, Cloudinary, Firebase)
- **WebSocket Errors**

#### 🟡 **MEDIUM** (Yellow)
- **400-499 Client Errors** (validation, not found, unauthorized)
- **Rate Limit Violations**
- **Image Upload Failures**

#### 🟢 **LOW** (Green)
- **Warnings and Notices**
- **Performance Degradation**

---

## 📊 Information Included in Each Report

Every error report contains:

1. **Error Details**
   - Error name and message
   - Stack trace (for critical/high severity)
   - Error code

2. **Request Context**
   - HTTP method (GET, POST, PUT, DELETE)
   - Endpoint path
   - User ID (if authenticated)
   - IP address
   - User agent

3. **Server Info**
   - Server hostname
   - Node.js version
   - Environment (production)
   - Timestamp

4. **Additional Context** (for Prisma errors)
   - Request body (sanitized, first 500 chars)
   - Error type
   - Status code

---

## 🔥 Recent Fixes Deployed

### ✅ Fix #1: Chat Creation `updated_at` Field (Oct 15, 2025)
**Commit**: `138aa87`
**Issue**: Missing `updated_at` field when creating listing chats
**Fix**: Added `updated_at: new Date()` to chat creation in `services/messageService.js:438`
**Status**: ✅ DEPLOYED

### ✅ Fix #2: Enhanced PEST Monitoring (Oct 15, 2025)
**Commit**: `2c77231`
**Changes**:
- Prisma errors now marked as CRITICAL
- Special highlighting: "🔴 PRISMA VALIDATION ERROR"
- Request body included for debugging
- Better error severity classification

### ✅ Fix #3: View Count Throttling (Oct 15, 2025)
**Commit**: `034650a`
**Feature**: Prevent view count inflation with 10-minute throttle window

---

## 🚨 Error Examples You'll See in Discord

### Example 1: Prisma Validation Error
```
🔴 Backend Error: PrismaClientValidationError
📍 Context: 🔴 PRISMA VALIDATION ERROR - POST /api/messages/listing
⚡ Severity: CRITICAL
🖥️ Server: brrow-production
🕐 Time: 2025-10-15T06:30:58.000Z

👤 Additional Info:
method: POST
path: /api/messages/listing
userId: cmfrmr7l30000nz01qfyr0lc4
errorType: PrismaClientValidationError
statusCode: 500
requestBody: {"listingId":"b7f2f798-01d9-4f27-b9c0-4664341188a0"}

📚 Stack Trace:
Invalid `prisma.chats.create()` invocation:
Argument `updated_at` is missing.
    at MessageService.getOrCreateListingChat (/app/services/messageService.js:431:14)
```

### Example 2: General 500 Error
```
🟠 Backend Error: Error
📍 Context: GET /api/listings
⚡ Severity: HIGH
🖥️ Server: brrow-production
🕐 Time: 2025-10-15T06:35:00.000Z

👤 Additional Info:
method: GET
path: /api/listings
userId: anonymous
errorType: Error
statusCode: 500
```

### Example 3: Client Validation Error
```
🟡 Backend Error: ValidationError
📍 Context: POST /api/listings
⚡ Severity: MEDIUM
🖥️ Server: brrow-production
🕐 Time: 2025-10-15T06:40:00.000Z
```

---

## ⚙️ Rate Limiting

To prevent spam, PEST limits Discord notifications to:
- **Maximum 10 errors per minute**
- Errors beyond this limit are logged locally but not sent to Discord
- History resets every minute

---

## 🔍 How to Use Discord Monitoring

### Daily Monitoring
1. Check Discord #backend-errors channel once per day
2. Look for 🔴 CRITICAL or 🟠 HIGH severity errors
3. 🟡 MEDIUM errors can be reviewed weekly
4. 🟢 LOW can be ignored unless frequent

### When You See a CRITICAL Error
1. Error is already logged with full details
2. Check the error message and stack trace
3. User ID tells you who was affected
4. Request body shows what data caused the issue
5. Fix the code and push to master
6. Railway auto-deploys in ~2 minutes

### Testing Error Reporting
Run this command to send a test error:
```bash
cd brrow-backend && node -e "
const { PEST } = require('./pest-control');
PEST.captureError(
  new Error('Test error'),
  'Manual test',
  'medium',
  { tester: 'Shalin' }
);
"
```

---

## 📈 Benefits

✅ **No more manual Railway log checking**
✅ **Instant notifications on your phone** (Discord mobile app)
✅ **Full error context** for fast debugging
✅ **Historical record** of all errors in Discord
✅ **Rate limiting** prevents spam
✅ **Severity classification** helps prioritize fixes

---

## 🛠️ Technical Details

**File**: `brrow-backend/pest-control.js`
**Discord Webhook**: https://discord.com/api/webhooks/1417209200655863970/...
**Middleware**: `PESTMiddleware()` - Automatically catches all Express errors
**Node Version**: 18.x
**Environment**: Production (Railway)

---

## ✅ Current Status

| Component | Status | Last Verified |
|-----------|--------|---------------|
| Discord Webhook | ✅ Active | Oct 15, 2025 06:16 UTC |
| PEST Middleware | ✅ Running | Oct 15, 2025 06:16 UTC |
| Railway Deployment | ✅ Live | Oct 15, 2025 06:16 UTC |
| updated_at Fix | ✅ Deployed | Oct 15, 2025 06:10 UTC |
| Enhanced Monitoring | ✅ Deployed | Oct 15, 2025 06:12 UTC |

---

## 🎯 Next Steps

1. ✅ Monitor Discord for any new Prisma errors
2. ✅ All 500 errors automatically reported
3. ✅ No need to check Railway logs manually
4. Create iOS archive and upload to App Store
5. Test messaging in production after deployment

**You're all set! Errors will now appear in Discord automatically.** 🚀
