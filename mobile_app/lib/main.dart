import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const JayBheemApp());
}

class JayBheemApp extends StatelessWidget {
  const JayBheemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jay Bheem',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}
