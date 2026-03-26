import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const HeySnowApp());
}

class HeySnowApp extends StatelessWidget {
  const HeySnowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hey Snow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}