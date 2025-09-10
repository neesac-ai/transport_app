import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  
  DriverStatus _selectedStatus = DriverStatus.active;
  DateTime? _licenseExpiry;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final driver = DriverModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        licenseExpiry: _licenseExpiry,
        status: _selectedStatus.displayName.toLowerCase().replaceAll(' ', '_'),
        address: _addressController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Save to Supabase (in development mode, this will just return the driver)
      await SupabaseService.saveDriver(driver.toJson());

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding driver: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _selectLicenseExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    
    if (date != null) {
      setState(() {
        _licenseExpiry = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Driver'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter driver name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '+91 9876543210',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'john.doe@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // License Number
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Number *',
                  hintText: 'DL123456789',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter license number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // License Expiry
              InkWell(
                onTap: _selectLicenseExpiry,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.grey500),
                      const SizedBox(width: 12),
                      Text(
                        _licenseExpiry != null
                            ? 'License Expiry: ${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}'
                            : 'Select License Expiry Date',
                        style: TextStyle(
                          color: _licenseExpiry != null ? AppColors.black : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Enter complete address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Status Selection
              const Text(
                'Status *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DriverStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: DriverStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }).toList(),
                    onChanged: (DriverStatus? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text(
                          'Add Driver',
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
}
