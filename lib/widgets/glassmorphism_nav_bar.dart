import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../screens/home_screen.dart';
import '../screens/wardrobe_screen.dart';
import '../screens/outfit_swap_screen.dart';
import '../screens/settings_screen.dart';

class GlassmorphismNavBar extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;

  const GlassmorphismNavBar({
    super.key,
    required this.currentIndex,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottomPadding > 0 ? bottomPadding + 10 : 20,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.lightbulb_outline,
                  activeIcon: Icons.lightbulb,
                  label: 'Home',
                  index: 0,
                  onTap: () {
                    if (currentIndex != 0) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                _buildNavItem(
                  icon: Icons.checkroom_outlined,
                  activeIcon: Icons.checkroom,
                  label: 'Wardrobe',
                  index: 1,
                  onTap: () {
                    if (currentIndex != 1) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WardrobeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                _buildNavItem(
                  icon: Icons.swap_horiz,
                  activeIcon: Icons.swap_horiz,
                  label: 'Outfit Swap',
                  index: 2,
                  onTap: () {
                    if (currentIndex != 2) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OutfitSwapScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  index: 3,
                  onTap: () {
                    if (currentIndex != 3) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? const Color(AppConstants.primaryColor)
                  : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? const Color(AppConstants.primaryColor)
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
