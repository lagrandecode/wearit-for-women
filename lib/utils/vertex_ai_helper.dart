import 'package:firebase_auth/firebase_auth.dart';
import '../services/vertex_ai_service.dart';
import '../constants/app_constants.dart';

/// Helper class for Vertex AI operations
/// 
/// This class provides convenient methods for common AI tasks in the Wearit app.
class VertexAIHelper {
  /// Generate outfit recommendations based on user preferences
  /// 
  /// [preferences] - Map containing user preferences (style, season, budget, etc.)
  /// [accessToken] - Optional access token for API calls
  /// 
  /// Returns AI-generated outfit recommendations
  static Future<String> generateOutfitRecommendations({
    required Map<String, dynamic> preferences,
    String? accessToken,
  }) async {
    final prompt = '''
You are a fashion stylist assistant for Wearit, a fashion app for women.

User Preferences:
- Style: ${preferences['style'] ?? 'not specified'}
- Season: ${preferences['season'] ?? 'not specified'}
- Budget: ${preferences['budget'] ?? 'not specified'}
- Outing Type: ${preferences['outing_type'] ?? 'not specified'}

Please provide:
1. Outfit recommendations (3-5 options)
2. Key pieces needed
3. Styling tips
4. Color palette suggestions

Keep the response concise and fashion-forward.
''';

    return await VertexAIService.generateText(
      prompt: prompt,
      model: VertexAIService.geminiFlash, // Fast, efficient model
      maxTokens: 1500,
      temperature: 0.8, // More creative
      accessToken: accessToken,
      apiKey: AppConstants.vertexAiApiKey,
    );
  }

  /// Analyze an outfit image and provide styling feedback
  /// 
  /// [imageBase64] - Base64 encoded image
  /// [mimeType] - Image MIME type
  /// [accessToken] - Optional access token
  /// 
  /// Returns styling analysis and suggestions
  static Future<String> analyzeOutfitImage({
    required String imageBase64,
    required String mimeType,
    String? accessToken,
  }) async {
    final prompt = '''
Analyze this outfit image and provide:
1. Style description
2. Color palette
3. Fit assessment
4. Styling suggestions
5. Occasion appropriateness

Be constructive and fashion-forward in your feedback.
''';

    return await VertexAIService.generateTextWithImage(
      prompt: prompt,
      imageBase64: imageBase64,
      mimeType: mimeType,
      model: VertexAIService.geminiFlash, // Fast model that supports vision
      accessToken: accessToken,
      apiKey: AppConstants.vertexAiApiKey,
    );
  }

  /// Generate product descriptions for fashion items
  /// 
  /// [itemDetails] - Map containing item details (type, color, material, etc.)
  /// [accessToken] - Optional access token
  /// 
  /// Returns AI-generated product description
  static Future<String> generateProductDescription({
    required Map<String, dynamic> itemDetails,
    String? accessToken,
  }) async {
    final prompt = '''
Create an engaging product description for a fashion item:

Item Type: ${itemDetails['type'] ?? 'not specified'}
Color: ${itemDetails['color'] ?? 'not specified'}
Material: ${itemDetails['material'] ?? 'not specified'}
Style: ${itemDetails['style'] ?? 'not specified'}

Write a compelling, concise product description (2-3 sentences) that highlights:
- Key features
- Style appeal
- Versatility
- Quality

Make it appealing to fashion-conscious women.
''';

    return await VertexAIService.generateText(
      prompt: prompt,
      model: VertexAIService.geminiFlash,
      maxTokens: 200,
      temperature: 0.7,
      accessToken: accessToken,
      apiKey: AppConstants.vertexAiApiKey,
    );
  }

  /// Get styling tips based on user's wardrobe
  /// 
  /// [wardrobeItems] - List of wardrobe items
  /// [accessToken] - Optional access token
  /// 
  /// Returns personalized styling tips
  static Future<String> getStylingTips({
    required List<Map<String, dynamic>> wardrobeItems,
    String? accessToken,
  }) async {
    final itemsSummary = wardrobeItems
        .map((item) => '${item['type']} (${item['color'] ?? 'various'})')
        .join(', ');

    final prompt = '''
Based on this wardrobe:
$itemsSummary

Provide:
1. Outfit combinations (3-5 suggestions)
2. Missing pieces to consider
3. Styling tips for mixing and matching
4. Seasonal recommendations

Keep it practical and inspiring.
''';

    return await VertexAIService.generateText(
      prompt: prompt,
      model: VertexAIService.geminiFlash,
      maxTokens: 1000,
      temperature: 0.8,
      accessToken: accessToken,
      apiKey: AppConstants.vertexAiApiKey,
    );
  }

  /// Get access token from Firebase Auth (for testing)
  /// 
  /// Note: In production, API calls should go through Cloud Functions
  /// which will handle authentication with Vertex AI.
  static Future<String?> getAccessToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    // Get Firebase ID token
    final idToken = await user.getIdToken();
    
    // Note: This token is for Firebase, not Vertex AI
    // For Vertex AI, you need to use gcloud auth or service account
    // In production, use Cloud Functions to proxy requests
    return idToken;
  }
}
