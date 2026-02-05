# Vertex AI (Gemini) API Setup Guide

This guide will help you enable and configure Vertex AI API (Gemini models) for your Wearit app.

## Prerequisites

- Google Cloud Project: `wearit-9b76f` (already set up)
- Firebase project configured
- Google Cloud Console access

---

## Part 1: Enable Vertex AI API in Google Cloud Console

### Step 1: Enable Vertex AI API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **wearit-9b76f**
3. Navigate to **APIs & Services** → **Library**
4. Search for **"Vertex AI API"**
5. Click on **Vertex AI API**
6. Click **Enable**

### Step 2: Enable Generative AI API (Gemini)

1. In the same **APIs & Services** → **Library** page
2. Search for **"Generative Language API"** or **"Gemini API"**
3. Click on it and **Enable**

**Note**: You might see both APIs. Enable both to ensure full access to Gemini models.

---

## Part 2: Create API Credentials

### Option A: Use Service Account (Recommended for Backend)

**Best for**: Cloud Functions, Cloud Run, or backend services

1. Go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Name: `vertex-ai-service`
4. Click **Create and Continue**
5. Grant role: **Vertex AI User** (or **AI Platform User**)
6. Click **Continue** → **Done**
7. Click on the created service account
8. Go to **Keys** tab
9. Click **Add Key** → **Create new key**
10. Choose **JSON** format
11. Download the JSON file (keep it secure - never commit to git!)

### Option B: Use API Key (For Testing/Development)

**Best for**: Quick testing and development

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Copy the API key
4. (Optional) Restrict the API key:
   - Click on the API key
   - Under **API restrictions**, select **Restrict key**
   - Choose **Vertex AI API** and **Generative Language API**
   - Save

**⚠️ Security Warning**: API keys should never be exposed in client-side code. Use them only in backend services or Cloud Functions.

---

## Part 3: Get Your Project Details

You'll need these values:

1. **Project ID**: `wearit-9b76f` (already have this)
2. **Region**: Choose a region (e.g., `us-central1`, `us-east1`, `europe-west1`)
   - Go to **Vertex AI** → **Workbench** to see available regions
3. **API Key** (if using API key method) or **Service Account JSON** (if using service account)

---

## Part 4: Available Gemini Models

Vertex AI offers several Gemini models:

- **gemini-1.5-flash** - Fast, efficient (good for most use cases)
- **gemini-1.5-pro** - More capable, slower
- **gemini-1.5-flash-8b** - Smaller, faster (nano-like)
- **gemini-pro** - Standard model
- **gemini-pro-vision** - For image understanding

**For "nano banana" (small/fast model)**: Use `gemini-1.5-flash` or `gemini-1.5-flash-8b`

---

## Part 5: Pricing

### Yes, Vertex AI is Pay-Per-Use (Token-Based)

Vertex AI uses a **pay-per-token pricing model**, not a subscription. You only pay for what you use.

### How It Works:

1. **Token-Based Pricing**:
   - You're charged based on **input tokens** (your prompt) and **output tokens** (AI response)
   - 1 token ≈ 4 characters (roughly 0.75 words)
   - Example: "Hello, how are you?" = ~5 tokens

2. **Free Tier** (Always Available):
   - **$0/month** - No credit card required to start
   - **Free quota** per month (varies by model):
     - Gemini 1.5 Flash: ~1,500 requests/day free
     - Gemini 1.5 Pro: ~50 requests/day free
   - After free quota: Pay per token used

3. **Pricing Examples** (as of 2024, check current rates):
   - **Gemini 1.5 Flash** (fast/nano model):
     - Input: ~$0.075 per 1M tokens
     - Output: ~$0.30 per 1M tokens
   - **Gemini 1.5 Pro** (more capable):
     - Input: ~$1.25 per 1M tokens
     - Output: ~$5.00 per 1M tokens

### Cost Calculation Example:

**Scenario**: Generate outfit recommendation (500 tokens input, 300 tokens output)

Using Gemini Flash:
- Input cost: (500 / 1,000,000) × $0.075 = $0.0000375
- Output cost: (300 / 1,000,000) × $0.30 = $0.00009
- **Total: ~$0.00013 per request** (less than 1 cent!)

**For 1,000 requests/month**:
- 1,000 × $0.00013 = **$0.13/month** (very affordable!)

### Free Tier Limits:

- **Rate Limits**: 15 requests per minute (RPM) for free tier
- **Daily Quota**: Varies by model (check Google Cloud Console)
- **Monthly Quota**: Resets monthly

### Cost Management Tips:

1. **Use Gemini Flash** for most tasks (cheapest, fastest)
2. **Set up billing alerts** in Google Cloud Console
3. **Monitor usage** in Cloud Console → Vertex AI → Usage
4. **Use caching** for repeated queries
5. **Set daily/monthly quotas** to prevent unexpected charges

### Billing:

- **No upfront cost** - Start free
- **Pay only for what you use** after free tier
- **Billed monthly** to your Google Cloud account
- **Set budget alerts** to avoid surprises

### Check Current Pricing:

- Official pricing: https://cloud.google.com/vertex-ai/pricing
- Pricing calculator: https://cloud.google.com/products/calculator
- Your usage dashboard: Google Cloud Console → Vertex AI → Usage

**Bottom Line**: Yes, it's pay-per-use (per token), but very affordable. The free tier is generous, and costs are typically less than $1/month for small apps.

---

## Part 6: Testing API Access

### Using curl (Quick Test)

Replace `YOUR_API_KEY` with your actual API key:

```bash
curl \
  -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://us-central1-aiplatform.googleapis.com/v1/projects/wearit-9b76f/locations/us-central1/publishers/google/models/gemini-1.5-flash:predict \
  -d '{
    "instances": [{
      "prompt": "Hello, how are you?"
    }]
  }'
```

### Using gcloud CLI

```bash
# Authenticate
gcloud auth login

# Set project
gcloud config set project wearit-9b76f

# Test API
gcloud ai models predict \
  --model=gemini-1.5-flash \
  --region=us-central1 \
  --json-request=request.json
```

---

## Part 7: Flutter Integration

See the `lib/services/vertex_ai_service.dart` file for implementation.

**Important**: 
- For production, use Vertex AI API calls from **Cloud Functions** or **Cloud Run**
- Never expose API keys in your Flutter app
- Use Firebase Authentication tokens to authenticate backend requests

---

## Part 8: Security Best Practices

1. **Never commit API keys to git**
2. **Use environment variables** or **Firebase Remote Config** for API keys
3. **Use Service Accounts** for backend services
4. **Restrict API keys** to specific APIs and IPs if possible
5. **Use Cloud Functions/Cloud Run** as a proxy for API calls
6. **Implement rate limiting** to prevent abuse

---

## Troubleshooting

### Error: "API not enabled"
- Make sure Vertex AI API is enabled in Google Cloud Console
- Wait a few minutes after enabling for propagation

### Error: "Permission denied"
- Check that your service account has **Vertex AI User** role
- Verify API key has correct permissions

### Error: "Region not available"
- Check available regions in Vertex AI console
- Use `us-central1` as default if unsure

### Error: "Quota exceeded"
- Check your quota limits in **APIs & Services** → **Quotas**
- Request quota increase if needed

---

## Next Steps

1. Enable Vertex AI API (Step 1)
2. Create credentials (Step 2)
3. Test API access (Step 6)
4. Integrate into Flutter app (see `lib/services/vertex_ai_service.dart`)

---

## Resources

- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Gemini API Reference](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing)
- [Authentication Guide](https://cloud.google.com/docs/authentication)
