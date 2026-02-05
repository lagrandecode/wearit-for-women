# Nano Banana Pro Model Setup

## What is Nano Banana Pro?

Nano Banana Pro is a model you saw in Vertex AI Studio, described as "Best model for image generation and editing."

## Current Implementation

I've updated the code to use Nano Banana Pro, but we need to verify the correct API model name.

### Possible Model Names:

1. **`gemini-2.0-flash-exp`** (currently set - experimental)
2. **`gemini-2.0-flash`** (if available)
3. **`gemini-2.0-flash-thinking-exp`** (if available)
4. Or a different name entirely

## How to Find the Correct Model Name

### Option 1: Check in Vertex AI Studio
1. Go to Vertex AI Studio
2. Select "Nano Banana Pro"
3. Look at the API endpoint or model name shown
4. The actual API name might be different from the display name

### Option 2: List Available Models via API
You can call the API to list available models:

```bash
curl "https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_API_KEY"
```

This will show all available models and their exact names.

### Option 3: Check Documentation
- [Gemini API Models](https://ai.google.dev/models/gemini)
- Check for latest model names

## Current Code

The outfit swap feature is now set to use:
```dart
model: VertexAIService.nanoBananaPro
```

Which is currently mapped to: `gemini-2.0-flash-exp`

## If Model Name is Wrong

If you get a 404 error saying the model is not found, we need to:
1. Find the correct model name
2. Update `nanoBananaPro` constant in `lib/services/vertex_ai_service.dart`
3. Try again

## Testing

1. Run the outfit swap feature
2. If it works → Great! ✅
3. If you get a 404 error → We need to update the model name

Let me know what happens when you test it!
