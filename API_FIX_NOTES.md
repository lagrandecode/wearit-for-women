# API Authentication Fix

## Problem
Vertex AI API doesn't support API keys - it requires OAuth2 access tokens. This caused 401/402 errors.

## Solution
Updated the service to use **Generative AI API** (REST API) when API keys are provided, which supports API keys.

## What Changed

### Two API Endpoints:
1. **Vertex AI API** (`aiplatform.googleapis.com`)
   - Requires OAuth2 access tokens
   - Used when `accessToken` is provided

2. **Generative AI API** (`generativelanguage.googleapis.com`)
   - Supports API keys ✅
   - Used when `apiKey` is provided
   - This is what we're using now

## Important: Enable Generative Language API

Make sure you've enabled **Generative Language API** (not just Vertex AI API):

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **wearit-9b76f**
3. Navigate to **APIs & Services** → **Library**
4. Search for **"Generative Language API"**
5. Click **Enable**

## API Key Setup

Your API key should have access to:
- ✅ Generative Language API
- ✅ Vertex AI API (optional, for OAuth2 method)

## Testing

The outfit swap feature should now work with your API key!
