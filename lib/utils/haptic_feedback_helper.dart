import 'package:flutter/services.dart';

class HapticFeedbackHelper {
  /// Light haptic feedback for selection/tap actions
  static void lightImpact() {
    HapticFeedback.selectionClick();
  }

  /// Medium haptic feedback for button presses
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback for important actions
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Light impact for taps
  static void tap() {
    HapticFeedback.selectionClick();
  }
}
