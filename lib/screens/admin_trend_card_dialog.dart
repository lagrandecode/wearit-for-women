import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trend_card.dart';
import '../services/trend_card_service.dart';
import '../constants/app_constants.dart';
import '../utils/haptic_feedback_helper.dart';

class AdminTrendCardDialog extends StatefulWidget {
  final TrendCard? card; // If provided, we're editing; otherwise, creating

  const AdminTrendCardDialog({super.key, this.card});

  @override
  State<AdminTrendCardDialog> createState() => _AdminTrendCardDialogState();
}

class _AdminTrendCardDialogState extends State<AdminTrendCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mediaUrlController = TextEditingController();
  final _promptController = TextEditingController();
  final _trendCardService = TrendCardService();
  String _selectedMediaType = 'video';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _mediaUrlController.text = widget.card!.mediaUrl;
      _promptController.text = widget.card!.prompt;
      _selectedMediaType = widget.card!.mediaType;
    }
  }

  @override
  void dispose() {
    _mediaUrlController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedbackHelper.tap();

    try {
      if (widget.card != null) {
        // Update existing card
        final updatedCard = widget.card!.copyWith(
          mediaUrl: _mediaUrlController.text.trim(),
          mediaType: _selectedMediaType,
          prompt: _promptController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _trendCardService.updateTrendCard(updatedCard);
      } else {
        // Create new card
        await _trendCardService.addTrendCard(
          mediaUrl: _mediaUrlController.text.trim(),
          mediaType: _selectedMediaType,
          prompt: _promptController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        HapticFeedbackHelper.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        HapticFeedbackHelper.heavyImpact();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.card == null ? 'Add Trend Card' : 'Edit Trend Card',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Media Type Selection
                Text(
                  'Media Type',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Video'),
                        value: 'video',
                        groupValue: _selectedMediaType,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() => _selectedMediaType = value!);
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Image'),
                        value: 'image',
                        groupValue: _selectedMediaType,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() => _selectedMediaType = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Media URL
                TextFormField(
                  controller: _mediaUrlController,
                  decoration: InputDecoration(
                    labelText: 'Media URL',
                    hintText: 'Enter image or video URL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a media URL';
                    }
                    if (!Uri.tryParse(value.trim())!.hasScheme) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Prompt
                TextFormField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    labelText: 'AI Generation Prompt',
                    hintText: 'Enter the prompt for image generation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a prompt';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.spaceGrotesk(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCard,
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
                                widget.card == null ? 'Add Card' : 'Update Card',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
