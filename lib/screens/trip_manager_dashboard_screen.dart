import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';
import 'create_trip_screen.dart';
import 'trip_list_screen.dart';

class TripManagerDashboardScreen extends StatefulWidget {
  final UserModel user;

  const TripManagerDashboardScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<TripManagerDashboardScreen> createState() => _TripManagerDashboardScreenState();
}

class _TripManagerDashboardScreenState extends State<TripManagerDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // Dashboard data
  List<TripModel> _allTrips = [];
  List<VehicleModel> _vehicles = [];
  List<DriverModel> _drivers = [];
  int _activeTrips = 0;
  int _completedTrips = 0;
  int _pendingTrips = 0;
  int _settledTrips = 0;
  int _cancelledTrips = 0;
  
  // Key for refreshing trip list
  GlobalKey _tripListKey = GlobalKey();
  
  // Key for refreshing dashboard

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Refresh dashboard data when switching to dashboard tab
  void _onTabChanged(int index) {
    print('=== TAB CHANGED ===');
    print('Previous index: $_currentIndex');
    print('New index: $index');
    
    setState(() {
      _currentIndex = index;
    });
    
    // Refresh dashboard data when switching to dashboard tab (index 0)
    if (index == 0) {
      print('Switching to dashboard tab - refreshing data');
      _loadDashboardData();
    } else {
      print('Switching to tab $index - no refresh needed');
    }
  }

  Future<void> _loadDashboardData() async {
    print('=== LOADING DASHBOARD DATA ===');
    setState(() => _isLoading = true);
    
    try {
      // Load all trips
      _allTrips = await SupabaseService.getAllTrips();
      _activeTrips = _allTrips.where((trip) => trip.status == 'in_progress').length;
      _completedTrips = _allTrips.where((trip) => trip.status == 'completed').length;
      _pendingTrips = _allTrips.where((trip) => trip.status == 'assigned').length;
      _settledTrips = _allTrips.where((trip) => trip.status == 'settled').length;
      _cancelledTrips = _allTrips.where((trip) => trip.status == 'cancelled').length;
      
      print('Dashboard stats updated:');
      print('- Total trips: ${_allTrips.length}');
      print('- Active trips: $_activeTrips');
      print('- Completed trips: $_completedTrips');
      print('- Pending trips: $_pendingTrips');
      print('- Settled trips: $_settledTrips');
      print('- Cancelled trips: $_cancelledTrips');
      
      // Load vehicles and drivers
      _vehicles = await SupabaseService.getAllVehicles();
      _drivers = await SupabaseService.getAllDrivers();
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        onTap: _onTabChanged,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'All Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Fleet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Drivers',
          ),
        ],
      ),
    );
  }

  List<Widget> _getScreens() {
    return [
      _buildDashboardTab(),
      _buildTripListTab(),
      _buildCreateTripTab(),
      _buildFleetTab(),
      _buildDriversTab(),
    ];
  }

  Widget _buildTripListTab() {
    return TripListScreen(key: _tripListKey);
  }

  Widget _buildCreateTripTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_circle_outline,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Create New Trip',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to create a new trip',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateTrip,
            icon: const Icon(Icons.add),
            label: const Text('Create Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateTrip() async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateTripScreen(),
        ),
      );
      
      // Refresh dashboard data if a trip was created
      if (result != null) {
        print('Trip created, refreshing dashboard data');
        _loadDashboardData();
        
        // Force refresh the trip list by recreating it with a new key
        setState(() {
          _tripListKey = GlobalKey();
        });
      }
    } catch (e) {
      print('Error navigating to create trip: $e');
    }
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () {
        print('=== PULL TO REFRESH TRIGGERED ===');
        return _loadDashboardData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with Refresh Button
            _buildWelcomeSectionWithRefresh(),
            const SizedBox(height: 24),
            
            // Quick Stats
            _buildQuickStats(),
            const SizedBox(height: 24),
            
            // Recent Trips
            _buildRecentTripsSection(),
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSectionWithRefresh() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.user.name}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage trips, assign drivers, and track fleet operations',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  print('=== MANUAL REFRESH BUTTON CLICKED ===');
                  _loadDashboardData();
                },
                tooltip: 'Refresh Dashboard',
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildQuickStats() {
    return Column(
      children: [
        // First row - 3 cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Trips',
                _activeTrips.toString(),
                Icons.local_shipping,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                _completedTrips.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                _pendingTrips.toString(),
                Icons.schedule,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - 2 cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Settled',
                _settledTrips.toString(),
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cancelled',
                _cancelledTrips.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            // Empty space to maintain alignment
            const Expanded(child: SizedBox()),
          ],
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

  Widget _buildRecentTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Trips',
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
        if (_allTrips.isEmpty)
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
                  'No trips created yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first trip to get started',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          ..._allTrips.take(3).map((trip) => _buildTripCard(trip)),
      ],
    );
  }

  Widget _buildTripCard(TripModel trip) {
    Color statusColor;
    switch (trip.status) {
      case 'assigned':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            Icons.local_shipping,
            color: statusColor,
          ),
        ),
        title: Text('LR-${trip.lrNumber}'),
        subtitle: Text('${trip.fromLocation} → ${trip.toLocation}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${trip.totalRate?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trip.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to trip details
          // TODO: Implement trip details navigation
        },
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
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Create New Trip',
                Icons.add_circle,
                Colors.blue,
                () => setState(() => _currentIndex = 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View All Trips',
                Icons.list,
                Colors.green,
                () => setState(() => _currentIndex = 1),
              ),
            ),
          ],
        ),
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

  Widget _buildFleetTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fleet Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Fleet Statistics
          _buildFleetStats(),
          const SizedBox(height: 16),
          
          // Vehicles Section
          Text(
            'All Vehicles (${_vehicles.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _vehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No vehicles available',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.directions_car, color: Colors.blue.shade700),
                          ),
                          title: Text(vehicle.registrationNumber),
                          subtitle: Text('${vehicle.vehicleType} • ${vehicle.capacity} tons'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: vehicle.status == 'active' ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vehicle.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: vehicle.status == 'active' ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStats() {
    final activeVehicles = _vehicles.where((v) => v.status == 'active').length;
    final inactiveVehicles = _vehicles.where((v) => v.status == 'inactive').length;
    final maintenanceVehicles = _vehicles.where((v) => v.status == 'maintenance').length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active',
                activeVehicles.toString(),
                Icons.directions_car,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Inactive',
                inactiveVehicles.toString(),
                Icons.directions_car_outlined,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Maintenance',
                maintenanceVehicles.toString(),
                Icons.build,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriversTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Drivers',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drivers Statistics
            _buildDriversStats(),
            const SizedBox(height: 16),
            
            // Drivers Section
            Text(
              'All Drivers (${_drivers.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No drivers available',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _drivers.length,
                      itemBuilder: (context, index) {
                        final driver = _drivers[index];
                        return _buildDriverCard(driver);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversStats() {
    final activeDrivers = _drivers.where((d) => d.status == 'active').length;
    final inactiveDrivers = _drivers.where((d) => d.status == 'inactive').length;
    final suspendedDrivers = _drivers.where((d) => d.status == 'suspended').length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active',
                activeDrivers.toString(),
                Icons.person,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Inactive',
                inactiveDrivers.toString(),
                Icons.person_outline,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Suspended',
                suspendedDrivers.toString(),
                Icons.person_off,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverCard(DriverModel driver) {
    Color statusColor;
    IconData statusIcon;
    
    switch (driver.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'inactive':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'suspended':
        statusColor = Colors.orange;
        statusIcon = Icons.person_off;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.person, color: statusColor),
        ),
        title: Text(
          driver.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('License: ${driver.licenseNumber}'),
            Text('Phone: ${driver.phoneNumber}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(height: 2),
            Text(
              driver.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
