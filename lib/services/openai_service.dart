import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/secrets.dart';

/// Service for interacting with OpenAI API for image generation
class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey = Secrets.openAiApiKey;

  /// Convert image file to base64 string
  Future<String> imageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  /// Transform an uploaded image using a text prompt (Real Image-to-Image Editing)
  /// Uses gpt-image-1 model to edit the actual image pixels, preserving identity
  /// 
  /// [imageFile] - The uploaded image file to transform
  /// [prompt] - The transformation prompt
  /// 
  /// Returns the base64 data URL of the generated/transformed image
  Future<String> transformImage({
    required File imageFile,
    required String prompt,
  }) async {
    try {
      // Convert image to base64 (raw, no data URL prefix)
      final base64Image = await imageToBase64(imageFile);

      // Enhance prompt to preserve identity
      final enhancedPrompt =
          '$prompt. Preserve exact facial structure, expression, pose, and proportions. '
          'Only transform surface material into layered flower petals. '
          'Do not change camera angle or body position.';

      // Send image and prompt together for real image editing
      // Use multipart/form-data format for gpt-image-1
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/images/edits'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $_apiKey';

      // Detect image MIME type from file extension
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      String mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default to JPEG
      }
      final contentType = MediaType.parse(mimeType);

      // Add image file - use 'image[]' format for multipart (matches curl example)
      request.files.add(
        await http.MultipartFile.fromPath(
          'image[]', // Use 'image[]' format as shown in documentation curl example
          imageFile.path,
          contentType: contentType, // Set correct MIME type
        ),
      );

      // Add other parameters
      request.fields['model'] = 'gpt-image-1';
      request.fields['prompt'] = enhancedPrompt;
      request.fields['size'] = '1024x1024';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return 'data:image/png;base64,${data['data'][0]['b64_json']}';
      } else {
        throw Exception(data['error']?['message'] ?? 'Image edit failed');
      }
    } catch (e) {
      throw Exception('Error transforming image: $e');
    }
  }

  /// Generate an image from a text prompt using DALL-E (Text-to-Image)
  /// 
  /// [prompt] - The text description for image generation
  /// [size] - Image size: "256x256", "512x512", or "1024x1024" (default: "1024x1024")
  /// [quality] - Image quality: "standard" or "hd" (default: "standard")
  /// [n] - Number of images to generate (default: 1, max: 10)
  /// 
  /// Returns the URL of the generated image
  Future<String> generateImage({
    required String prompt,
    String size = '1024x1024',
    String quality = 'standard',
    int n = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': n,
          'size': size,
          'quality': quality,
          'response_format': 'url',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0]['url'];
        } else {
          throw Exception('No image URL in response');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to generate image');
      }
    } catch (e) {
      throw Exception('Error generating image: $e');
    }
  }

  /// Download image from URL or decode from base64 data URL and return as bytes
  Future<Uint8List> downloadImage(String imageUrl) async {
    try {
      // Check if it's a data URL (base64)
      if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',')[1];
        return base64Decode(base64String);
      }
      
      // Otherwise, download from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading image: $e');
    }
  }
}
