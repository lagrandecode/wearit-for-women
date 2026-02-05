import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class DancingText extends StatefulWidget {
  final String text;
  final String prefixText;
  final double fontSize;

  const DancingText({
    super.key,
    required this.text,
    this.prefixText = 'For ',
    this.fontSize = 58,
  });

  @override
  State<DancingText> createState() => _DancingTextState();
}

class _DancingTextState extends State<DancingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _dancingAnimationController;
  late Animation<double> _dancingRotationAnimation;
  late Animation<double> _dancingScaleAnimation;
  late Animation<double> _dancingOffsetAnimation;

  @override
  void initState() {
    super.initState();
    
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
  }

  @override
  void dispose() {
    _dancingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.prefixText,
          style: GoogleFonts.spaceGrotesk(
            fontSize: widget.fontSize,
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
                    widget.text,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(AppConstants.primaryColor),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
