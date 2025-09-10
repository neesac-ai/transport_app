import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';
import 'profile_setup_screen.dart';
import 'role_dashboard_screen.dart';
import 'pending_approval_screen.dart';

class AuthEmailScreen extends StatefulWidget {
  const AuthEmailScreen({super.key});

  @override
  State<AuthEmailScreen> createState() => _AuthEmailScreenState();
}

class _AuthEmailScreenState extends State<AuthEmailScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter email');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseService.signInWithEmail(
        _emailController.text.trim(), 
        _passwordController.text
      );
      
      if (response != null && response.user != null) {
        final user = response.user!;
        
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', user.id);
        await prefs.setString('userEmail', user.email ?? '');
        
        setState(() {
          _isLoading = false;
        });

        // Check if user has completed profile
        final userProfile = await SupabaseService.getUserProfile(user.id);
        print('=== AUTH DEBUG ===');
        print('User profile: $userProfile');
        print('Approval status: ${userProfile?.approvalStatus.name}');
        print('Role: ${userProfile?.role?.name}');
        
        if (userProfile != null && userProfile.role != null) {
          // Check approval status
          if (userProfile.approvalStatus.name == 'approved') {
            // User is approved, navigate to dashboard
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => RoleDashboardScreen(user: userProfile),
              ),
            );
          } else if (userProfile.approvalStatus.name == 'pending') {
            // User is pending approval
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PendingApprovalScreen(
                  userEmail: userProfile.email,
                  userName: userProfile.name,
                  userRole: userProfile.role?.displayName ?? 'Unknown',
                ),
              ),
            );
          } else if (userProfile.approvalStatus.name == 'rejected') {
            // User was rejected
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your registration was rejected. Reason: ${userProfile.rejectionReason ?? 'No reason provided'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            // Sign out the user
            await SupabaseService.signOut();
          }
        } else {
          // User needs to complete profile
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(
                phoneNumber: userProfile?.phoneNumber ?? '',
                email: user.email,
              ),
            ),
          );
        }
      } else {
        throw Exception('Authentication failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Authentication failed: ${e.toString()}');
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter email');
      return;
    }
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showError('Please enter password and confirm password');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (response != null && response.user != null) {
        final user = response.user!;
        
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', user.id);
        await prefs.setString('userEmail', user.email ?? '');
        
        setState(() {
          _isLoading = false;
        });

        // Navigate to profile setup for additional details
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              phoneNumber: '',
              email: user.email,
            ),
          ),
        );
      } else {
        throw Exception('Signup failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Signup failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('RV Fleet Login'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Title
            Center(
              child: Column(
                children: [
                  const Text(
                    'Welcome to RV Fleet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isSignUp ? 'Create your account' : 'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'your.email@example.com',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Password field (only for signup)
            if (_isSignUp) ...[
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                  : ElevatedButton(
                      onPressed: _isSignUp ? _signUp : _signIn,
                      child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                    ),
            ),
            const SizedBox(height: 20),

            // Toggle between Sign In and Sign Up
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    // Clear form when switching
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                  });
                },
                child: Text(
                  _isSignUp 
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}