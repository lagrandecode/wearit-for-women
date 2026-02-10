import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/vertex_ai_service.dart';
import '../constants/app_constants.dart';
import '../widgets/shimmer_loading.dart';

class RateMyOutfitScreen extends StatefulWidget {
  const RateMyOutfitScreen({super.key});

  @override
  State<RateMyOutfitScreen> createState() => _RateMyOutfitScreenState();
}

class _RateMyOutfitScreenState extends State<RateMyOutfitScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  int? _outfitScore; // Percentage score (0-100)
  String? _recommendations;
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
          _outfitScore = null;
          _recommendations = null;
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

  Future<void> _rateOutfit() async {
    if (_selectedImage == null) {
      setState(() {
        _error = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _outfitScore = null;
      _recommendations = null;
    });

    try {
      // Convert image to base64
      final imageBase64 = await _imageToBase64(_selectedImage!.path);
      final mimeType = _getMimeType(_selectedImage!.path);

      // Create the prompt for outfit rating
      const prompt = '''
Analyze this outfit and provide a comprehensive rating and styling recommendations.

Please evaluate the outfit based on:
1. Color coordination and harmony
2. Fit and proportions
3. Style consistency
4. Occasion appropriateness
5. Overall aesthetic appeal
6. Accessories and finishing touches

Provide your response in the following format:
SCORE: [a number from 0-100 representing the overall outfit rating]
RECOMMENDATIONS: [detailed styling tips and suggestions for improvement, including specific recommendations for colors, fits, accessories, and styling adjustments]

Be constructive and specific in your feedback. Highlight what works well and provide actionable suggestions for improvement.
''';

      // Use Gemini for outfit analysis
      final result = await VertexAIService.generateTextWithImage(
        prompt: prompt,
        imageBase64: imageBase64,
        mimeType: mimeType,
        model: VertexAIService.geminiFlash, // Use gemini-pro for analysis
        apiKey: AppConstants.vertexAiApiKey,
      );

      // Parse the response to extract score and recommendations
      int? score;
      String? recommendations;

      // Try to extract score from response
      final scoreMatch = RegExp(r'SCORE:\s*(\d+)', caseSensitive: false).firstMatch(result);
      if (scoreMatch != null) {
        score = int.tryParse(scoreMatch.group(1) ?? '');
      }

      // Extract recommendations
      final recommendationsMatch = RegExp(r'RECOMMENDATIONS:\s*(.+?)(?:\n\n|\Z)', caseSensitive: false, dotAll: true).firstMatch(result);
      if (recommendationsMatch != null) {
        recommendations = recommendationsMatch.group(1)?.trim();
      } else {
        // If format not found, use the whole response as recommendations
        recommendations = result.replaceAll(RegExp(r'SCORE:\s*\d+\s*', caseSensitive: false), '').trim();
      }

      // If score not found, try to extract any number that might be a score
      if (score == null) {
        final numberMatch = RegExp(r'\b(\d{1,3})\b').firstMatch(result);
        if (numberMatch != null) {
          final potentialScore = int.tryParse(numberMatch.group(1) ?? '');
          if (potentialScore != null && potentialScore >= 0 && potentialScore <= 100) {
            score = potentialScore;
          }
        }
      }

      // Default score if still not found
      score ??= 75;

      setState(() {
        _outfitScore = score;
        _recommendations = recommendations ?? result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to rate outfit: $e';
        _isLoading = false;
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great!';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rate My Outfit',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
                        'Get outfit feedback',
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
                    '1. Upload your outfit photo\n2. AI analyzes your style\n3. Get percentage score and styling tips',
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (_selectedImage != null) const SizedBox(height: 24),

            // Rate button
            if (_selectedImage != null)
              ElevatedButton(
                onPressed: _isLoading ? null : _rateOutfit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShimmerLoading(
                            baseColor: Colors.white.withOpacity(0.3),
                            highlightColor: Colors.white.withOpacity(0.6),
                            child: Container(
                              height: 20,
                              width: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Analyzing...',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Rate My Outfit',
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

            // Score display
            if (_outfitScore != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Outfit Score',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: _outfitScore! / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getScoreColor(_outfitScore!),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$_outfitScore%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(_outfitScore!),
                              ),
                            ),
                            Text(
                              _getScoreLabel(_outfitScore!),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Recommendations display
            if (_recommendations != null) ...[
              const SizedBox(height: 24),

              Text(
                'Styling Recommendations',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  _recommendations!,
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
