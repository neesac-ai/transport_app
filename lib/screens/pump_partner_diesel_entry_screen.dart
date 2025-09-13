import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/models/user_model.dart';
import 'package:version1/models/trip_model.dart';
import 'package:version1/models/diesel_record_model.dart';
import 'package:version1/services/supabase_service.dart';

class PumpPartnerDieselEntryScreen extends StatefulWidget {
  final UserModel user;
  final TripModel? selectedTrip;

  const PumpPartnerDieselEntryScreen({
    super.key,
    required this.user,
    this.selectedTrip,
  });

  @override
  State<PumpPartnerDieselEntryScreen> createState() => _PumpPartnerDieselEntryScreenState();
}

class _PumpPartnerDieselEntryScreenState extends State<PumpPartnerDieselEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<TripModel> _activeTrips = [];
  List<DieselRecordModel> _recentDieselRecords = [];
  
  TripModel? _selectedTrip;
  
  final _quantityController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedTrip = widget.selectedTrip;
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pricePerLiterController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load active trips
      final trips = await SupabaseService.getAllTrips();
      _activeTrips = trips.where((trip) => 
        trip.status == 'assigned' || trip.status == 'in_progress'
      ).toList();
      
      // If we have a selected trip from constructor, make sure it's in the active trips list
      if (_selectedTrip != null) {
        final tripIndex = _activeTrips.indexWhere((t) => t.id == _selectedTrip!.id);
        if (tripIndex >= 0) {
          _selectedTrip = _activeTrips[tripIndex];
        } else {
          _selectedTrip = null;
        }
      }
      
      // Load recent diesel records
      _recentDieselRecords = await _getRecentDieselRecords();
      
    } catch (e) {
      print('Error loading diesel entry data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<DieselRecordModel>> _getRecentDieselRecords() async {
    // In a real app, this would fetch from the diesel_records table
    // For now, we'll return sample data
    return [
      DieselRecordModel(
        id: '1',
        tripId: '123',
        vehicleId: 'vehicle1',
        quantity: 100.0,
        pricePerLiter: 90.5,
        totalAmount: 9050.0,
        recordType: 'refill',
        pumpPartnerId: widget.user.id,
        recordDate: DateTime.now().subtract(const Duration(days: 1)),
        location: 'Highway Pump 1',
        notes: 'Regular diesel',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DieselRecordModel(
        id: '2',
        tripId: '456',
        vehicleId: 'vehicle2',
        quantity: 150.0,
        pricePerLiter: 91.2,
        totalAmount: 13680.0,
        recordType: 'refill',
        pumpPartnerId: widget.user.id,
        recordDate: DateTime.now().subtract(const Duration(days: 2)),
        location: 'City Pump 2',
        notes: 'Premium diesel',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  void _calculateTotalAmount() {
    double quantity = 0.0;
    double pricePerLiter = 0.0;
    
    try {
      quantity = double.parse(_quantityController.text);
    } catch (_) {}
    
    try {
      pricePerLiter = double.parse(_pricePerLiterController.text);
    } catch (_) {}
    
    setState(() {
      _totalAmount = quantity * pricePerLiter;
    });
  }

  Future<void> _saveDieselRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a trip'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would save to the diesel_records table
      // For now, we'll just show a success message
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diesel record saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form
      _quantityController.clear();
      _pricePerLiterController.clear();
      _locationController.clear();
      _notesController.clear();
      setState(() {
        _totalAmount = 0.0;
      });
      
      // Refresh data
      _loadData();
    } catch (e) {
      print('Error saving diesel record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving diesel record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diesel Entry'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDieselEntryForm(),
                  const SizedBox(height: 24),
                  _buildRecentDieselRecords(),
                ],
              ),
            ),
    );
  }

  Widget _buildDieselEntryForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Record Diesel Fill',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Trip selection dropdown
              DropdownButtonFormField<TripModel>(
                decoration: const InputDecoration(
                  labelText: 'Select Trip *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                initialValue: _selectedTrip,
                items: _activeTrips.map((trip) {
                  return DropdownMenuItem<TripModel>(
                    value: trip,
                    child: Text('${trip.lrNumber} (${trip.fromLocation} to ${trip.toLocation})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTrip = value;
                    // No need to track vehicle ID separately as it's available in _selectedTrip
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a trip';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Quantity field
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (Liters) *',
                  hintText: 'Enter diesel quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.water_drop),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotalAmount(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter diesel quantity';
                  }
                  try {
                    final quantity = double.parse(value);
                    if (quantity <= 0) {
                      return 'Quantity must be greater than 0';
                    }
                  } catch (_) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Price per liter field
              TextFormField(
                controller: _pricePerLiterController,
                decoration: const InputDecoration(
                  labelText: 'Price per Liter (₹) *',
                  hintText: 'Enter price per liter',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotalAmount(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price per liter';
                  }
                  try {
                    final price = double.parse(value);
                    if (price <= 0) {
                      return 'Price must be greater than 0';
                    }
                  } catch (_) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Total amount display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Location field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter pump location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Enter any additional notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDieselRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Diesel Record',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDieselRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Diesel Records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentDieselRecords.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No recent diesel records'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentDieselRecords.length,
            itemBuilder: (context, index) {
              final record = _recentDieselRecords[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.local_gas_station, color: Colors.blue.shade700),
                  ),
                  title: Text('${record.quantity.toStringAsFixed(1)} L at ₹${record.pricePerLiter.toStringAsFixed(2)}/L'),
                  subtitle: Text('${_formatDate(record.recordDate)} • ${record.location ?? 'Unknown location'}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${record.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        record.recordType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showDieselRecordDetails(record),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showDieselRecordDetails(DieselRecordModel record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diesel Record Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Quantity', '${record.quantity.toStringAsFixed(1)} L'),
            _buildDetailRow('Price per Liter', '₹${record.pricePerLiter.toStringAsFixed(2)}'),
            _buildDetailRow('Total Amount', '₹${record.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Date', _formatDate(record.recordDate)),
            if (record.location != null) _buildDetailRow('Location', record.location!),
            if (record.notes != null) _buildDetailRow('Notes', record.notes!),
            _buildDetailRow('Record Type', record.recordType.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
