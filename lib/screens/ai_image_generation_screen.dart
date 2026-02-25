import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../services/openai_service.dart';
import '../utils/haptic_feedback_helper.dart';
import '../widgets/shimmer_loading.dart';
import '../constants/app_constants.dart';

class AIImageGenerationScreen extends StatefulWidget {
  final String? prompt; // Optional prompt from trend card
  
  const AIImageGenerationScreen({super.key, this.prompt});

  @override
  State<AIImageGenerationScreen> createState() => _AIImageGenerationScreenState();
}

class _AIImageGenerationScreenState extends State<AIImageGenerationScreen> {
  final ImagePicker _picker = ImagePicker();
  final OpenAIService _openAIService = OpenAIService();
  
  XFile? _selectedImage;
  String? _generatedImageUrl;
  Uint8List? _generatedImageBytes;
  bool _isGenerating = false;
  String? _error;

  // Use provided prompt or default prompt
  String get _prompt => widget.prompt ?? 
      "Transform me into a figure made entirely from layered flower petals. "
      "Use realistic petal textures, delicate edges, and natural overlaps to form "
      "facial features and silhouette while keeping identity recognizable. "
      "Soft daylight, gentle shadows, and a clean minimal background. "
      "Photoreal, high-detail, elegant";

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
          _generatedImageUrl = null;
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

  Future<void> _generateImage() async {
    if (_selectedImage == null) {
      _showImageSourceDialog();
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedImageUrl = null;
      _generatedImageBytes = null;
    });

    try {
      HapticFeedbackHelper.tap();
      
      // Transform the uploaded image using OpenAI image editing
      final imageFile = File(_selectedImage!.path);
      final imageUrl = await _openAIService.transformImage(
        imageFile: imageFile,
        prompt: _prompt,
      );

      // Download the transformed image
      final imageBytes = await _openAIService.downloadImage(imageUrl);

      if (mounted) {
        setState(() {
          _generatedImageUrl = imageUrl;
          _generatedImageBytes = imageBytes;
          _isGenerating = false;
        });
        HapticFeedbackHelper.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isGenerating = false;
        });
        HapticFeedbackHelper.heavyImpact();
      }
    }
  }

  Future<void> _downloadImage() async {
    if (_generatedImageBytes == null) return;

    try {
      HapticFeedbackHelper.tap();
      
      // Save image to photo library
      final result = await ImageGallerySaver.saveImage(
        _generatedImageBytes!,
        quality: 100,
        name: 'ai_generated_image_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image saved to photo library!',
                style: GoogleFonts.spaceGrotesk(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          HapticFeedbackHelper.mediumImpact();
        } else {
          throw Exception('Failed to save to photo library');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save image: $e',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        HapticFeedbackHelper.heavyImpact();
      }
    }
  }

  Future<void> _shareImage([BuildContext? shareContext]) async {
    if (_generatedImageBytes == null) return;

    try {
      HapticFeedbackHelper.tap();
      
      // Save image to temporary directory for sharing
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ai_generated_image_$timestamp.png';
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(_generatedImageBytes!);

      // Get share position origin for iOS (especially iPad)
      Rect? sharePositionOrigin;
      if (Platform.isIOS && shareContext != null) {
        final RenderBox? renderBox = shareContext.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final size = renderBox.size;
          final offset = renderBox.localToGlobal(Offset.zero);
          sharePositionOrigin = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
        }
      }

      // Share the image with a custom message
      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: 'image/png', name: fileName)],
        text: 'Check out my AI-generated image transformed into flower petals! 🌸✨',
        subject: 'AI Generated Image - Flower Petals Transformation',
        sharePositionOrigin: sharePositionOrigin,
      );

      // Show success feedback if share was completed
      if (result.status == ShareResultStatus.success) {
        if (mounted) {
          HapticFeedbackHelper.mediumImpact();
        }
      } else if (result.status == ShareResultStatus.dismissed) {
        // User dismissed the share sheet - no error, just cancelled
        HapticFeedbackHelper.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share image: ${e.toString().replaceAll('Exception: ', '').replaceAll('PlatformException: ', '')}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        HapticFeedbackHelper.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Generation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Text(
              'Upload or take a photo to transform yourself into a figure made from flower petals',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Selected Image Section
            if (_selectedImage != null)
              Column(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Image Picker Button
            if (_selectedImage == null)
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to upload or take a photo',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Generate Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Generate Image',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Generated Image Section
            if (_isGenerating) ...[
              const SizedBox(height: 32),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: ImageShimmer(),
                ),
              ),
            ],

            if (_generatedImageBytes != null) ...[
              const SizedBox(height: 32),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _generatedImageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloadImage,
                      icon: const Icon(Icons.download),
                      label: Text(
                        'Download',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (buttonContext) => ElevatedButton.icon(
                        onPressed: () => _shareImage(buttonContext),
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: Text(
                          'Share',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppConstants.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
