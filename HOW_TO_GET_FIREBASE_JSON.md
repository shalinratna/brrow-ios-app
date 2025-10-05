# How to Get Firebase Service Account JSON

## 📋 Step-by-Step Guide

### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com
2. Select your **Brrow** project (or whatever your Firebase project is named)

### Step 2: Navigate to Service Accounts
1. Click the **⚙️ Settings icon** (top left, next to "Project Overview")
2. Click **"Project settings"**
3. Click the **"Service accounts"** tab at the top

### Step 3: Generate New Private Key
1. Scroll down to "Firebase Admin SDK"
2. Click the **"Generate new private key"** button
3. A popup will appear warning you to keep it secure
4. Click **"Generate key"**
5. A JSON file will download (e.g., `brrow-firebase-adminsdk-abc123.json`)

---

## 📄 What the JSON Looks Like

### Raw Downloaded File (Has Line Breaks)
```json
{
  "type": "service_account",
  "project_id": "brrow-app",
  "private_key_id": "abc123def456...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@brrow-app.iam.gserviceaccount.com",
  "client_id": "123456789012345678",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40brrow-app.iam.gserviceaccount.com"
}
```

### What Railway Needs (One Line, No Formatting)
```json
{"type":"service_account","project_id":"brrow-app","private_key_id":"abc123def456...","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xxxxx@brrow-app.iam.gserviceaccount.com","client_id":"123456789012345678","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40brrow-app.iam.gserviceaccount.com"}
```

**Notice:**
- ✅ All on ONE line
- ✅ No spaces between keys
- ✅ `\n` characters are kept in the private_key (they're part of the string)

---

## 🔧 How to Convert Downloaded JSON to Railway Format

### Method 1: Using Online Tool (Easiest)
1. Download the JSON file from Firebase
2. Go to: https://jsonformatter.org/json-minify
3. Paste the contents of your downloaded JSON
4. Click "Minify"
5. Copy the output (it's now one line)
6. Paste into Railway's `FIREBASE_SERVICE_ACCOUNT` variable

### Method 2: Using Terminal (Mac/Linux)

```bash
# Navigate to where you downloaded the file
cd ~/Downloads

# Find your Firebase file (it will be named something like brrow-firebase-adminsdk-xxxxx.json)
ls -la | grep firebase

# Minify it using Python (built into Mac)
cat brrow-firebase-adminsdk-*.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)))"
```

The output will be one long line - copy that!

### Method 3: Using Node.js

```bash
# Navigate to where you downloaded the file
cd ~/Downloads

# Minify using Node
node -e "console.log(JSON.stringify(require('./brrow-firebase-adminsdk-xxxxx.json')))"
```

Replace `brrow-firebase-adminsdk-xxxxx.json` with your actual filename.

---

## 🚀 Adding to Railway

### Step 1: Copy Your Minified JSON
After running one of the methods above, you'll have a long single-line JSON string. Copy it.

### Step 2: Go to Railway Dashboard
1. Go to: https://railway.app
2. Select your Brrow project
3. Click on your **brrow-backend-nodejs** service
4. Click the **"Variables"** tab

### Step 3: Update the Variable
1. Look for `FIREBASE_SERVICE_ACCOUNT`
   - If it exists, click on it
   - If it doesn't exist, click **"+ New Variable"**

2. Paste your minified JSON as the value
   - **Variable name:** `FIREBASE_SERVICE_ACCOUNT`
   - **Value:** (paste the long single-line JSON)

3. Click **"Add"** or **"Update"**

### Step 4: Railway Auto-Redeploys
- Railway will automatically redeploy your service
- Wait 2-3 minutes
- Check logs for: `✅ Firebase service account loaded`

---

## ✅ How to Verify It Worked

### Check Railway Logs
```bash
# In your terminal, from the brrow-backend directory
railway logs | grep Firebase
```

**Should see:**
```
✅ Firebase service account loaded
```

**Should NOT see:**
```
❌ Failed to parse Firebase credentials
```

### Check Backend Health
```bash
curl https://brrow-backend-nodejs-production.up.railway.app/health
```

Look for:
```json
{
  "monitoring": {
    "firebase": {
      "status": "healthy"
    }
  }
}
```

---

## 🎯 Quick Reference

### What You Need:
1. Firebase Console access
2. Download service account JSON
3. Minify it to one line
4. Add to Railway as `FIREBASE_SERVICE_ACCOUNT`

### Common Mistakes:
❌ Pasting the pretty-printed JSON (with line breaks)
❌ Missing the `\n` characters in private_key
❌ Adding quotes around the entire JSON
❌ Using wrong variable name

### Correct Format:
✅ Single line JSON
✅ Keep `\n` in private_key as-is
✅ No extra quotes
✅ Variable name: `FIREBASE_SERVICE_ACCOUNT`

---

## 💡 Alternative: If You Can't Find Your Firebase Project

### Check if Firebase is Set Up
1. Go to https://console.firebase.google.com
2. Look for a project named "Brrow" or "brrow-app" or similar

### If No Firebase Project Exists
You need to create one first:

1. **Create Firebase Project:**
   - Go to https://console.firebase.google.com
   - Click "Add project"
   - Name it "Brrow"
   - Follow the wizard

2. **Enable Cloud Messaging:**
   - In Firebase Console, go to "Build" → "Cloud Messaging"
   - Click "Get Started"

3. **Add iOS App:**
   - Click the iOS icon
   - Bundle ID: (get from Xcode - usually com.yourname.Brrow)
   - Download `GoogleService-Info.plist`
   - Add to your Xcode project

4. **Then Get Service Account:**
   - Follow the steps at the top of this document

---

## 🆘 Still Stuck?

### Quick Test - Do You Have Firebase?
Run this in terminal:
```bash
# Check if you have Firebase files in your iOS project
find /Users/shalin/Documents/Projects/Xcode/Brrow -name "GoogleService-Info.plist" 2>/dev/null
```

**If found:** You have Firebase set up! Just need to get service account.
**If not found:** Need to set up Firebase first.

---

**Need help with any of these steps? Let me know which method you want to use!** 🚀
