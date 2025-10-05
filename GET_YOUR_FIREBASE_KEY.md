# Get Your Firebase Service Account - EXACT STEPS

## ✅ You Already Have Firebase Set Up!

**Your Firebase Project:** `brrow-c8bb9`

---

## 🚀 Get Service Account JSON (5 Minutes)

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/project/brrow-c8bb9/settings/serviceaccounts/adminsdk

**Or manually:**
1. Go to: https://console.firebase.google.com
2. Click on project **"brrow-c8bb9"**
3. Click ⚙️ (Settings) → **Project settings**
4. Click **"Service accounts"** tab

### Step 2: Generate New Private Key
1. You'll see "Firebase Admin SDK" section
2. Click the **"Generate new private key"** button
3. Popup appears → Click **"Generate key"**
4. A file downloads: `brrow-c8bb9-firebase-adminsdk-xxxxx.json`

### Step 3: Minify the JSON

**Option A: Use Online Tool (Easiest)**
1. Open the downloaded JSON file in any text editor
2. Copy ALL the contents
3. Go to: https://jsonformatter.org/json-minify
4. Paste your JSON
5. Click "Minify"
6. Copy the output (single line)

**Option B: Use Terminal**
```bash
# Navigate to Downloads
cd ~/Downloads

# Minify using Python
cat brrow-c8bb9-firebase-adminsdk-*.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)))"
```

Copy the output!

### Step 4: Add to Railway

1. Go to: https://railway.app
2. Select your Brrow project
3. Click **brrow-backend-nodejs** service
4. Click **"Variables"** tab
5. Find `FIREBASE_SERVICE_ACCOUNT` (or create it)
6. Paste the minified JSON (single line)
7. Click **Save** / **Add**

### Step 5: Wait for Redeploy
- Railway auto-redeploys (takes 2-3 minutes)
- Check logs: `railway logs | grep Firebase`
- Should see: `✅ Firebase service account loaded`

---

## 📋 Example of What It Should Look Like

### ❌ WRONG (Has line breaks):
```json
{
  "type": "service_account",
  "project_id": "brrow-c8bb9",
  "private_key_id": "abc123",
  ...
}
```

### ✅ CORRECT (One line):
```json
{"type":"service_account","project_id":"brrow-c8bb9","private_key_id":"abc123","private_key":"-----BEGIN PRIVATE KEY-----\nABC...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk@brrow-c8bb9.iam.gserviceaccount.com",...}
```

---

## 🔗 Quick Links

**Direct Link to Your Firebase Service Accounts:**
https://console.firebase.google.com/project/brrow-c8bb9/settings/serviceaccounts/adminsdk

**Railway Dashboard:**
https://railway.app

**JSON Minifier:**
https://jsonformatter.org/json-minify

---

## ✅ Verification

After adding to Railway, run:
```bash
curl -s https://brrow-backend-nodejs-production.up.railway.app/health | python3 -m json.tool | grep -A 3 firebase
```

Should see:
```json
"firebase": {
  "status": "healthy"
}
```

---

**That's it! This will fix push notifications.** 🚀
