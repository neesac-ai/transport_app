import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';
import 'add_vehicle_screen.dart';

class AdminFleetOverviewScreen extends StatefulWidget {
  const AdminFleetOverviewScreen({super.key});

  @override
  State<AdminFleetOverviewScreen> createState() => _AdminFleetOverviewScreenState();
}

class _AdminFleetOverviewScreenState extends State<AdminFleetOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VehicleModel> _vehicles = [];
  List<DriverModel> _drivers = [];
  bool _isLoading = true;
  String? _error;

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
      _error = null;
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
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Overview'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.local_shipping),
              text: 'Vehicles',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Drivers',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVehiclesTab(),
                    _buildDriversTab(),
                  ],
                ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesTab() {
    if (_vehicles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping,
        title: 'No Vehicles Found',
        subtitle: 'Add your first vehicle to get started',
        actionText: 'Add Vehicle',
        onAction: () => _navigateToAddVehicle(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                ),
              ),
              title: Text(
                vehicle.registrationNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: ${vehicle.vehicleType}'),
                  Text('Capacity: ${vehicle.capacity}'),
                  Text('Status: ${vehicle.status}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vehicle.status == 'active' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vehicle.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleVehicleAction(value, vehicle),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit_status',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Change Status'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'view_details',
                        child: Row(
                          children: [
                            Icon(Icons.info, size: 18),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => _showVehicleDetails(vehicle),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriversTab() {
    if (_drivers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person,
        title: 'No Drivers Found',
        subtitle: 'Drivers will appear here once they register and are approved',
        actionText: 'Refresh',
        onAction: _loadData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                driver.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('License: ${driver.licenseNumber}'),
                  Text('Phone: ${driver.phoneNumber}'),
                  Text('Email: ${driver.email}'),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: driver.status == 'active' ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  driver.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () => _showDriverDetails(driver),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Only show FAB for vehicles tab, not for drivers (drivers come from user registrations)
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        if (_tabController.index == 1) {
          return const SizedBox.shrink(); // Hide FAB for drivers tab
        }
        
        return FloatingActionButton(
          onPressed: _navigateToAddVehicle,
          backgroundColor: AppColors.primaryBlue,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        );
      },
    );
  }

  void _navigateToAddVehicle() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddVehicleScreen(),
      ),
    );
    
    if (result == true) {
      _loadData(); // Refresh data after adding vehicle
    }
  }


  void _handleVehicleAction(String action, VehicleModel vehicle) {
    switch (action) {
      case 'edit_status':
        _showStatusChangeDialog(vehicle);
        break;
      case 'view_details':
        _showVehicleDetails(vehicle);
        break;
    }
  }

  void _showStatusChangeDialog(VehicleModel vehicle) {
    String currentStatus = vehicle.status;
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Status - ${vehicle.registrationNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new status:'),
              const SizedBox(height: 16),
              ...['active', 'maintenance', 'inactive'].map((status) => 
                RadioListTile<String>(
                  title: Text(status.toUpperCase()),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus != currentStatus
                  ? () => _updateVehicleStatus(vehicle, selectedStatus)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateVehicleStatus(VehicleModel vehicle, String newStatus) async {
    try {
      await SupabaseService.updateVehicleStatus(vehicle.id, newStatus);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vehicle.registrationNumber} status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVehicleDetails(VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle.registrationNumber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${vehicle.vehicleType}'),
            Text('Capacity: ${vehicle.capacity}'),
            Text('Status: ${vehicle.status}'),
            Text('Driver ID: ${vehicle.driverId ?? 'Not assigned'}'),
            Text('Created: ${vehicle.createdAt.toString().split(' ')[0]}'),
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

  void _showDriverDetails(DriverModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('License: ${driver.licenseNumber}'),
            Text('Phone: ${driver.phoneNumber}'),
            Text('Email: ${driver.email}'),
            Text('Status: ${driver.status}'),
            Text('Address: ${driver.address}'),
            Text('Created: ${driver.createdAt.toString().split(' ')[0]}'),
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
}
