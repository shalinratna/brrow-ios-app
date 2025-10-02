# AUDIO UPLOAD FIX - DEPLOYMENT INSTRUCTIONS

## CRITICAL FIX APPLIED

**Date**: October 1, 2025
**Issue**: Missing `/api/messages/upload/audio` endpoint
**Status**: ✅ Code added, ready for deployment

---

## WHAT WAS FIXED

Added the missing audio upload endpoint that iOS VoiceRecorderView was calling.

**File Modified**: `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/routes/messages.js`
**Lines Added**: 572-632 (new audio upload endpoint)

### New Endpoint Details
- **URL**: `POST /api/messages/upload/audio`
- **Authentication**: Required (JWT token)
- **Method**: Multipart form-data with field name `audio`
- **Max File Size**: 10MB
- **Supported Formats**: All audio/* MIME types (m4a, mp3, wav, etc.)
- **Upload Destination**: Cloudinary `brrow/chat_audio/` folder
- **Response**: `{success: true, data: {url: string, duration: number}}`

---

## DEPLOYMENT STEPS

### Step 1: Verify Local Changes
```bash
cd /Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend

# Check that the file was modified
git status

# Review the changes
git diff routes/messages.js
```

### Step 2: Commit Changes
```bash
# Stage the changes
git add routes/messages.js

# Commit with descriptive message
git commit -m "Fix: Add missing audio upload endpoint for voice messages

- Add POST /api/messages/upload/audio endpoint
- Validates audio files (10MB limit, audio/* MIME types)
- Uploads to Cloudinary brrow/chat_audio folder
- Returns Cloudinary URL and duration
- Fixes 404 error when iOS sends voice messages"
```

### Step 3: Push to Remote
```bash
# Push to your main branch (adjust branch name if needed)
git push origin main

# OR if you're on a different branch:
git push origin bubbles-analytics
```

### Step 4: Deploy to Railway

**Option A: Automatic Deployment (if Railway is connected to GitHub)**
1. Railway will automatically detect the new commit
2. It will trigger a new deployment
3. Wait 2-5 minutes for deployment to complete
4. Check Railway dashboard for deployment status

**Option B: Manual Deployment**
1. Log into Railway dashboard: https://railway.app/dashboard
2. Select your `brrow-backend-nodejs` project
3. Go to "Deployments" tab
4. Click "Deploy" or "Redeploy"
5. Wait for deployment to complete

### Step 5: Verify Deployment
```bash
# Check if the endpoint is live
curl -X POST https://brrow-backend-nodejs-production.up.railway.app/api/messages/upload/audio \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: multipart/form-data" \
  -F "audio=@test-audio.m4a"

# Expected response (without auth): 401 Unauthorized
# Expected response (with auth, no file): 400 No audio file provided
# Expected response (with auth + file): 200 {success: true, data: {...}}
```

---

## TESTING FROM iOS APP

### 1. Launch iOS App
Open Xcode and run the app on simulator or device.

### 2. Start a Chat
Navigate to any conversation in the messaging section.

### 3. Test Voice Message
1. Tap the microphone icon in the message input area
2. Hold to record a voice message (up to 2 minutes)
3. Waveform animation should appear
4. Release to send OR swipe left to cancel
5. Voice message should upload to Cloudinary
6. Message should appear in chat with audio player
7. Recipient can play the audio

### 4. Verify Success
- ✅ No 404 error in Xcode console
- ✅ "Audio upload successful" log message
- ✅ Voice message appears in chat
- ✅ Audio player shows play button and waveform
- ✅ Recipient receives voice message via WebSocket

---

## TROUBLESHOOTING

### Issue: 404 Not Found
**Cause**: Backend not deployed yet or deployment failed
**Fix**:
1. Check Railway deployment logs
2. Verify routes/messages.js was pushed to Git
3. Redeploy manually from Railway dashboard

### Issue: 401 Unauthorized
**Cause**: No JWT token or expired token
**Fix**:
1. Ensure user is logged into iOS app
2. Check AuthManager has valid authToken
3. Try logging out and back in

### Issue: 400 No audio file provided
**Cause**: iOS sending wrong multipart field name
**Fix**:
- Backend expects field name `audio`
- iOS sends with field name `audio` (line 527 in ChatDetailViewModel.swift)
- These should match - if not, update one to match the other

### Issue: 413 Payload Too Large
**Cause**: Audio file exceeds 10MB limit
**Fix**:
- Voice recordings should be under 2 minutes (typically 1-2MB)
- If exceeding limit, check iOS recording settings
- Consider increasing backend limit if needed

### Issue: Cloudinary Upload Failed
**Cause**: Cloudinary credentials missing or invalid
**Fix**:
1. Check Railway environment variables:
   - CLOUDINARY_CLOUD_NAME=brrow
   - CLOUDINARY_API_KEY=918121214196197
   - CLOUDINARY_API_SECRET=(secret key)
2. Verify credentials are correct in Railway dashboard
3. Restart backend service after updating env vars

---

## ENVIRONMENT VARIABLES (Railway)

Ensure these are set in Railway dashboard:

```env
CLOUDINARY_CLOUD_NAME=brrow
CLOUDINARY_API_KEY=918121214196197
CLOUDINARY_API_SECRET=_uv_x8ku7vRhFN7Z0Ko61xibqYY
DATABASE_URL=postgresql://...
JWT_SECRET=brrow-secret-key-2024
PORT=3002
```

---

## ROLLBACK PLAN

If the new endpoint causes issues:

```bash
# Revert the commit
git revert HEAD

# Push the revert
git push origin main

# Railway will automatically deploy the reverted version
```

---

## NEXT STEPS AFTER DEPLOYMENT

1. ✅ Test voice messages from multiple users
2. ✅ Verify audio plays correctly for recipients
3. ✅ Check Cloudinary dashboard for uploaded audio files
4. ✅ Monitor Railway logs for any errors
5. ⚠️ (Optional) Add NSFW detection for audio transcription
6. ⚠️ (Optional) Add audio compression to reduce file sizes

---

## ESTIMATED TIME

- **Code Fix**: ✅ Complete (10 minutes)
- **Git Commit/Push**: 2 minutes
- **Railway Deployment**: 3-5 minutes
- **iOS Testing**: 5 minutes
- **Total**: ~15 minutes

---

## SUCCESS CRITERIA

✅ Backend endpoint returns 200 OK with valid audio file
✅ iOS voice messages upload successfully
✅ Audio appears in chat with player controls
✅ Recipient can play the audio message
✅ Cloudinary shows files in `brrow/chat_audio/` folder
✅ No 404 errors in iOS logs

---

## CONTACT

If you encounter issues during deployment:
1. Check Railway deployment logs
2. Review iOS Xcode console for errors
3. Check Cloudinary dashboard for upload attempts
4. Verify all environment variables are set

---

**Status**: Ready for deployment
**Confidence**: High - fix is straightforward and follows existing patterns
