import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'auth_email_screen.dart';
import 'role_dashboard_screen.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Start animation
    _animationController.forward();

    // Check authentication status after animation
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final profileCompleted = prefs.getBool('profileCompleted') ?? false;
      
      if (isLoggedIn && profileCompleted) {
        // User is logged in and profile is completed, navigate to role dashboard
        final userDataString = prefs.getString('userData');
        if (userDataString != null) {
          try {
            final userData = jsonDecode(userDataString);
            final user = UserModel.fromJson(userData);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => RoleDashboardScreen(user: user),
              ),
            );
            return;
          } catch (e) {
            // If user data is corrupted, go to auth
          }
        }
      }
      
      // User is not logged in or profile not completed, navigate to auth
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthEmailScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.local_shipping,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // App Title
              const Text(
                'RV Truck Fleet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              
              // Subtitle
              const Text(
                'Management System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 50),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
