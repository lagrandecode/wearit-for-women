import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/vertex_ai_service.dart';
import '../utils/vertex_ai_helper.dart';
import '../constants/app_constants.dart';

/// Example screen for testing Vertex AI integration
/// 
/// ⚠️ This is for development/testing only.
/// In production, API calls should be made from Cloud Functions.
class VertexAITestScreen extends StatefulWidget {
  const VertexAITestScreen({super.key});

  @override
  State<VertexAITestScreen> createState() => _VertexAITestScreenState();
}

class _VertexAITestScreenState extends State<VertexAITestScreen> {
  final _promptController = TextEditingController();
  final _responseController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _testGenerateText() async {
    if (_promptController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a prompt';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _responseController.clear();
    });

    try {
      // Try to use API key from constants, or access token
      // ⚠️ For production, this should call Cloud Functions instead
      
      final response = await VertexAIService.generateText(
        prompt: _promptController.text,
        model: VertexAIService.geminiFlash, // Fast model
        maxTokens: 500,
        apiKey: AppConstants.vertexAiApiKey, // Will be null if not set
      );

      setState(() {
        _responseController.text = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e\n\nNote: You need to set up authentication. See VERTEX_AI_SETUP.md';
        _isLoading = false;
      });
    }
  }

  Future<void> _testOutfitRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _responseController.clear();
    });

    try {
      final response = await VertexAIHelper.generateOutfitRecommendations(
        preferences: {
          'style': 'casual',
          'season': 'spring',
          'budget': 'moderate',
          'outing_type': 'brunch',
        },
      );

      setState(() {
        _responseController.text = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e\n\nNote: You need to set up authentication. See VERTEX_AI_SETUP.md';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vertex AI Test',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vertex AI (Gemini) Test',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ For production, use Cloud Functions to call Vertex AI API',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              
              // Prompt input
              TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: 'Enter your prompt',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(AppConstants.primaryColor),
                    ),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testGenerateText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                              'Generate Text',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testOutfitRecommendations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Get Outfit Tips',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Error display
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.red.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
              
              if (_error != null) const SizedBox(height: 16),
              
              // Response display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : TextField(
                          controller: _responseController,
                          readOnly: true,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'AI response will appear here...',
                          ),
                          style: GoogleFonts.spaceGrotesk(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
