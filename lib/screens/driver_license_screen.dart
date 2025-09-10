import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'pending_approval_screen.dart';

class DriverLicenseScreen extends StatefulWidget {
  final UserModel user;
  
  const DriverLicenseScreen({
    super.key,
    required this.user,
  });

  @override
  State<DriverLicenseScreen> createState() => _DriverLicenseScreenState();
}

class _DriverLicenseScreenState extends State<DriverLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  DateTime? _selectedExpiryDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
        _licenseExpiryController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  String? _validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    if (value.length < 10) {
      return 'License number must be at least 10 characters';
    }
    if (value.length > 20) {
      return 'License number must not exceed 20 characters';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'License expiry date is required';
    }
    if (_selectedExpiryDate == null) {
      return 'Please select a valid expiry date';
    }
    if (_selectedExpiryDate!.isBefore(DateTime.now())) {
      return 'License has already expired';
    }
    return null;
  }

  Future<void> _saveDriverLicense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save driver license to database
      await SupabaseService.saveDriverLicense(
        widget.user.id,
        _licenseNumberController.text.trim(),
        _selectedExpiryDate!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver license saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to pending approval screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PendingApprovalScreen(
              userEmail: widget.user.email,
              userName: widget.user.name,
              userRole: widget.user.role?.displayName ?? 'Driver',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving license: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver License Details'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBlue, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.drive_eta,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Driver License Information',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete your driver profile',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please provide your driving license details to complete your driver registration.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'License Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // License Number
                        TextFormField(
                          controller: _licenseNumberController,
                          decoration: InputDecoration(
                            labelText: 'License Number',
                            hintText: 'Enter your driving license number',
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: _validateLicenseNumber,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // License Expiry Date
                        TextFormField(
                          controller: _licenseExpiryController,
                          decoration: InputDecoration(
                            labelText: 'License Expiry Date',
                            hintText: 'Select expiry date',
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: _selectExpiryDate,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          readOnly: true,
                          validator: _validateExpiryDate,
                          onTap: _selectExpiryDate,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveDriverLicense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save License Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // User Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'D',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Role: ${widget.user.role?.displayName ?? 'Driver'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
