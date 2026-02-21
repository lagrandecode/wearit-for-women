import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class GlassmorphismNavBar extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;
  final ValueChanged<int>? onTabChanged;

  const GlassmorphismNavBar({
    super.key,
    required this.currentIndex,
    required this.context,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Positioned(
      bottom: bottomPadding > 0 ? bottomPadding + 10 : 20,
      left: 20,
      right: 20,
      child: isDark
          ? LiquidGlassLayer(
              settings: const LiquidGlassSettings(
                thickness: 15,
                blur: 10,
                glassColor: Color(0x33FFFFFF),
                lightIntensity: 1.2,
              ),
              child: LiquidGlass(
                shape: LiquidRoundedSuperellipse(
                  borderRadius: 30,
                ),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _buildNavItems(context),
                  ),
                ),
              ),
            )
          : Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
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
                children: _buildNavItems(context),
              ),
            ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    return [
      _buildNavItem(
        context: context,
        icon: Icons.lightbulb_outline,
        activeIcon: Icons.lightbulb,
        label: 'Home',
        index: 0,
        onTap: () {
          HapticFeedback.selectionClick();
          if (currentIndex != 0 && onTabChanged != null) {
            onTabChanged!(0);
          }
        },
      ),
      _buildNavItem(
        context: context,
        icon: Icons.checkroom_outlined,
        activeIcon: Icons.checkroom,
        label: 'Wardrobe',
        index: 1,
        onTap: () {
          HapticFeedback.selectionClick();
          if (currentIndex != 1 && onTabChanged != null) {
            onTabChanged!(1);
          }
        },
      ),
      _buildNavItem(
        context: context,
        icon: Icons.swap_horiz,
        activeIcon: Icons.swap_horiz,
        label: 'Outfit Swap',
        index: 2,
        onTap: () {
          HapticFeedback.selectionClick();
          if (currentIndex != 2 && onTabChanged != null) {
            onTabChanged!(2);
          }
        },
      ),
      _buildNavItem(
        context: context,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings',
        index: 3,
        onTap: () {
          HapticFeedback.selectionClick();
          if (currentIndex != 3 && onTabChanged != null) {
            onTabChanged!(3);
          }
        },
      ),
    ];
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isActive = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark 
                  ? Colors.white.withOpacity(0.3)
                  : const Color(AppConstants.primaryColor).withOpacity(0.2))
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
                  : (isDark 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade700),
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
                    : (isDark 
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
