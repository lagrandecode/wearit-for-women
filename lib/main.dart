import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/firebase_service.dart';
import 'constants/app_constants.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (e) {
    print("System UI failed $e");
  }
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(AppConstants.primaryColor),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColor),
          primary: const Color(AppConstants.primaryColor),
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
