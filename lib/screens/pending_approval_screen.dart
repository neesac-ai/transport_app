import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/supabase_service.dart';
import 'auth_email_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  final String userEmail;
  final String userName;
  final String userRole;

  const PendingApprovalScreen({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: AppColors.primaryBlue,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Registration Submitted',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 50,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your registration request has been submitted successfully!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Role: $userRole',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: $userEmail',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your account is pending approval from the administrator. You will receive an email notification once approved.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const AuthEmailScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      // Check approval status
                      try {
                        final user = SupabaseService.client.auth.currentUser;
                        if (user != null) {
                          final userProfile = await SupabaseService.getUserProfile(user.id);
                          if (userProfile != null) {
                            if (userProfile.approvalStatus.name == 'approved') {
                              // User is approved, navigate to dashboard
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const AuthEmailScreen(),
                                ),
                              );
                            } else {
                              // Still pending
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your account is still pending approval. Please wait for admin approval.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error checking status: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Check Approval Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
