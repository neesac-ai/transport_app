import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';
import 'role_dashboard_screen.dart';
import 'pending_approval_screen.dart';
import 'driver_license_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final String? email;

  const ProfileSetupScreen({
    super.key,
    required this.phoneNumber,
    this.email,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  UserRole? _selectedRole;
  bool _isLoading = false;
  bool _adminExists = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate email if provided
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
    // Pre-populate phone if provided
    if (widget.phoneNumber.isNotEmpty) {
      _phoneController.text = widget.phoneNumber;
    }
    // Check if admin already exists
    _checkAdminExists();
  }

  Future<void> _checkAdminExists() async {
    try {
      print('=== CHECKING ADMIN EXISTS ===');
      // Check if there's already an approved admin
      final response = await SupabaseService.client
          .from('user_profiles')
          .select('id')
          .eq('role', 'admin')
          .eq('approval_status', 'approved')
          .maybeSingle();
      
      print('Admin check response: $response');
      print('Admin exists: ${response != null}');
      
      setState(() {
        _adminExists = response != null;
      });
    } catch (e) {
      print('Error checking admin existence: $e');
      setState(() {
        _adminExists = false; // Default to false on error
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    print('=== PROFILE SAVE STARTED ===');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    
    // Check if role is selected
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Check if trying to create admin when one already exists
    if (_selectedRole == UserRole.admin && _adminExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only one admin account is allowed. An admin already exists.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    print('Form validation passed');

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID from storage
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null) {
        throw Exception('User ID not found. Please sign in again.');
      }
      
      print('Saving profile for user ID: $userId');
      
      // Create user model
      final user = UserModel(
        id: userId,
        username: null, // No username for email-only authentication
        phoneNumber: _phoneController.text.trim(), // Use phone from form
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        role: _selectedRole!, // Role is guaranteed to be non-null due to validation above
        createdAt: DateTime.now(),
      );

      print('User model created: ${user.toJson()}');
      print('About to call SupabaseService.saveUserProfile...');

      // Save to Supabase
      final savedUser = await SupabaseService.saveUserProfile(user);
      
      print('Profile saved successfully: ${savedUser.toJson()}');
      print('=== PROFILE SAVE COMPLETED ===');
      
      // Save to local storage as backup
      await prefs.setString('userData', jsonEncode(savedUser.toJson()));
      await prefs.setBool('profileCompleted', true);

      setState(() {
        _isLoading = false;
      });

      // Navigate based on role and approval status
      if (savedUser.role == UserRole.admin) {
        // Admin users are auto-approved, go to dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RoleDashboardScreen(user: savedUser),
          ),
        );
      } else if (savedUser.role == UserRole.driver) {
        // Driver users need to provide license details first
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DriverLicenseScreen(user: savedUser),
          ),
        );
      } else {
        // Other non-admin users need approval, show pending screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PendingApprovalScreen(
              userEmail: savedUser.email,
              userName: savedUser.name,
              userRole: savedUser.role?.displayName ?? 'Unknown',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Error in _saveProfile: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 48,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome to RV Fleet Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Phone number field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '+91 9876543210',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Address field
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Enter your complete address',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Role selection
              const Text(
                'Select Your Role *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              ...UserRole.values.map((role) => _buildRoleCard(role)),
              const SizedBox(height: 30),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    final isSelected = _selectedRole == role;
    final isAdminDisabled = role == UserRole.admin && _adminExists;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isAdminDisabled ? null : () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : (isAdminDisabled ? Colors.grey[200]! : Colors.grey[300]!),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.blue[50] : (isAdminDisabled ? Colors.grey[100] : Colors.white),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: 2,
                  ),
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue[700] : (isAdminDisabled ? Colors.grey[400] : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdminDisabled ? 'Admin account already exists' : role.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdminDisabled ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
