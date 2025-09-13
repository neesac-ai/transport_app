import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../services/supabase_service.dart';
import 'driver_trip_details_screen.dart';

class DriverTripListScreen extends StatefulWidget {
  final UserModel user;

  const DriverTripListScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<DriverTripListScreen> createState() => _DriverTripListScreenState();
}

class _DriverTripListScreenState extends State<DriverTripListScreen> {
  bool _isLoading = true;
  List<TripModel> _trips = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    
    try {
      final trips = await SupabaseService.getDriverTrips(widget.user.id);
      setState(() => _trips = trips);
    } catch (e) {
      print('Error loading trips: $e');
      _showErrorSnackBar('Failed to load trips');
    } finally {
      setState(() => _isLoading = false);
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

  List<TripModel> _getFilteredTrips() {
    switch (_selectedFilter) {
      case 'assigned':
        return _trips.where((trip) => trip.status == 'assigned').toList();
      case 'in_progress':
        return _trips.where((trip) => trip.status == 'in_progress').toList();
      case 'completed':
        return _trips.where((trip) => trip.status == 'completed').toList();
      case 'settled':
        return _trips.where((trip) => trip.status == 'settled').toList();
      default:
        return _trips;
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'assigned', 'label': 'Assigned'},
      {'key': 'in_progress', 'label': 'In Progress'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'settled', 'label': 'Settled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter['key']!);
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _viewTripDetails(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LR: ${trip.lrNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      trip.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(trip.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${trip.fromLocation} → ${trip.toLocation}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.straighten, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${trip.distanceKm} km',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.local_shipping, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${trip.tonnage} tons',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '₹${trip.totalRate?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (trip.startDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Started: ${_formatDate(trip.startDate!)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewTripDetails(trip),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewTripDetails(TripModel trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverTripDetailsScreen(
          trip: trip,
          user: widget.user,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTrips,
                    child: _getFilteredTrips().isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _getFilteredTrips().length,
                            itemBuilder: (context, index) {
                              final trip = _getFilteredTrips()[index];
                              return _buildTripCard(trip);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No trips found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any trips in this category',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
