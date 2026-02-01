

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try{
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }catch (e){
    print("System UI failed $e");
  }
  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFFFE9ECD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFE9ECD),
          primary: const Color(0xFFFE9ECD),
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  late AnimationController _buttonAnimationController;
  late Animation<double> _button1Animation;
  late Animation<double> _button2Animation;
  late Animation<double> _button3Animation;
  
  late AnimationController _dancingAnimationController;
  late Animation<double> _dancingRotationAnimation;
  late Animation<double> _dancingScaleAnimation;
  late Animation<double> _dancingOffsetAnimation;

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
    
    // Initialize dancing animation
    _dancingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    _dancingRotationAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(
        parent: _dancingAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _dancingScaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _dancingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _dancingOffsetAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _dancingAnimationController,
        curve: Curves.bounceOut,
      ),
    );
    
    // Start animations when video is initialized
    if (_isInitialized) {
      _buttonAnimationController.forward();
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/intro22.mp4');
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
    _dancingAnimationController.dispose();
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
              child: CircularProgressIndicator(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'For ',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 58,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _dancingAnimationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _dancingRotationAnimation.value,
                            child: Transform.scale(
                              scale: _dancingScaleAnimation.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  _dancingOffsetAnimation.value,
                                ),
                                child: Text(
                                  'Women',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 58,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFE9ECD),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
                          child: _buildAnimatedButton(
                            context,
                            icon: Icons.apple,
                            label: 'Continue with Apple',
                            onPressed: () {},
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
                          child: _buildAnimatedGoogleButton(
                            context,
                            label: 'Continue with Google',
                            onPressed: () {},
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
                          child: _buildAnimatedButton(
                            context,
                            icon: Icons.email_outlined,
                            label: 'Continue with Email',
                            onPressed: () {},
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

  Widget _buildAnimatedButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return _AnimatedButtonWidget(
      icon: icon,
      label: label,
      onPressed: onPressed,
    );
  }

  Widget _buildAnimatedGoogleButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return _AnimatedGoogleButtonWidget(
      label: label,
      onPressed: onPressed,
    );
  }
}

class _AnimatedButtonWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AnimatedButtonWidget({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_AnimatedButtonWidget> createState() => _AnimatedButtonWidgetState();
}

class _AnimatedButtonWidgetState extends State<_AnimatedButtonWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE9ECD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _borderColorAnimation.value ?? Colors.transparent,
                      width: _isHovered ? 2.0 : 0.0,
                    ),
                  ),
                  elevation: _isHovered ? 4 : 0,
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return null;
                    },
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedGoogleButtonWidget extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _AnimatedGoogleButtonWidget({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_AnimatedGoogleButtonWidget> createState() =>
      _AnimatedGoogleButtonWidgetState();
}

class _AnimatedGoogleButtonWidgetState
    extends State<_AnimatedGoogleButtonWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE9ECD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _borderColorAnimation.value ?? Colors.transparent,
                      width: _isHovered ? 2.0 : 0.0,
                    ),
                  ),
                  elevation: _isHovered ? 4 : 0,
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return null;
                    },
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: const FaIcon(
                        FontAwesomeIcons.google,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


