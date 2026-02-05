# Next Steps: After Enabling Vertex AI & Gemini APIs

You've enabled both APIs! Now let's get you authenticated and testing.

---

## Step 1: Get Authentication Credentials

You have **two options** for authentication:

### Option A: API Key (Easiest for Testing) ⚡

**Best for**: Quick testing and development

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **wearit-9b76f**
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **API Key**
5. Copy the API key (you'll need it)
6. **(Recommended)** Restrict the API key:
   - Click on the created API key
   - Under **API restrictions**, select **Restrict key**
   - Choose:
     - ✅ Vertex AI API
     - ✅ Generative Language API
   - Click **Save**

**⚠️ Important**: API keys should NOT be used in production Flutter apps. Use them only for testing or in backend services.

---

### Option B: Service Account (Recommended for Production) 🔒

**Best for**: Production apps, Cloud Functions, Cloud Run

1. Go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Name: `vertex-ai-service`
4. Click **Create and Continue**
5. Grant role: **Vertex AI User**
6. Click **Continue** → **Done**
7. Click on the created service account
8. Go to **Keys** tab
9. Click **Add Key** → **Create new key**
10. Choose **JSON** format
11. Download the JSON file
12. **Keep it secure** - Never commit to git!

---

## Step 2: Test API Access

### Quick Test Using gcloud CLI

If you have `gcloud` CLI installed:

```bash
# Authenticate
gcloud auth login

# Set your project
gcloud config set project wearit-9b76f

# Get access token
gcloud auth print-access-token

# Test Vertex AI API
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://us-central1-aiplatform.googleapis.com/v1/projects/wearit-9b76f/locations/us-central1/publishers/google/models/gemini-1.5-flash:generateContent \
  -d '{
    "contents": [{
      "parts": [{"text": "Hello! Say hi back in one sentence."}]
    }]
  }'
```

---

## Step 3: Update Your Flutter App

### Option 1: Test with API Key (Development Only)

**⚠️ Warning**: Don't hardcode API keys in your app. Use environment variables or Firebase Remote Config.

1. Add API key to your constants (temporarily for testing):

```dart
// lib/constants/app_constants.dart
class AppConstants {
  // ... existing code ...
  
  // Vertex AI Configuration
  static const vertexAiApiKey = 'YOUR_API_KEY_HERE'; // ⚠️ Remove before committing!
  static const vertexAiRegion = 'us-central1';
}
```

2. Update the Vertex AI service to use API key:

```dart
// lib/services/vertex_ai_service.dart
// Add API key support (for testing only)
static Future<String> generateText({
  required String prompt,
  String model = geminiFlash,
  int maxTokens = 1024,
  double temperature = 0.7,
  String? accessToken,
  String? apiKey, // Add this
}) async {
  // ... existing code ...
  
  final headers = {
    'Content-Type': 'application/json',
  };

  // Use API key if provided (for testing)
  if (apiKey != null) {
    final urlWithKey = Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');
    // Use urlWithKey instead of url
  } else if (accessToken != null) {
    headers['Authorization'] = 'Bearer $accessToken';
  }
  
  // ... rest of code ...
}
```

### Option 2: Use Cloud Functions (Production) ✅

**Recommended approach**: Create a Cloud Function that calls Vertex AI, then call the function from your Flutter app.

**Why?**
- API keys stay secure on backend
- Better rate limiting
- Easier to manage costs
- More secure

---

## Step 4: Test in Your Flutter App

### Quick Test

1. Add the test screen to your app:

```dart
// In lib/screens/home_screen.dart or wherever you want to test
import '../screens/vertex_ai_test_screen.dart';

// Add a button
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VertexAITestScreen(),
      ),
    );
  },
  child: Text('Test Vertex AI'),
)
```

2. Run your app and test!

---

## Step 5: Set Up Cloud Functions (For Production)

### Why Cloud Functions?

- ✅ API keys stay secure
- ✅ Better authentication
- ✅ Rate limiting
- ✅ Cost control
- ✅ Easier to scale

### Quick Setup:

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

2. Initialize Functions:
```bash
cd /Volumes/T7/wearit
firebase init functions
```

3. Create a function to call Vertex AI (see example below)

---

## Example: Cloud Function for Vertex AI

```javascript
// functions/index.js
const {onCall} = require("firebase-functions/v2/https");
const {VertexAI} = require("@google-cloud/vertexai");

const vertexAI = new VertexAI({
  project: "wearit-9b76f",
  location: "us-central1",
});

const model = vertexAI.getGenerativeModel({
  model: "gemini-1.5-flash",
});

exports.generateText = onCall(async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const {prompt} = request.data;
  
  const result = await model.generateContent({
    contents: [{role: "user", parts: [{text: prompt}]}],
  });

  return {
    text: result.response.candidates[0].content.parts[0].text,
  };
});
```

---

## Step 6: Monitor Usage & Costs

1. Go to **Vertex AI** → **Usage** in Google Cloud Console
2. Set up **billing alerts**:
   - Go to **Billing** → **Budgets & alerts**
   - Create budget alert (e.g., $10/month)
3. Monitor token usage regularly

---

## Quick Checklist

- [x] Enabled Vertex AI API
- [x] Enabled Gemini API
- [ ] Created API key OR Service Account
- [ ] Tested API access (curl or gcloud)
- [ ] Updated Flutter app with credentials
- [ ] Tested in Flutter app
- [ ] Set up Cloud Functions (for production)
- [ ] Set up billing alerts
- [ ] Ready to use! 🎉

---

## What's Next?

1. **For Testing**: Use API key method (Step 3, Option 1)
2. **For Production**: Set up Cloud Functions (Step 5)
3. **Start Using**: Call Vertex AI from your app!

---

## Need Help?

- Check `VERTEX_AI_SETUP.md` for detailed setup
- Check `PRICING_EXPLANATION.md` for cost info
- Test with `VertexAITestScreen` in your app

---

## Security Reminders

⚠️ **Never commit API keys to git!**
- Use `.gitignore` to exclude config files
- Use environment variables
- Use Firebase Remote Config
- Use Cloud Functions for production

---

You're almost there! Choose your authentication method and start testing! 🚀
