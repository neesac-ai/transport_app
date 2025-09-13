import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/broker_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _tonnageController = TextEditingController();
  final _ratePerTonController = TextEditingController();
  final _commissionRateController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  
  // Silak allowance controllers
  final _fuelAllowanceController = TextEditingController(text: '0');
  final _foodAllowanceController = TextEditingController(text: '0');
  final _stayAllowanceController = TextEditingController(text: '0');
  final _otherAllowanceController = TextEditingController(text: '0');
  final _otherAllowanceDescController = TextEditingController();

  String? _selectedVehicleId;
  String? _selectedDriverId;
  String? _selectedBrokerId;
  
  List<VehicleModel> _vehicles = [];
  List<DriverModel> _drivers = [];
  List<BrokerModel> _brokers = [];
  
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _distanceController.dispose();
    _tonnageController.dispose();
    _ratePerTonController.dispose();
    _commissionRateController.dispose();
    _notesController.dispose();
    
    // Dispose silak controllers
    _fuelAllowanceController.dispose();
    _foodAllowanceController.dispose();
    _stayAllowanceController.dispose();
    _otherAllowanceController.dispose();
    _otherAllowanceDescController.dispose();
    
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final vehicles = await SupabaseService.getVehicles();
      final drivers = await SupabaseService.getDrivers();
      final brokers = await SupabaseService.getBrokers();
      
      print('=== CREATE TRIP: Data loaded ===');
      print('Vehicles count: ${vehicles.length}');
      print('Drivers count: ${drivers.length}');
      print('Brokers count: ${brokers.length}');
      
      if (drivers.isNotEmpty) {
        print('First driver: ${drivers.first.name} (${drivers.first.id})');
      }
      
      setState(() {
        _vehicles = vehicles;
        _drivers = drivers;
        _brokers = brokers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading data: $e');
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  double _calculateTotalRate() {
    final tonnage = double.tryParse(_tonnageController.text) ?? 0.0;
    final ratePerTon = double.tryParse(_ratePerTonController.text) ?? 0.0;
    return tonnage * ratePerTon;
  }

  double _calculateCommission() {
    final totalRate = _calculateTotalRate();
    final commissionRate = double.tryParse(_commissionRateController.text) ?? 0.0;
    return totalRate * (commissionRate / 100);
  }
  
  double _calculateSilakAllowance() {
    final distance = double.tryParse(_distanceController.text) ?? 0.0;
    final fuelAllowance = double.tryParse(_fuelAllowanceController.text) ?? 0.0;
    final foodAllowance = double.tryParse(_foodAllowanceController.text) ?? 0.0;
    final stayAllowance = double.tryParse(_stayAllowanceController.text) ?? 0.0;
    final otherAllowance = double.tryParse(_otherAllowanceController.text) ?? 0.0;
    
    final totalFuel = distance * fuelAllowance;
    final totalFood = distance * foodAllowance;
    final totalStay = distance * stayAllowance;
    final totalOther = distance * otherAllowance;
    
    return totalFuel + totalFood + totalStay + totalOther;
  }

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null || _selectedDriverId == null) {
      _showErrorSnackBar('Please select vehicle and driver');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final trip = TripModel(
        id: '', // Will be generated by database
        lrNumber: '', // Will be auto-generated
        vehicleId: _selectedVehicleId!,
        driverId: _selectedDriverId!,
        brokerId: _selectedBrokerId?.isEmpty == true ? null : _selectedBrokerId,
        fromLocation: _fromLocationController.text.trim(),
        toLocation: _toLocationController.text.trim(),
        distanceKm: double.tryParse(_distanceController.text),
        tonnage: double.tryParse(_tonnageController.text),
        ratePerTon: double.tryParse(_ratePerTonController.text),
        totalRate: _calculateTotalRate(),
        commissionAmount: _calculateCommission(),
        silakAmount: _calculateSilakAllowance(),
        status: 'assigned',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final createdTrip = await SupabaseService.createTrip(trip);
      
      _showSuccessSnackBar('Trip created successfully! LR Number: ${createdTrip.lrNumber}');
      
      // Add a small delay to ensure the snackbar is shown
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pop(createdTrip);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create trip: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Trip'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Trip Details'),
                    const SizedBox(height: 16),
                    
                    // From Location
                    TextFormField(
                      controller: _fromLocationController,
                      decoration: const InputDecoration(
                        labelText: 'From Location *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter from location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // To Location
                    TextFormField(
                      controller: _toLocationController,
                      decoration: const InputDecoration(
                        labelText: 'To Location *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter to location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Distance
                    TextFormField(
                      controller: _distanceController,
                      decoration: const InputDecoration(
                        labelText: 'Distance (km)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                        suffixText: 'km',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}), // Trigger rebuild for calculations
                    ),
                    const SizedBox(height: 16),
                    
                    // Tonnage
                    TextFormField(
                      controller: _tonnageController,
                      decoration: const InputDecoration(
                        labelText: 'Tonnage *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                        suffixText: 'tons',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter tonnage';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter valid tonnage';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}), // Trigger rebuild for calculations
                    ),
                    const SizedBox(height: 16),
                    
                    // Rate per Ton
                    TextFormField(
                      controller: _ratePerTonController,
                      decoration: const InputDecoration(
                        labelText: 'Rate per Ton *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter rate per ton';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter valid rate';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}), // Trigger rebuild for calculations
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('Assignment'),
                    const SizedBox(height: 16),
                    
                    // Vehicle Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Select Vehicle *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      items: _vehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle.id,
                          child: Text('${vehicle.registrationNumber} (${vehicle.vehicleType})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedVehicleId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a vehicle';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Driver Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Select Driver *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _drivers.isEmpty 
                        ? [DropdownMenuItem(value: null, child: Text('No drivers available'))]
                        : _drivers.map((driver) {
                            print('Creating dropdown item for driver: ${driver.name} (${driver.id})');
                            return DropdownMenuItem(
                              value: driver.id,
                              child: Text('${driver.name} (${driver.licenseNumber})'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        print('Driver selected: $value');
                        setState(() => _selectedDriverId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a driver';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Broker Selection
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedBrokerId,
                      decoration: const InputDecoration(
                        labelText: 'Select Broker',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Broker'),
                        ),
                        ..._brokers.map((broker) {
                          return DropdownMenuItem<String?>(
                            value: broker.id,
                            child: Text('${broker.name} (${broker.company})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedBrokerId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Commission Rate
                    TextFormField(
                      controller: _commissionRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Commission Rate (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                        suffixText: '%',
                      ),
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild to update financial summary
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter commission rate';
                        }
                        final rate = double.tryParse(value);
                        if (rate == null || rate < 0 || rate > 100) {
                          return 'Commission rate must be between 0 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('Silak Allowances'),
                    const SizedBox(height: 16),
                    
                    // Silak allowances section
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver allowances calculated per kilometer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Fuel allowance
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _fuelAllowanceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Fuel Allowance (₹/km)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.local_gas_station),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (double.tryParse(_distanceController.text) != null && double.tryParse(_fuelAllowanceController.text) != null)
                                  Text(
                                    'Total: ₹${(double.parse(_distanceController.text) * double.parse(_fuelAllowanceController.text)).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Food allowance
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _foodAllowanceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Food Allowance (₹/km)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.restaurant),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (double.tryParse(_distanceController.text) != null && double.tryParse(_foodAllowanceController.text) != null)
                                  Text(
                                    'Total: ₹${(double.parse(_distanceController.text) * double.parse(_foodAllowanceController.text)).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Stay allowance
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _stayAllowanceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Stay Allowance (₹/km)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.hotel),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (double.tryParse(_distanceController.text) != null && double.tryParse(_stayAllowanceController.text) != null)
                                  Text(
                                    'Total: ₹${(double.parse(_distanceController.text) * double.parse(_stayAllowanceController.text)).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Other allowance
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _otherAllowanceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Other Allowance (₹/km)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.more_horiz),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (double.tryParse(_distanceController.text) != null && double.tryParse(_otherAllowanceController.text) != null)
                                  Text(
                                    'Total: ₹${(double.parse(_distanceController.text) * double.parse(_otherAllowanceController.text)).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Description for other allowance
                            TextFormField(
                              controller: _otherAllowanceDescController,
                              decoration: const InputDecoration(
                                labelText: 'Other Allowance Description',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Total Silak Allowance
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Silak Allowance:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '₹${_calculateSilakAllowance().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('Financial Summary'),
                    const SizedBox(height: 16),
                    
                    // Financial Summary Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildFinancialRow('Total Rate', '₹${_calculateTotalRate().toStringAsFixed(2)}'),
                            const Divider(),
                            _buildFinancialRow('Commission (${_commissionRateController.text}%)', '₹${_calculateCommission().toStringAsFixed(2)}'),
                            const Divider(),
                            _buildFinancialRow('Silak Allowance', '₹${_calculateSilakAllowance().toStringAsFixed(2)}'),
                            const Divider(),
                            _buildFinancialRow('Net Amount', '₹${(_calculateTotalRate() - _calculateCommission()).toStringAsFixed(2)}', isTotal: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('Additional Information'),
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Create Trip',
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primaryBlue : null,
            ),
          ),
        ],
      ),
    );
  }
}

