import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';
import 'add_vehicle_screen.dart';
import 'add_driver_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VehicleModel> _vehicles = [];
  List<DriverModel> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await SupabaseService.getVehicles();
      final drivers = await SupabaseService.getDrivers();
      
      setState(() {
        _vehicles = vehicles;
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.lightBlue,
          tabs: const [
            Tab(text: 'Vehicles', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Drivers', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVehiclesTab(),
          _buildDriversTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _navigateToAddVehicle();
          } else {
            _navigateToAddDriver();
          }
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildVehiclesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping,
              size: 80,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildDriversTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      );
    }

    if (_drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 80,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No drivers found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first driver to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return _buildDriverCard(driver);
        },
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.registrationNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        vehicle.vehicleType,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(vehicle.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(vehicle.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.straighten, size: 16, color: AppColors.grey500),
                const SizedBox(width: 8),
                Text(
                  'Capacity: ${vehicle.capacity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
            if (vehicle.driverId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.grey500),
                  const SizedBox(width: 8),
                  Text(
                    'Driver: ${vehicle.driverId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverModel driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        driver.phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDriverStatusColor(driver.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    driver.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getDriverStatusColor(driver.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.badge, size: 16, color: AppColors.grey500),
                const SizedBox(width: 8),
                Text(
                  'License: ${driver.licenseNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
            if (driver.assignedVehicleId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: AppColors.grey500),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle: ${driver.assignedVehicleId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'maintenance':
        return AppColors.warning;
      case 'inactive':
        return AppColors.grey500;
      case 'retired':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  Color _getDriverStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'on_trip':
        return AppColors.primaryBlue;
      case 'on_leave':
        return AppColors.warning;
      case 'inactive':
        return AppColors.grey500;
      default:
        return AppColors.grey500;
    }
  }

  void _navigateToAddVehicle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddVehicleScreen(),
      ),
    ).then((_) {
      _loadData(); // Refresh data when returning
    });
  }

  void _navigateToAddDriver() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddDriverScreen(),
      ),
    ).then((_) {
      _loadData(); // Refresh data when returning
    });
  }
}
