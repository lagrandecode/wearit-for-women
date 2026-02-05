import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Service for interacting with Vertex AI (Gemini) API
/// 
/// ⚠️ IMPORTANT: For production, API calls should be made from Cloud Functions/Cloud Run,
/// not directly from the Flutter app. This service is for development/testing only.
class VertexAIService {
  // Configuration
  static const String _projectId = AppConstants.firebaseProjectId;
  static const String _region = AppConstants.vertexAiRegion;
  
  // Available models for Generative AI API (REST) - supports API keys
  // Text generation models:
  static const String geminiFlash = 'gemini-pro'; // Fast, supports vision (works with API keys)
  static const String geminiFlashAlt = 'gemini-1.5-flash'; // Alternative (may not be available)
  static const String geminiFlash8B = 'gemini-1.5-flash-8b'; // Nano-like model
  static const String geminiPro = 'gemini-1.5-pro'; // More capable, supports vision
  
  // Image generation models (Nano Banana series):
  static const String nanoBanana = 'gemini-2.5-flash-image'; // Fast image generation
  static const String nanoBananaPro = 'gemini-3-pro-image-preview'; // Professional image generation/editing (Nano Banana Pro)
  
  // Available models for Vertex AI API - requires OAuth2 (from documentation)
  static const String gemini20Flash = 'gemini-2.0-flash'; // Latest from Vertex AI API
  static const String gemini20FlashLite = 'gemini-2.0-flash-lite'; // Lite version
  static const String gemini25Flash = 'gemini-2.5-flash'; // Latest version
  // Note: gemini-pro-vision doesn't exist in REST API - use gemini-1.5-flash or gemini-1.5-pro for vision

  /// Base URL for Vertex AI API (requires OAuth2)
  static String get _vertexAiBaseUrl => 
      'https://$_region-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_region/publishers/google/models';
  
  /// Base URL for Generative AI API (supports API keys)
  /// Use v1beta for image generation models (Nano Banana)
  static String get _generativeAiBaseUrl => 
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Generate text using Gemini model
  /// 
  /// [prompt] - The text prompt to send to the model
  /// [model] - The model to use (default: gemini-1.5-flash)
  /// [maxTokens] - Maximum tokens in response (default: 1024)
  /// [temperature] - Sampling temperature 0.0-1.0 (default: 0.7)
  /// [accessToken] - OAuth access token (from gcloud auth print-access-token)
  /// [apiKey] - API key (for Generative AI API - recommended for testing)
  /// 
  /// Returns the generated text response
  /// 
  /// ⚠️ For production, call this from Cloud Functions. Never expose API keys in client code.
  static Future<String> generateText({
    required String prompt,
    String model = geminiFlash,
    int maxTokens = 1024,
    double temperature = 0.7,
    String? accessToken, // For testing with gcloud auth token
    String? apiKey, // For Generative AI API (supports API keys)
  }) async {
    try {
      Uri url;
      
      // Prefer Vertex AI API if access token is provided (newer models, better features)
      if (accessToken != null) {
        // Vertex AI API endpoint (requires OAuth2) - supports gemini-2.0-flash, gemini-2.5-flash
        url = Uri.parse('$_vertexAiBaseUrl/$model:generateContent');
      } else if (apiKey != null) {
        // Generative AI API endpoint (supports API keys)
        // For image models (Nano Banana), use v1beta endpoint
        url = Uri.parse('$_generativeAiBaseUrl/$model:generateContent');
      } else {
        throw Exception('Either accessToken (for Vertex AI) or apiKey (for Generative AI) must be provided');
      }
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': maxTokens,
          'temperature': temperature,
        }
      };

      final headers = {
        'Content-Type': 'application/json',
      };

      // Only add Authorization header for Vertex AI (OAuth2)
      // Add Authorization header for Vertex AI API (OAuth2)
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both Vertex AI and Generative AI API response formats
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'];
            return text ?? 'No response generated';
          }
        }
        return 'No response generated';
      } else {
        final errorBody = response.body;
        String errorMessage = 'API error: ${response.statusCode}';
        
        if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage += '\n\nAuthentication failed.';
          if (apiKey != null) {
            errorMessage += '\n\nNote: Your API key might be invalid or restricted.';
            errorMessage += '\nMake sure you enabled "Generative Language API".';
          }
        }
        
        errorMessage += '\n\nResponse: $errorBody';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to generate text: $e');
    }
  }

  /// Generate text with image input (multimodal)
  /// 
  /// [prompt] - The text prompt
  /// [imageBase64] - Base64 encoded image
  /// [mimeType] - Image MIME type (e.g., 'image/jpeg', 'image/png')
  /// [model] - The model to use (default: gemini-2.0-flash for Vertex AI)
  /// [accessToken] - OAuth access token (required for Vertex AI API)
  /// [apiKey] - API key (for Generative AI API - fallback)
  /// 
  /// Returns the generated text response
  static Future<String> generateTextWithImage({
    required String prompt,
    required String imageBase64,
    required String mimeType,
    String model = gemini20Flash, // Use gemini-2.0-flash (Vertex AI API)
    String? accessToken,
    String? apiKey,
  }) async {
    try {
      Uri url;
      
      // Prefer Vertex AI API if access token is provided (newer models, better features)
      if (accessToken != null) {
        // Vertex AI API endpoint (requires OAuth2) - supports gemini-2.0-flash, gemini-2.5-flash
        url = Uri.parse('$_vertexAiBaseUrl/$model:generateContent');
      } else if (apiKey != null) {
        // Generative AI API endpoint (supports API keys)
        // For image models (Nano Banana), use v1beta endpoint
        url = Uri.parse('$_generativeAiBaseUrl/$model:generateContent');
      } else {
        throw Exception('Either accessToken (for Vertex AI) or apiKey (for Generative AI) must be provided');
      }
      
      // Build request body with generation config for image models
      final requestBody = <String, dynamic>{
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': imageBase64,
                }
              }
            ]
          }
        ],
      };
      
      // Add generation config for image generation models (Nano Banana)
      if (model == nanoBanana || model == nanoBananaPro) {
        requestBody['generationConfig'] = {
          'responseModalities': ['TEXT', 'IMAGE'],
        };
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add Authorization header for Vertex AI API (OAuth2)
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      
      // For Generative AI API with API keys, use x-goog-api-key header (not query param)
      if (apiKey != null && accessToken == null) {
        headers['x-goog-api-key'] = apiKey;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both Vertex AI and Generative AI API response formats
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            String? textResult;
            String? imageBase64;
            
            // Check for both text and image responses
            for (var part in parts) {
              if (part['text'] != null) {
                textResult = part['text'] as String;
              }
              if (part['inlineData'] != null) {
                final inlineData = part['inlineData'] as Map<String, dynamic>;
                imageBase64 = inlineData['data'] as String?;
              }
            }
            
            // Return text if available, otherwise return image data indicator
            if (textResult != null) {
              return textResult;
            } else if (imageBase64 != null) {
              // Return image data as base64 string (prefixed for identification)
              return 'IMAGE_DATA:$imageBase64';
            }
          }
        }
        return 'No response generated';
      } else {
        final errorBody = response.body;
        String errorMessage = 'API error: ${response.statusCode}';
        
        if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage += '\n\nAuthentication failed.';
          if (apiKey != null) {
            errorMessage += '\n\nNote: Your API key might be invalid or restricted.';
            errorMessage += '\nMake sure you enabled "Generative Language API".';
          }
        }
        
        errorMessage += '\n\nResponse: $errorBody';
        
        // If 404 and using Generative AI API, suggest trying different model name
        if (response.statusCode == 404 && apiKey != null) {
          errorMessage += '\n\nTip: Try using a different model name or check available models.';
          errorMessage += '\nFor image generation, use: gemini-2.5-flash-image or gemini-3-pro-image-preview';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to generate text with image: $e');
    }
  }

  /// Chat completion with conversation history
  /// 
  /// [messages] - List of messages in format: [{'role': 'user', 'content': 'text'}, ...]
  /// [model] - The model to use
  /// [accessToken] - OAuth access token
  /// [apiKey] - API key (for testing only)
  /// 
  /// Returns the assistant's response
  static Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    String model = geminiFlash,
    String? accessToken,
    String? apiKey,
  }) async {
    try {
      Uri url;
      
      // Use Generative AI API if API key is provided
      if (apiKey != null) {
        url = Uri.parse('$_generativeAiBaseUrl/$model:generateContent?key=$apiKey');
      } else if (accessToken != null) {
        url = Uri.parse('$_vertexAiBaseUrl/$model:generateContent');
      } else {
        throw Exception('Either apiKey or accessToken must be provided');
      }
      
      final contents = messages.map((msg) => {
        'parts': [
          {'text': msg['content']}
        ],
        'role': msg['role'] == 'user' ? 'user' : 'model',
      }).toList();

      final requestBody = {
        'contents': contents,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add Authorization header for Vertex AI API (OAuth2)
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      
      // For Generative AI API with API keys, use x-goog-api-key header (not query param)
      if (apiKey != null && accessToken == null) {
        headers['x-goog-api-key'] = apiKey;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both Vertex AI and Generative AI API response formats
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'];
            return text ?? 'No response generated';
          }
        }
        return 'No response generated';
      } else {
        final errorBody = response.body;
        String errorMessage = 'API error: ${response.statusCode}';
        
        if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage += '\n\nAuthentication failed.';
          if (apiKey != null) {
            errorMessage += '\n\nNote: Your API key might be invalid or restricted.';
            errorMessage += '\nMake sure you enabled "Generative Language API".';
          }
        }
        
        errorMessage += '\n\nResponse: $errorBody';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to complete chat: $e');
    }
  }

  /// Get available models from Generative AI API
  /// 
  /// Returns list of available model names
  /// Useful for finding the correct model name (e.g., for Nano Banana Pro)
  static Future<List<Map<String, dynamic>>> getAvailableModels({
    String? apiKey,
  }) async {
    try {
      final url = apiKey != null
          ? Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey')
          : throw Exception('API key is required to list models');

      final headers = {
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['models'] as List?)
            ?.map((m) => {
                  'name': m['name'] as String?,
                  'displayName': m['displayName'] as String?,
                  'description': m['description'] as String?,
                  'supportedGenerationMethods': m['supportedGenerationMethods'] as List?,
                })
            .whereType<Map<String, dynamic>>()
            .toList() ?? [];
        return models;
      } else {
        throw Exception(
          'Failed to get models: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      throw Exception('Failed to get available models: $e');
    }
  }
}
