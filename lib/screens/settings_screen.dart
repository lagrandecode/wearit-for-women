import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../widgets/glassmorphism_nav_bar.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100, // Space for navigation bar
            ),
            children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(AppConstants.primaryColor),
                      child: Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user?.displayName ?? 'User',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      user?.email ?? '',
                      style: GoogleFonts.spaceGrotesk(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Settings Options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(
                    'Notifications',
                    style: GoogleFonts.spaceGrotesk(),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(
                    'Appearance',
                    style: GoogleFonts.spaceGrotesk(),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to appearance settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(
                    'Privacy',
                    style: GoogleFonts.spaceGrotesk(),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to privacy settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(
                    'Help & Support',
                    style: GoogleFonts.spaceGrotesk(),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Sign Out Button
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Sign Out',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.spaceGrotesk(),
                    ),
                    content: Text(
                      'Are you sure you want to sign out?',
                      style: GoogleFonts.spaceGrotesk(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel', style: GoogleFonts.spaceGrotesk()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ),
            ],
          ),
          GlassmorphismNavBar(
            currentIndex: 3,
            context: context,
          ),
        ],
      ),
    );
  }
}
