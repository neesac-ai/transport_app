import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/services/supabase_service.dart';
import 'package:version1/models/vehicle_model.dart';
import 'package:version1/models/driver_model.dart';
import 'add_vehicle_screen.dart';

class AdminFleetManagementScreen extends StatefulWidget {
  const AdminFleetManagementScreen({super.key});

  @override
  State<AdminFleetManagementScreen> createState() => _AdminFleetManagementScreenState();
}

class _AdminFleetManagementScreenState extends State<AdminFleetManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<VehicleModel> _vehicles = [];
  List<DriverModel> _drivers = [];

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
      });
    } catch (e) {
      print('Error loading fleet data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading fleet data: $e'),
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
        title: const Text('Fleet'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Vehicles', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Drivers', icon: Icon(Icons.person)),
          ],
        ),
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

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        if (_tabController.index == 1) { // Drivers tab
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

  Widget _buildVehiclesTab() {
    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to get started',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
                    color: _getStatusColor(vehicle.status),
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
    );
  }

  Widget _buildDriversTab() {
    if (_drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No drivers found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drivers will appear here after they register',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
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
                Text('Phone: ${driver.phoneNumber}'),
                Text('License: ${driver.licenseNumber}'),
                Text('Status: ${driver.status}'),
                if (driver.licenseExpiry != null)
                  Text('License Expiry: ${driver.licenseExpiry.toString().split(' ')[0]}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(driver.status),
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
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
            Text('Phone: ${driver.phoneNumber}'),
            Text('Email: ${driver.email}'),
            Text('Address: ${driver.address}'),
            Text('License Number: ${driver.licenseNumber}'),
            if (driver.licenseExpiry != null)
              Text('License Expiry: ${driver.licenseExpiry.toString().split(' ')[0]}'),
            Text('Status: ${driver.status}'),
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

  void _navigateToAddVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
    ).then((_) {
      _loadData(); // Refresh data after adding vehicle
    });
  }
}
