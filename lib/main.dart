import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_email_screen.dart';
import 'services/supabase_service.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const RVFleetApp());
}

class RVFleetApp extends StatelessWidget {
  const RVFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RV Truck Fleet Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
                   routes: {
               '/auth': (context) => const AuthEmailScreen(),
               '/dashboard': (context) => const SplashScreen(), // Will be updated with proper dashboard
             },
    );
  }
}
