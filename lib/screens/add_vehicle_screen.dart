import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _rcController = TextEditingController();
  final _permitController = TextEditingController();
  final _insuranceController = TextEditingController();
  
  VehicleType _selectedType = VehicleType.truck;
  VehicleStatus _selectedStatus = VehicleStatus.active;
  String _capacity = '';
  DateTime? _insuranceExpiry;
  bool _isLoading = false;

  @override
  void dispose() {
    _registrationController.dispose();
    _rcController.dispose();
    _permitController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicle = VehicleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        registrationNumber: _registrationController.text.trim(),
        vehicleType: _selectedType.displayName,
        capacity: _capacity,
        status: _selectedStatus.displayName.toLowerCase(),
        rcNumber: _rcController.text.trim().isEmpty ? null : _rcController.text.trim(),
        permitNumber: _permitController.text.trim().isEmpty ? null : _permitController.text.trim(),
        insuranceNumber: _insuranceController.text.trim().isEmpty ? null : _insuranceController.text.trim(),
        insuranceExpiry: _insuranceExpiry,
        createdAt: DateTime.now(),
      );

      // Save to Supabase (in development mode, this will just return the vehicle)
      await SupabaseService.saveVehicle(vehicle.toJsonForDatabase());

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle added successfully!'),
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
          content: Text('Error adding vehicle: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _selectInsuranceExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _insuranceExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    
    if (date != null) {
      setState(() {
        _insuranceExpiry = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
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
              // Vehicle Type Selection
              const Text(
                'Vehicle Type *',
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
                  child: DropdownButton<VehicleType>(
                    value: _selectedType,
                    isExpanded: true,
                    items: VehicleType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (VehicleType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Registration Number
              TextFormField(
                controller: _registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number *',
                  hintText: 'KA01AB1234',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter registration number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Capacity
              TextFormField(
                onChanged: (value) => _capacity = value,
                decoration: const InputDecoration(
                  labelText: 'Capacity *',
                  hintText: '10 tons',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle capacity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // RC Number
              TextFormField(
                controller: _rcController,
                decoration: const InputDecoration(
                  labelText: 'RC Number',
                  hintText: 'RC123456789',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 20),

              // Permit Number
              TextFormField(
                controller: _permitController,
                decoration: const InputDecoration(
                  labelText: 'Permit Number',
                  hintText: 'PERMIT123456',
                  prefixIcon: Icon(Icons.assignment),
                ),
              ),
              const SizedBox(height: 20),

              // Insurance Number
              TextFormField(
                controller: _insuranceController,
                decoration: const InputDecoration(
                  labelText: 'Insurance Number',
                  hintText: 'INS123456789',
                  prefixIcon: Icon(Icons.security),
                ),
              ),
              const SizedBox(height: 20),

              // Insurance Expiry
              InkWell(
                onTap: _selectInsuranceExpiry,
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
                        _insuranceExpiry != null
                            ? 'Insurance Expiry: ${_insuranceExpiry!.day}/${_insuranceExpiry!.month}/${_insuranceExpiry!.year}'
                            : 'Select Insurance Expiry Date',
                        style: TextStyle(
                          color: _insuranceExpiry != null ? AppColors.black : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  child: DropdownButton<VehicleStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: VehicleStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }).toList(),
                    onChanged: (VehicleStatus? newValue) {
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
                  onPressed: _isLoading ? null : _saveVehicle,
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
                          'Add Vehicle',
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
