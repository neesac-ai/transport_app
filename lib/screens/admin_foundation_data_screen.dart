import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/supabase_service.dart';

class AdminFoundationDataScreen extends StatefulWidget {
  const AdminFoundationDataScreen({super.key});

  @override
  State<AdminFoundationDataScreen> createState() => _AdminFoundationDataScreenState();
}

class _AdminFoundationDataScreenState extends State<AdminFoundationDataScreen> {
  bool _isLoading = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Foundation Data'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_applications,
                    color: AppColors.primaryBlue,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foundation Data Setup',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set up initial data for your fleet management system',
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
            ),
            
            const SizedBox(height: 24),
            
            // Status
            if (_status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('Error') ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status.contains('Error') ? Colors.red[200]! : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('Error') ? Icons.error : Icons.check_circle,
                      color: _status.contains('Error') ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('Error') ? Colors.red[700] : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Setup Options
            const Text(
              'Setup Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sample Vehicles
            _buildSetupCard(
              icon: Icons.local_shipping,
              title: 'Sample Vehicles',
              description: 'Add sample vehicles to your fleet',
              onTap: _setupSampleVehicles,
            ),
            
            const SizedBox(height: 12),
            
            // Sample Brokers
            _buildSetupCard(
              icon: Icons.business,
              title: 'Sample Brokers',
              description: 'Add sample brokers for trip assignments',
              onTap: _setupSampleBrokers,
            ),
            
            const SizedBox(height: 12),
            
            // Complete Setup
            _buildSetupCard(
              icon: Icons.rocket_launch,
              title: 'Complete Setup',
              description: 'Set up all foundation data at once',
              onTap: _setupCompleteFoundation,
              isPrimary: true,
            ),
            
            const Spacer(),
            
            // Info
            Container(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will populate your database with sample data to get started. You can always add, edit, or delete this data later.',
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
    );
  }

  Widget _buildSetupCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPrimary ? AppColors.primaryBlue : Colors.grey[200],
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : Colors.grey[600],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPrimary ? AppColors.primaryBlue : Colors.black,
          ),
        ),
        subtitle: Text(description),
        trailing: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: isPrimary ? AppColors.primaryBlue : Colors.grey[400],
                size: 16,
              ),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  Future<void> _setupSampleVehicles() async {
    setState(() {
      _isLoading = true;
      _status = '';
    });

    try {
      // Sample vehicles data
      final sampleVehicles = [
        {
          'registration_number': 'KA01AB1234',
          'vehicle_type': 'Truck',
          'capacity': '10 tons',
          'status': 'active',
        },
        {
          'registration_number': 'KA02CD5678',
          'vehicle_type': 'Truck',
          'capacity': '15 tons',
          'status': 'active',
        },
        {
          'registration_number': 'KA03EF9012',
          'vehicle_type': 'Truck',
          'capacity': '20 tons',
          'status': 'active',
        },
        {
          'registration_number': 'KA04GH3456',
          'vehicle_type': 'Truck',
          'capacity': '12 tons',
          'status': 'maintenance',
        },
        {
          'registration_number': 'KA05IJ7890',
          'vehicle_type': 'Truck',
          'capacity': '18 tons',
          'status': 'active',
        },
      ];

      // Add vehicles to database
      for (final vehicleData in sampleVehicles) {
        await SupabaseService.saveVehicle(vehicleData);
      }

      setState(() {
        _status = 'Successfully added ${sampleVehicles.length} sample vehicles!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding sample vehicles: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _setupSampleBrokers() async {
    setState(() {
      _isLoading = true;
      _status = '';
    });

    try {
      // Sample brokers data
      final sampleBrokers = [
        {
          'name': 'ABC Logistics',
          'contact_person': 'John Doe',
          'phone': '+91-9876543210',
          'email': 'john@abclogistics.com',
          'address': 'Mumbai, Maharashtra',
          'commission_rate': 5.00,
          'status': 'active',
        },
        {
          'name': 'XYZ Transport',
          'contact_person': 'Jane Smith',
          'phone': '+91-9876543211',
          'email': 'jane@xyztransport.com',
          'address': 'Delhi, NCR',
          'commission_rate': 4.50,
          'status': 'active',
        },
        {
          'name': 'PQR Freight',
          'contact_person': 'Mike Johnson',
          'phone': '+91-9876543212',
          'email': 'mike@pqrfreight.com',
          'address': 'Bangalore, Karnataka',
          'commission_rate': 6.00,
          'status': 'active',
        },
        {
          'name': 'DEF Cargo',
          'contact_person': 'Sarah Wilson',
          'phone': '+91-9876543213',
          'email': 'sarah@defcargo.com',
          'address': 'Chennai, Tamil Nadu',
          'commission_rate': 5.50,
          'status': 'active',
        },
      ];

      // Add brokers to database
      for (final brokerData in sampleBrokers) {
        await SupabaseService.createBrokerFromMap(brokerData);
      }

      setState(() {
        _status = 'Successfully added ${sampleBrokers.length} sample brokers!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding sample brokers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _setupCompleteFoundation() async {
    setState(() {
      _isLoading = true;
      _status = '';
    });

    try {
      // Setup vehicles
      await _setupSampleVehicles();
      if (_status.contains('Error')) return;

      // Setup brokers
      await _setupSampleBrokers();
      if (_status.contains('Error')) return;

      setState(() {
        _status = 'Foundation data setup completed successfully! Your fleet management system is ready to use.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error in complete setup: $e';
        _isLoading = false;
      });
    }
  }
}
