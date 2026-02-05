import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/vertex_ai_service.dart';
import '../constants/app_constants.dart';

class OutfitSwapScreen extends StatefulWidget {
  const OutfitSwapScreen({super.key});

  @override
  State<OutfitSwapScreen> createState() => _OutfitSwapScreenState();
}

class _OutfitSwapScreenState extends State<OutfitSwapScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _generatedResult;
  Uint8List? _generatedImageBytes; // Store generated image bytes
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _generatedResult = null;
          _generatedImageBytes = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _imageToBase64(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    return base64Encode(bytes);
  }

  String _getMimeType(String imagePath) {
    final extension = imagePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _generateOutfitSwap() async {
    if (_selectedImage == null) {
      setState(() {
        _error = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _generatedResult = null;
      _generatedImageBytes = null;
    });

    try {
      // Convert image to base64
      final imageBase64 = await _imageToBase64(_selectedImage!.path);
      final mimeType = _getMimeType(_selectedImage!.path);

      // Create the prompt for outfit swap
      const prompt = '''
Swap the person's outfit for one that suits them aesthetically. Choose clothing that complements their face, hair, proportions, and overall vibe. Keep the pose, expression, lighting, and identity unchanged. Ensure the new outfit feels natural, flattering, and well-styled.

Analyze the image and provide:
1. Detailed description of the current outfit
2. Analysis of the person's features (face shape, hair, body proportions, skin tone)
3. Recommended outfit swap with specific clothing items
4. Color palette suggestions that complement their features
5. Styling tips to make the new outfit look natural and flattering

Be specific about:
- Clothing types (e.g., "fitted blazer", "flowy midi dress", "tailored trousers")
- Colors that work with their skin tone and hair
- Fit and proportions that flatter their body type
- Accessories that complete the look
- Overall style direction (e.g., "elegant casual", "sophisticated professional", "effortless chic")
''';

      // Call Nano Banana Pro (gemini-3-pro-image-preview) for image editing
      // This model is designed for professional image generation and editing
      final result = await VertexAIService.generateTextWithImage(
        prompt: prompt,
        imageBase64: imageBase64,
        mimeType: mimeType,
        model: VertexAIService.nanoBananaPro, // gemini-3-pro-image-preview (Nano Banana Pro)
        apiKey: AppConstants.vertexAiApiKey, // API key for Generative AI API
      );

      // Check if result contains image data
      if (result.startsWith('IMAGE_DATA:')) {
        // Extract base64 image data
        final imageBase64 = result.substring(11); // Remove 'IMAGE_DATA:' prefix
        final imageBytes = base64Decode(imageBase64);
        
        setState(() {
          _generatedImageBytes = imageBytes;
          _generatedResult = 'Image generated successfully!';
          _isLoading = false;
        });
      } else {
        // Regular text response
        setState(() {
          _generatedResult = result;
          _generatedImageBytes = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to generate outfit swap: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Swap'),
        backgroundColor: const Color(AppConstants.primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Upload or take a photo\n2. AI analyzes your features\n3. Get personalized outfit recommendations',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image selection button
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(
                _selectedImage == null
                    ? 'Select or Take Photo'
                    : 'Change Photo',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected image preview
            if (_selectedImage != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),

            if (_selectedImage != null) const SizedBox(height: 24),

            // Generate button
            if (_selectedImage != null)
              ElevatedButton(
                onPressed: _isLoading ? null : _generateOutfitSwap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Generate Outfit Swap',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

            // Error display
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.red.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Result display
            if (_generatedResult != null || _generatedImageBytes != null) ...[
              const SizedBox(height: 24),
              Text(
                'Outfit Recommendations',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Display generated image if available
              if (_generatedImageBytes != null) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _generatedImageBytes!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Display text result if available
              if (_generatedResult != null && _generatedImageBytes == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    _generatedResult!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
