import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../services/video_cache_service.dart';
import '../constants/app_constants.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/floating_message.dart';
import 'main_navigation_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> with AutomaticKeepAliveClientMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;
  
  VideoPlayerController? _signInVideoController;
  VideoPlayerController? _signUpVideoController;
  VideoPlayerController? _currentVideoController;
  bool _signInVideoInitialized = false;
  bool _signUpVideoInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    final videoCacheManager = VideoCacheManager();
    
    // Sign in video
    try {
      final signInUrl = 'https://firebasestorage.googleapis.com/v0/b/alausasabi-c35ab.appspot.com/o/outfit1.mp4?alt=media&token=71a9fa4f-89e3-4d4a-8b1d-6678a98a6c9f';
      final signInFile = await videoCacheManager.getCachedVideoFile(signInUrl);
      
      _signInVideoController = VideoPlayerController.file(
        signInFile,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      _signInVideoController!.setLooping(true);
      _signInVideoController!.setVolume(0);
      await _signInVideoController!.initialize();
      if (mounted) {
        setState(() {
          _signInVideoInitialized = true;
        });
        _signInVideoController!.play();
        _currentVideoController = _signInVideoController;
      }
    } catch (e) {
      debugPrint('Error initializing sign in video: $e');
      // Fallback to network
      try {
        final signInUrl = 'https://firebasestorage.googleapis.com/v0/b/alausasabi-c35ab.appspot.com/o/outfit1.mp4?alt=media&token=71a9fa4f-89e3-4d4a-8b1d-6678a98a6c9f';
        _signInVideoController = VideoPlayerController.network(
          signInUrl,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        _signInVideoController!.setLooping(true);
        _signInVideoController!.setVolume(0);
        await _signInVideoController!.initialize();
        if (mounted) {
          setState(() {
            _signInVideoInitialized = true;
          });
          _signInVideoController!.play();
          _currentVideoController = _signInVideoController;
        }
      } catch (networkError) {
        debugPrint('Error with network fallback for sign in: $networkError');
        if (mounted) {
          setState(() {
            _signInVideoInitialized = false;
          });
        }
      }
    }
    
    // Sign up video - initialize after a delay to avoid conflicts
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      final signUpUrl = 'https://firebasestorage.googleapis.com/v0/b/alausasabi-c35ab.appspot.com/o/outfit5.mp4?alt=media&token=08ad87ed-e48f-4fe4-a2d1-3c7873d55ab6';
      final signUpFile = await videoCacheManager.getCachedVideoFile(signUpUrl);
      
      _signUpVideoController = VideoPlayerController.file(
        signUpFile,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      _signUpVideoController!.setLooping(true);
      _signUpVideoController!.setVolume(0);
      await _signUpVideoController!.initialize();
      if (mounted) {
        setState(() {
          _signUpVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing sign up video: $e');
      // Fallback to network
      try {
        final signUpUrl = 'https://firebasestorage.googleapis.com/v0/b/alausasabi-c35ab.appspot.com/o/outfit5.mp4?alt=media&token=08ad87ed-e48f-4fe4-a2d1-3c7873d55ab6';
        _signUpVideoController = VideoPlayerController.network(
          signUpUrl,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        _signUpVideoController!.setLooping(true);
        _signUpVideoController!.setVolume(0);
        await _signUpVideoController!.initialize();
        if (mounted) {
          setState(() {
            _signUpVideoInitialized = true;
          });
        }
      } catch (networkError) {
        debugPrint('Error with network fallback for sign up: $networkError');
        if (mounted) {
          setState(() {
            _signUpVideoInitialized = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signInVideoController?.dispose();
    _signUpVideoController?.dispose();
    super.dispose();
  }
  
  void _switchVideo(bool isSignUp) {
    if (isSignUp) {
      _signInVideoController?.pause();
      if (_signUpVideoInitialized && _signUpVideoController != null) {
        _signUpVideoController!.play();
        _currentVideoController = _signUpVideoController;
      }
    } else {
      _signUpVideoController?.pause();
      if (_signInVideoInitialized && _signInVideoController != null) {
        _signInVideoController!.play();
        _currentVideoController = _signInVideoController;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // Sign up
        await AuthService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Sign in
        await AuthService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        FloatingMessage.show(
          context,
          message: _getErrorMessage(e.code),
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        FloatingMessage.show(
          context,
          message: 'Error: ${e.toString()}',
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video background
          Positioned.fill(
            child: _currentVideoController != null &&
                    _currentVideoController!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _currentVideoController!.value.size.width,
                      height: _currentVideoController!.value.size.height,
                      child: VideoPlayer(_currentVideoController!),
                    ),
                  )
                : ShimmerLoading(
                    baseColor: Colors.grey.shade900,
                    highlightColor: Colors.grey.shade800,
                    child: Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.email, color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(AppConstants.primaryColor)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(AppConstants.primaryColor)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppConstants.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? ShimmerLoading(
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
                              )
                            : Text(
                                _isSignUp ? 'Sign Up' : 'Sign In',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _switchVideo(_isSignUp);
                          });
                        },
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign In'
                              : 'Don\'t have an account? Sign Up',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(AppConstants.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
