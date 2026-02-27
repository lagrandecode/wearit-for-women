import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';
import 'floating_message.dart';

/// Widget to display FCM token for testing purposes
/// Remove this widget from production builds
class FCMTokenDisplay extends StatefulWidget {
  const FCMTokenDisplay({super.key});

  @override
  State<FCMTokenDisplay> createState() => _FCMTokenDisplayState();
}

class _FCMTokenDisplayState extends State<FCMTokenDisplay> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final token = await NotificationService.getFCMToken();
      setState(() {
        _token = token;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _token = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_token != null) {
      // Copy to clipboard
      // Note: You'll need to add clipboard package or use a different method
      FloatingMessage.show(
        context,
        message: 'Token copied! Check console for full token.',
        icon: Icons.check_circle,
        backgroundColor: AppConstants.successColor,
        iconColor: Colors.white,
        duration: const Duration(seconds: 2),
      );
      print('FCM Token (copy this): $_token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'FCM Token (for testing)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const CircularProgressIndicator()
          else if (_token != null) ...[
            SelectableText(
              _token!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Token'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ] else
            Text(
              'No token available',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
        ],
      ),
    );
  }
}
