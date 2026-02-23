import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../services/auth_service.dart';
import '../services/video_cache_service.dart';
import '../utils/haptic_feedback_helper.dart';
import '../constants/app_constants.dart';
import 'login_screen.dart';
import 'outfit_swap_screen.dart';
import 'planner_screen.dart';
import 'rate_my_outfit_screen.dart';
import 'wardrobe_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;
  bool _hasShownConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _checkAndShowConfetti();
  }

  Future<void> _checkAndShowConfetti() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return; // User not authenticated, skip confetti
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userDocRef = firestore.collection('users').doc(user.uid);
      
      // Check if user has seen confetti
      final userDoc = await userDocRef.get();
      final hasSeenConfetti = userDoc.exists && 
          (userDoc.data()?['hasSeenWelcomeConfetti'] ?? false);
      
      if (!hasSeenConfetti) {
        // Wait a bit for the screen to render
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _confettiController.play();
          setState(() {
            _hasShownConfetti = true;
          });
          
          // Mark that confetti has been shown in Firestore
          await userDocRef.set({
            'hasSeenWelcomeConfetti': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error checking confetti status: $e');
      // If there's an error, don't show confetti to avoid showing it multiple times
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'user';
    
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    
    return '$greeting, $userName!';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
          // Logo and Notification Header
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 5.0, 24.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/wearit.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.bell),
                  onPressed: () {
                    // Notification action - to be implemented later
                  },
                ),
              ],
            ),
          ),
          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Text(
                    _getTimeBasedGreeting(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // AI Stylist Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Stylist',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AI Stylist Cards
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Make an outfit card (Outfit Swap)
                        VideoStylistCard(
                          videoUrl: 'https://firebasestorage.googleapis.com/v0/b/alausasabi-c35ab.appspot.com/o/outfit3.mp4?alt=media&token=5460c71f-6eaa-435a-9cd2-41e950d36e5c',
                          title: 'Make an outfit',
                          subtitle: 'For any date, occasion and style',
                          icon: Icons.swap_horiz,
                          onTap: () {
                            HapticFeedbackHelper.tap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OutfitSwapScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // Rate my outfit card
                        VideoStylistCard(
                          videoUrl: 'https://firebasestorage.googleapis.com/v0/b/alausasabi-c35ab.appspot.com/o/outfit4.mp4?alt=media&token=bd316d4b-b900-44b6-9359-134e3e58d0aa',
                          title: 'Rate my outfit',
                          subtitle: 'Suggest styling tips',
                          icon: Icons.star_rate,
                          onTap: () {
                            HapticFeedbackHelper.tap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RateMyOutfitScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Shortcuts Section
                  Text(
                    'Shortcuts',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shortcuts Horizontal ListView
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildShortcutButton(
                          context,
                          icon: Icons.calendar_today,
                          label: 'Planner',
                          onTap: () {
                            HapticFeedbackHelper.tap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlannerScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildShortcutButton(
                          context,
                          icon: Icons.swap_horiz,
                          label: 'Outfit Swap',
                          onTap: () {
                            HapticFeedbackHelper.tap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OutfitSwapScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildShortcutButton(
                          context,
                          icon: Icons.star_rate,
                          label: 'Rate Outfit',
                          onTap: () {
                            HapticFeedbackHelper.tap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RateMyOutfitScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildShortcutButton(
                          context,
                          icon: Icons.checkroom,
                          label: 'My Wardrobe',
                          onTap: () {
                            HapticFeedbackHelper.tap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WardrobeScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
            ],
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Downward direction (90 degrees)
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                Color(0xFF9C27B0), // Purple
                Color(0xFF968200), // Teal
                Color(0xFFE91E63), // Pink
                Color(0xFFFFD500), // Emerald green
                Color(0xFF0047AB), // Cobalt blue
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylistCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern or image could go here
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Icon in top right
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedbackHelper.tap();
        onTap();
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(AppConstants.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Video-based stylist card widget
class VideoStylistCard extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const VideoStylistCard({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<VideoStylistCard> createState() => _VideoStylistCardState();
}

class _VideoStylistCardState extends State<VideoStylistCard> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final videoCacheManager = VideoCacheManager();
      
      // Get cached video file (downloads if not cached)
      final videoFile = await videoCacheManager.getCachedVideoFile(widget.videoUrl);
      
      // Use file controller with cached video
      _controller = VideoPlayerController.file(
        videoFile,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      _controller!.setLooping(true);
      _controller!.setVolume(0);
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        _controller!.play();
      }
    } catch (e) {
      debugPrint('Error initializing video for ${widget.title}: $e');
      // Fallback to network if caching fails
      try {
        _controller = VideoPlayerController.network(
          widget.videoUrl,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        _controller!.setLooping(true);
        _controller!.setVolume(0);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
          _controller!.play();
        }
      } catch (networkError) {
        debugPrint('Error with network fallback: $networkError');
        if (mounted) {
          setState(() {
            _isInitialized = false;
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return GestureDetector(
      onTap: () {
        HapticFeedbackHelper.tap();
        widget.onTap();
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Video background
              Positioned.fill(
                child: _isInitialized && _controller != null &&
                        _controller!.value.isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : Container(
                        color: Colors.black,
                      ),
              ),
              // Dark overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Icon in top right
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 24,
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
