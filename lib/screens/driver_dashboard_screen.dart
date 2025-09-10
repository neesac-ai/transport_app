import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';
import 'driver_trip_list_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_trip_details_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  final UserModel user;

  const DriverDashboardScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // Dashboard data
  List<TripModel> _assignedTrips = [];
  List<TripModel> _completedTrips = [];
  VehicleModel? _assignedVehicle;
  int _pendingExpenses = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load driver's trips
      final trips = await SupabaseService.getDriverTrips(widget.user.id);
      _assignedTrips = trips.where((trip) => 
        trip.status == 'assigned' || trip.status == 'in_progress').toList();
      _completedTrips = trips.where((trip) => 
        trip.status == 'completed' || trip.status == 'settled').toList();
      
      // Load assigned vehicle (mock for now)
      final vehicles = await SupabaseService.getVehicles();
      _assignedVehicle = vehicles.isNotEmpty ? vehicles.first : null;
      
      // Load pending expenses count
      final expenses = await SupabaseService.getDriverExpenses(widget.user.id);
      _pendingExpenses = expenses.where((e) => e.status == 'pending').length;
      
      // Load advance information (for future use)
      // final advances = await SupabaseService.getDriverAdvances(widget.user.id);
      
    } catch (e) {
      print('Error loading dashboard data: $e');
      _showErrorSnackBar('Failed to load dashboard data');
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

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            
            // Quick Stats
            _buildQuickStats(),
            const SizedBox(height: 24),
            
            // Assigned Trips
            _buildAssignedTripsSection(),
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${widget.user.name}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to hit the road?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          if (_assignedVehicle != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Vehicle: ${_assignedVehicle!.registrationNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Assigned Trips',
            _assignedTrips.length.toString(),
            Icons.assignment,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            _completedTrips.length.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Expenses',
            _pendingExpenses.toString(),
            Icons.receipt,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Assigned Trips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_assignedTrips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No assigned trips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new assignments',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          ..._assignedTrips.take(3).map((trip) => _buildTripCard(trip)),
      ],
    );
  }

  Widget _buildTripCard(TripModel trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(trip.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trip.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(trip.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.fromLocation} → ${trip.toLocation}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Distance: ${trip.distanceKm} km | Tonnage: ${trip.tonnage} tons',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateTripStatus(trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Update Status'),
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'Trip LR-001 completed',
                '2 hours ago',
                Icons.check_circle,
                Colors.green,
              ),
              const Divider(),
              _buildActivityItem(
                'Expense submitted for approval',
                '4 hours ago',
                Icons.receipt,
                Colors.blue,
              ),
              const Divider(),
              _buildActivityItem(
                'Advance request approved',
                '1 day ago',
                Icons.attach_money,
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_assignedTrips.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'View My Trips',
                  Icons.assignment,
                  Colors.blue,
                  () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Start Trip',
                  Icons.play_arrow,
                  Colors.green,
                  () => _showStartTripDialog(),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 32,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No active trips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wait for trip assignments from Trip Manager',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _updateTripStatus(TripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Trip Status - ${trip.lrNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('In Progress'),
              value: 'in_progress',
              groupValue: trip.status,
              onChanged: (value) => _changeTripStatus(trip, value!),
            ),
            RadioListTile<String>(
              title: const Text('Completed'),
              value: 'completed',
              groupValue: trip.status,
              onChanged: (value) => _changeTripStatus(trip, value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeTripStatus(TripModel trip, String newStatus) async {
    try {
      await SupabaseService.updateTripStatus(trip.id, newStatus);
      Navigator.pop(context);
      _loadDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Failed to update trip status');
    }
  }

  void _viewTripDetails(TripModel trip) {
    // Navigate to trip details screen
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

  List<Widget> _getScreens() {
    return [
      _buildDashboardTab(),
      DriverTripListScreen(user: widget.user),
      DriverProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'My Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showStartTripDialog() {
    if (_assignedTrips.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _assignedTrips.map((trip) => ListTile(
            title: Text('LR-${trip.lrNumber}'),
            subtitle: Text('${trip.fromLocation} → ${trip.toLocation}'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to trip details to start the trip
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverTripDetailsScreen(trip: trip),
                  ),
                );
              },
              child: const Text('Start'),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
