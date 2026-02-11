import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_google_button.dart';
import '../widgets/dancing_text.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/floating_message.dart';
import 'email_auth_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  late AnimationController _buttonAnimationController;
  late Animation<double> _button1Animation;
  late Animation<double> _button2Animation;
  late Animation<double> _button3Animation;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    
    // Initialize button animations
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _button1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    
    _button2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _button3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Start animations when video is initialized
    if (_isInitialized) {
      _buttonAnimationController.forward();
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(AppConstants.videoAssetPath);
    await _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    setState(() {
      _isInitialized = true;
    });
    // Start button animations after video is ready
    _buttonAnimationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video background
          if (_isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(
              child: CardShimmer(width: double.infinity, height: double.infinity),
            ),
          // Content overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Title
                  Text(
                    'Wearit',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 58,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Subtitle with primary color and dancing animation
                  const DancingText(
                    text: 'Women',
                    prefixText: 'For ',
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Log in to your account or create a new account for free.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  // Buttons with animations
                  AnimatedBuilder(
                    animation: _button1Animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _button1Animation.value)),
                        child: Opacity(
                          opacity: _button1Animation.value,
                          child: AnimatedButtonWidget(
                            icon: Icons.apple,
                            label: 'Continue with Apple',
                            onPressed: () => _signInWithApple(context),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _button2Animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _button2Animation.value)),
                        child: Opacity(
                          opacity: _button2Animation.value,
                          child: AnimatedGoogleButtonWidget(
                            label: 'Continue with Google',
                            onPressed: () => _signInWithGoogle(context),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _button3Animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _button3Animation.value)),
                        child: Opacity(
                          opacity: _button3Animation.value,
                          child: AnimatedButtonWidget(
                            icon: Icons.email_outlined,
                            label: 'Continue with Email',
                            onPressed: () => _signInWithEmail(context),
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Authentication methods
  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final userCredential = await AuthService.signInWithApple(context);
      if (userCredential != null && userCredential.user != null) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        FloatingMessage.show(
          context,
          message: 'Apple Sign-In failed: ${e.toString()}',
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
        );
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final userCredential = await AuthService.signInWithGoogle(context);
      if (userCredential != null && userCredential.user != null) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        FloatingMessage.show(
          context,
          message: 'Google Sign-In failed: ${e.toString()}',
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _signInWithEmail(BuildContext context) async {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EmailAuthScreen()),
      );
    }
  }
}
