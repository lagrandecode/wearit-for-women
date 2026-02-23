import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'outfit_swap_screen.dart';
import 'settings_screen.dart';
import '../widgets/glassmorphism_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const WardrobeScreen(),
    const OutfitSwapScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          GlassmorphismNavBar(
            currentIndex: _currentIndex,
            onTabChanged: _onTabTapped,
            context: context,
          ),
        ],
      ),
    );
  }
}
