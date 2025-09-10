import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/broker_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';
import 'trip_details_screen.dart';
import 'create_trip_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<TripModel> _trips = [];
  List<BrokerModel> _brokers = [];
  List<VehicleModel> _vehicles = [];
  List<DriverModel> _drivers = [];
  
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      print('=== LOADING TRIP LIST DATA ===');
      final trips = await SupabaseService.getAllTrips();
      final brokers = await SupabaseService.getBrokers();
      final vehicles = await SupabaseService.getVehicles();
      final drivers = await SupabaseService.getDrivers();
      
      print('Loaded ${trips.length} trips');
      print('Loaded ${brokers.length} brokers');
      print('Loaded ${vehicles.length} vehicles');
      print('Loaded ${drivers.length} drivers');
      
      setState(() {
        _trips = trips;
        _brokers = brokers;
        _vehicles = vehicles;
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading trip list data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load trips: $e');
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

  List<TripModel> get _filteredTrips {
    if (_selectedStatus == 'all') {
      return _trips;
    }
    return _trips.where((trip) => trip.status == _selectedStatus).toList();
  }

  String _getBrokerName(String? brokerId) {
    if (brokerId == null) return 'No Broker';
    try {
      return _brokers.firstWhere((b) => b.id == brokerId).name;
    } catch (e) {
      return 'Unknown Broker';
    }
  }

  String _getVehicleRegistration(String vehicleId) {
    try {
      return _vehicles.firstWhere((v) => v.id == vehicleId).registrationNumber;
    } catch (e) {
      return 'Unknown Vehicle';
    }
  }

  String _getDriverName(String driverId) {
    try {
      return _drivers.firstWhere((d) => d.id == driverId).name;
    } catch (e) {
      return 'Unknown Driver';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'settled':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'settled':
        return 'Settled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Future<void> _updateTripStatus(String tripId, String newStatus) async {
    print('=== UPDATING TRIP STATUS ===');
    print('Trip ID: $tripId');
    print('New Status: $newStatus');
    
    try {
      await SupabaseService.updateTripStatus(tripId, newStatus);
      print('Trip status updated successfully');
      await _loadData(); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip status updated to ${_getStatusDisplayName(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating trip status: $e');
      _showErrorSnackBar('Failed to update trip status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Management'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreateTripScreen()),
              );
              if (result != null) {
                await _loadData(); // Reload if trip was created
              }
            },
            tooltip: 'Create Trip',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Filter by Status: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Trips')),
                      DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'settled', child: Text('Settled')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Trip List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTrips.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No trips found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first trip to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredTrips.length,
                          itemBuilder: (context, index) {
                            final trip = _filteredTrips[index];
                            print('Building trip card for: ${trip.lrNumber} (${trip.status})');
                            return _buildTripCard(trip);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      child: InkWell(
        onTap: () {
          print('=== TRIP CARD TAPPED ===');
          print('Trip ID: ${trip.id}');
          print('Trip LR Number: ${trip.lrNumber}');
          try {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(trip: trip),
              ),
            );
          } catch (e) {
            print('Error navigating to trip details: $e');
            _showErrorSnackBar('Error opening trip details: $e');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with LR Number and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trip.lrNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(trip.status)),
                    ),
                    child: Text(
                      _getStatusDisplayName(trip.status),
                      style: TextStyle(
                        color: _getStatusColor(trip.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Route Information
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${trip.fromLocation} → ${trip.toLocation}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Vehicle and Driver
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _getVehicleRegistration(trip.vehicleId),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _getDriverName(trip.driverId),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Broker
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _getBrokerName(trip.brokerId),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Financial Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Rate',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          '₹${trip.totalRate?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Commission',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          '₹${trip.commissionAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Action Buttons
              _buildActionButtons(trip),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(TripModel trip) {
    List<Widget> buttons = [
      Expanded(
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(trip: trip),
              ),
            );
          },
          child: const Text('View Details'),
        ),
      ),
    ];

    // Add status-specific buttons
    switch (trip.status) {
      case 'assigned':
        buttons.addAll([
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateTripStatus(trip.id, 'in_progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Trip'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showCancelConfirmation(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            ),
          ),
        ]);
        break;
      case 'in_progress':
        buttons.addAll([
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateTripStatus(trip.id, 'completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showCancelConfirmation(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            ),
          ),
        ]);
        break;
      case 'completed':
        buttons.addAll([
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateTripStatus(trip.id, 'settled'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Settle'),
            ),
          ),
        ]);
        break;
    }

    return Row(children: buttons);
  }

  void _showCancelConfirmation(TripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trip'),
        content: Text('Are you sure you want to cancel trip ${trip.lrNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateTripStatus(trip.id, 'cancelled');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
