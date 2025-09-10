import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/broker_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';

class TripDetailsScreen extends StatefulWidget {
  final TripModel trip;

  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  List<BrokerModel> _brokers = [];
  List<VehicleModel> _vehicles = [];
  List<DriverModel> _drivers = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final brokers = await SupabaseService.getBrokers();
      final vehicles = await SupabaseService.getVehicles();
      final drivers = await SupabaseService.getDrivers();
      
      setState(() {
        _brokers = brokers;
        _vehicles = vehicles;
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load trip details: $e');
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

  Future<void> _updateTripStatus(String newStatus) async {
    try {
      await SupabaseService.updateTripStatus(widget.trip.id, newStatus);
      setState(() {
        // Update the trip status locally
        widget.trip.status = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip status updated to ${_getStatusDisplayName(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update trip status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.lrNumber),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trip Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(widget.trip.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _getStatusColor(widget.trip.status)),
                                ),
                                child: Text(
                                  _getStatusDisplayName(widget.trip.status),
                                  style: TextStyle(
                                    color: _getStatusColor(widget.trip.status),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Created',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.trip.createdAt.day}/${widget.trip.createdAt.month}/${widget.trip.createdAt.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Route Information
                  _buildSectionCard(
                    'Route Information',
                    [
                      _buildInfoRow('From', widget.trip.fromLocation, Icons.location_on),
                      _buildInfoRow('To', widget.trip.toLocation, Icons.location_on),
                      if (widget.trip.distanceKm != null)
                        _buildInfoRow('Distance', '${widget.trip.distanceKm!.toStringAsFixed(2)} km', Icons.straighten),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Assignment Information
                  _buildSectionCard(
                    'Assignment',
                    [
                      _buildInfoRow('Vehicle', _getVehicleRegistration(widget.trip.vehicleId), Icons.local_shipping),
                      _buildInfoRow('Driver', _getDriverName(widget.trip.driverId), Icons.person),
                      _buildInfoRow('Broker', _getBrokerName(widget.trip.brokerId), Icons.business),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Load Information
                  _buildSectionCard(
                    'Load Information',
                    [
                      if (widget.trip.tonnage != null)
                        _buildInfoRow('Tonnage', '${widget.trip.tonnage!.toStringAsFixed(2)} tons', Icons.scale),
                      if (widget.trip.ratePerTon != null)
                        _buildInfoRow('Rate per Ton', '₹${widget.trip.ratePerTon!.toStringAsFixed(2)}', Icons.attach_money),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Financial Information
                  _buildSectionCard(
                    'Financial Summary',
                    [
                      _buildInfoRow('Total Rate', '₹${widget.trip.totalRate?.toStringAsFixed(2) ?? '0.00'}', Icons.attach_money),
                      _buildInfoRow('Commission', '₹${widget.trip.commissionAmount.toStringAsFixed(2)}', Icons.percent),
                      _buildInfoRow('Advance Given', '₹${widget.trip.advanceGiven.toStringAsFixed(2)}', Icons.account_balance_wallet),
                      _buildInfoRow('Diesel Issued', '₹${widget.trip.dieselIssued.toStringAsFixed(2)}', Icons.local_gas_station),
                      _buildInfoRow('Silak Amount', '₹${widget.trip.silakAmount.toStringAsFixed(2)}', Icons.money),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Trip Dates
                  if (widget.trip.startDate != null || widget.trip.endDate != null)
                    _buildSectionCard(
                      'Trip Timeline',
                      [
                        if (widget.trip.startDate != null)
                          _buildInfoRow('Start Date', '${widget.trip.startDate!.day}/${widget.trip.startDate!.month}/${widget.trip.startDate!.year}', Icons.play_arrow),
                        if (widget.trip.endDate != null)
                          _buildInfoRow('End Date', '${widget.trip.endDate!.day}/${widget.trip.endDate!.month}/${widget.trip.endDate!.year}', Icons.stop),
                      ],
                    ),
                  const SizedBox(height: 16),
                  
                  // Notes
                  if (widget.trip.notes != null && widget.trip.notes!.isNotEmpty)
                    _buildSectionCard(
                      'Notes',
                      [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            widget.trip.notes!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.trip.status == 'assigned')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateTripStatus('in_progress'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (widget.trip.status == 'in_progress') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateTripStatus('completed'),
                      icon: const Icon(Icons.check),
                      label: const Text('Complete Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateTripStatus('cancelled'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
                if (widget.trip.status == 'completed')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateTripStatus('settled'),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Settle Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


