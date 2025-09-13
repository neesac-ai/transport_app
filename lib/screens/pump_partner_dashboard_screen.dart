import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/models/user_model.dart';
import 'package:version1/models/trip_model.dart';
import 'package:version1/services/supabase_service.dart';
import 'pump_partner_diesel_entry_screen.dart';
import 'pump_partner_profile_screen.dart';

class PumpPartnerDashboardScreen extends StatefulWidget {
  final UserModel user;

  const PumpPartnerDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<PumpPartnerDashboardScreen> createState() => _PumpPartnerDashboardScreenState();
}

class _PumpPartnerDashboardScreenState extends State<PumpPartnerDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<TripModel> _activeTrips = [];
  int _totalDieselFills = 0;
  double _totalDieselQuantity = 0;
  double _totalDieselAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load active trips
      final trips = await SupabaseService.getAllTrips();
      _activeTrips = trips.where((trip) => 
        trip.status == 'assigned' || trip.status == 'in_progress'
      ).toList();
      
      // Get diesel statistics
      final dieselStats = await _getDieselStatistics();
      _totalDieselFills = dieselStats['totalFills'];
      _totalDieselQuantity = dieselStats['totalQuantity'];
      _totalDieselAmount = dieselStats['totalAmount'];
      
    } catch (e) {
      print('Error loading pump partner dashboard data: $e');
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

  Future<Map<String, dynamic>> _getDieselStatistics() async {
    // In a real app, this would fetch from the diesel_records table
    // For now, we'll return sample data
    return {
      'totalFills': 12,
      'totalQuantity': 1250.5,
      'totalAmount': 112545.0,
    };
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
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Diesel Entry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  List<Widget> _getScreens() {
    return [
      _buildDashboardTab(),
      PumpPartnerDieselEntryScreen(user: widget.user),
      PumpPartnerProfileScreen(user: widget.user),
    ];
  }

  Widget _buildDashboardTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pump Partner Dashboard'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildDieselStats(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildActiveTripsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            radius: 30,
            child: const Icon(
              Icons.local_gas_station,
              size: 30,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.user.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have ${_activeTrips.length} active trips that may need diesel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadDashboardData,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last updated: ${DateTime.now().toString().split('.')[0]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDieselStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diesel Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Fills',
                '$_totalDieselFills',
                'Transactions',
                Icons.local_gas_station,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Quantity',
                '${_totalDieselQuantity.toStringAsFixed(1)} L',
                'Diesel',
                Icons.water_drop,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Amount',
                '₹${_totalDieselAmount.toStringAsFixed(0)}',
                'Value',
                Icons.currency_rupee,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Record Diesel Fill',
                Icons.local_gas_station,
                Colors.blue,
                () => setState(() => _currentIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View Active Trips',
                Icons.directions_car,
                Colors.green,
                () => _showActiveTripsDialog(),
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

  Widget _buildActiveTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showActiveTripsDialog(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_activeTrips.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No active trips'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeTrips.length > 3 ? 3 : _activeTrips.length,
            itemBuilder: (context, index) {
              final trip = _activeTrips[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.directions_car, color: Colors.blue.shade700),
                  ),
                  title: Text(trip.lrNumber),
                  subtitle: Text('${trip.fromLocation} to ${trip.toLocation}'),
                  trailing: ElevatedButton(
                    onPressed: () => _recordDieselForTrip(trip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Add Diesel'),
                  ),
                  onTap: () => _recordDieselForTrip(trip),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showActiveTripsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Trips'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _activeTrips.isEmpty
              ? const Center(child: Text('No active trips'))
              : ListView.builder(
                  itemCount: _activeTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _activeTrips[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.directions_car, color: Colors.blue.shade700),
                      ),
                      title: Text(trip.lrNumber),
                      subtitle: Text('${trip.fromLocation} to ${trip.toLocation}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _recordDieselForTrip(trip);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Add Diesel'),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _recordDieselForTrip(trip);
                      },
                    );
                  },
                ),
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

  void _recordDieselForTrip(TripModel trip) {
    // Navigate to diesel entry screen with pre-selected trip
    setState(() => _currentIndex = 1);
    
    // Pass the selected trip to the diesel entry screen
    // This would be implemented in a real app by using a state management solution
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recording diesel for trip ${trip.lrNumber}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}


