# Switching to Vertex AI API - Setup Guide

## What Changed

Your code now **prefers Vertex AI API** (with OAuth2) over Generative AI API (with API keys).

### Benefits:
- ✅ Access to newer models (`gemini-2.0-flash`, `gemini-2.5-flash`)
- ✅ Better features and performance
- ✅ More production-ready
- ✅ "Nano Banana Pro" might be available as `gemini-2.0-flash` or `gemini-2.5-flash`

### Trade-offs:
- ⚠️ Requires OAuth2 access token (not API keys)
- ⚠️ Slightly more complex setup

---

## Step 1: Get OAuth2 Access Token

You have **two options**:

### Option A: Using gcloud CLI (Easiest for Testing)

1. **Install gcloud CLI** (if not installed):
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Or download from:
   # https://cloud.google.com/sdk/docs/install
   ```

2. **Authenticate**:
   ```bash
   gcloud auth login
   ```

3. **Set your project**:
   ```bash
   gcloud config set project wearit-9b76f
   ```

4. **Get access token**:
   ```bash
   gcloud auth print-access-token
   ```

5. **Copy the token** and add it to `lib/constants/app_constants.dart`:
   ```dart
   static const String? vertexAiAccessToken = 'YOUR_TOKEN_HERE';
   ```

**Note**: This token expires after 1 hour. For production, use a service account.

### Option B: Service Account (For Production)

1. Go to **IAM & Admin** → **Service Accounts**
2. Create or select a service account
3. Grant **Vertex AI User** role
4. Create a JSON key
5. Use the service account to get tokens programmatically

---

## Step 2: Update Your Constants

Open `lib/constants/app_constants.dart` and add your access token:

```dart
static const String? vertexAiAccessToken = 'YOUR_OAUTH2_TOKEN_HERE';
```

**⚠️ Important**: 
- Token expires after 1 hour
- For production, use Cloud Functions instead
- Never commit tokens to git!

---

## Step 3: Test It

1. **Get your access token**:
   ```bash
   gcloud auth print-access-token
   ```

2. **Add to constants file** (temporarily for testing)

3. **Run your app**:
   ```bash
   flutter run
   ```

4. **Try outfit swap** - it should now use Vertex AI API with `gemini-2.0-flash`!

---

## How It Works Now

### Priority Order:
1. **If `accessToken` is provided** → Uses Vertex AI API (`gemini-2.0-flash`, `gemini-2.5-flash`)
2. **If only `apiKey` is provided** → Falls back to Generative AI API (`gemini-1.5-flash`)

### Current Models Available:

**Vertex AI API** (with OAuth2):
- `gemini-2.0-flash` ✅ (default now)
- `gemini-2.0-flash-lite`
- `gemini-2.5-flash`
- `gemini-1.5-flash` (also available)

**Generative AI API** (with API key - fallback):
- `gemini-1.5-flash`
- `gemini-1.5-pro`

---

## Quick Test Command

```bash
# Get token
TOKEN=$(gcloud auth print-access-token)

# Test Vertex AI API
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  https://us-central1-aiplatform.googleapis.com/v1/projects/wearit-9b76f/locations/us-central1/publishers/google/models/gemini-2.0-flash:generateContent \
  -d '{
    "contents": [{
      "parts": [{"text": "Hello! Say hi back."}]
    }]
  }'
```

---

## For Production

**Don't use access tokens in the Flutter app!** Instead:

1. **Create Cloud Functions** that call Vertex AI API
2. **Use service account** in Cloud Functions
3. **Call Cloud Functions** from your Flutter app
4. **No tokens/keys in client code** ✅

---

## Troubleshooting

### Error: "Invalid access token"
- Token expired (they last 1 hour)
- Run `gcloud auth print-access-token` again
- Make sure you're authenticated: `gcloud auth login`

### Error: "Permission denied"
- Check service account has **Vertex AI User** role
- Verify project is correct: `wearit-9b76f`

### Error: "Model not found"
- Make sure you're using correct model name
- Check available models: `gcloud ai models list --region=us-central1`

---

## Summary

✅ **Code updated** to prefer Vertex AI API  
✅ **Uses `gemini-2.0-flash`** by default  
✅ **Falls back** to Generative AI API if no token  
✅ **Get token**: `gcloud auth print-access-token`  
✅ **Add to constants**: `vertexAiAccessToken`  

**Next**: Get your access token and test! 🚀
