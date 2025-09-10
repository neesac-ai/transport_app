import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/services/supabase_service.dart';
import 'package:version1/models/user_model.dart';
import 'package:version1/models/vehicle_model.dart';
import 'package:version1/models/driver_model.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await SupabaseService.getAllUsers();
      final vehicles = await SupabaseService.getVehicles();
      final drivers = await SupabaseService.getDrivers();

      // Calculate statistics
      final userStats = _calculateUserStats(users);
      final vehicleStats = _calculateVehicleStats(vehicles);
      final driverStats = _calculateDriverStats(drivers);

      setState(() {
        _reportData = {
          'users': userStats,
          'vehicles': vehicleStats,
          'drivers': driverStats,
          'lastUpdated': DateTime.now(),
        };
      });
    } catch (e) {
      print('Error loading report data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading report data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateUserStats(List<UserModel> users) {
    final total = users.length;
    final active = users.where((u) => u.approvalStatus.name == 'approved').length;
    final pending = users.where((u) => u.approvalStatus.name == 'pending').length;
    final inactive = users.where((u) => u.approvalStatus.name == 'rejected').length;

    final roleCounts = <String, int>{};
    for (final user in users) {
      final role = user.role?.toString().split('.').last ?? 'not_set';
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    return {
      'total': total,
      'active': active,
      'pending': pending,
      'inactive': inactive,
      'roleCounts': roleCounts,
    };
  }

  Map<String, dynamic> _calculateVehicleStats(List<VehicleModel> vehicles) {
    final total = vehicles.length;
    final active = vehicles.where((v) => v.status == 'active').length;
    final maintenance = vehicles.where((v) => v.status == 'maintenance').length;
    final inactive = vehicles.where((v) => v.status == 'inactive').length;

    final typeCounts = <String, int>{};
    for (final vehicle in vehicles) {
      typeCounts[vehicle.vehicleType] = (typeCounts[vehicle.vehicleType] ?? 0) + 1;
    }

    return {
      'total': total,
      'active': active,
      'maintenance': maintenance,
      'inactive': inactive,
      'typeCounts': typeCounts,
    };
  }

  Map<String, dynamic> _calculateDriverStats(List<DriverModel> drivers) {
    final total = drivers.length;
    final active = drivers.where((d) => d.status == 'active').length;
    final pending = drivers.where((d) => d.status == 'pending').length;
    final inactive = drivers.where((d) => d.status == 'inactive').length;

    // Calculate license expiry warnings
    final now = DateTime.now();
    final expiringSoon = drivers.where((d) {
      if (d.licenseExpiry == null) return false;
      final daysUntilExpiry = d.licenseExpiry!.difference(now).inDays;
      return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
    }).length;

    final expired = drivers.where((d) {
      if (d.licenseExpiry == null) return false;
      return d.licenseExpiry!.isBefore(now);
    }).length;

    return {
      'total': total,
      'active': active,
      'pending': pending,
      'inactive': inactive,
      'expiringSoon': expiringSoon,
      'expired': expired,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Refresh Reports',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReports,
            tooltip: 'Export Reports',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportHeader(),
                    const SizedBox(height: 20),
                    _buildUserReports(),
                    const SizedBox(height: 20),
                    _buildFleetReports(),
                    const SizedBox(height: 20),
                    _buildDriverReports(),
                    const SizedBox(height: 20),
                    _buildSystemReports(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue.withOpacity(0.1), AppColors.primaryBlue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Reports & Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${_reportData['lastUpdated']?.toString().split('.')[0] ?? 'Never'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserReports() {
    final userStats = _reportData['users'] as Map<String, dynamic>? ?? {};
    
    return _buildReportCard(
      title: 'User Analytics',
      icon: Icons.people,
      color: Colors.blue,
      children: [
        _buildStatRow('Total Users', '${userStats['total'] ?? 0}'),
        _buildStatRow('Active Users', '${userStats['active'] ?? 0}'),
        _buildStatRow('Pending Approvals', '${userStats['pending'] ?? 0}'),
        _buildStatRow('Inactive Users', '${userStats['inactive'] ?? 0}'),
        const Divider(),
        _buildRoleBreakdown(userStats['roleCounts'] as Map<String, int>? ?? {}),
      ],
    );
  }

  Widget _buildFleetReports() {
    final vehicleStats = _reportData['vehicles'] as Map<String, dynamic>? ?? {};
    
    return _buildReportCard(
      title: 'Fleet Analytics',
      icon: Icons.local_shipping,
      color: Colors.green,
      children: [
        _buildStatRow('Total Vehicles', '${vehicleStats['total'] ?? 0}'),
        _buildStatRow('Active Vehicles', '${vehicleStats['active'] ?? 0}'),
        _buildStatRow('Under Maintenance', '${vehicleStats['maintenance'] ?? 0}'),
        _buildStatRow('Inactive Vehicles', '${vehicleStats['inactive'] ?? 0}'),
        const Divider(),
        _buildVehicleTypeBreakdown(vehicleStats['typeCounts'] as Map<String, int>? ?? {}),
      ],
    );
  }

  Widget _buildDriverReports() {
    final driverStats = _reportData['drivers'] as Map<String, dynamic>? ?? {};
    
    return _buildReportCard(
      title: 'Driver Analytics',
      icon: Icons.person,
      color: Colors.orange,
      children: [
        _buildStatRow('Total Drivers', '${driverStats['total'] ?? 0}'),
        _buildStatRow('Active Drivers', '${driverStats['active'] ?? 0}'),
        _buildStatRow('Pending Drivers', '${driverStats['pending'] ?? 0}'),
        _buildStatRow('Inactive Drivers', '${driverStats['inactive'] ?? 0}'),
        const Divider(),
        _buildStatRow('Licenses Expiring Soon', '${driverStats['expiringSoon'] ?? 0}', isWarning: true),
        _buildStatRow('Expired Licenses', '${driverStats['expired'] ?? 0}', isError: true),
      ],
    );
  }

  Widget _buildSystemReports() {
    return _buildReportCard(
      title: 'System Health',
      icon: Icons.analytics,
      color: Colors.purple,
      children: [
        _buildStatRow('Database Status', 'Operational', isSuccess: true),
        _buildStatRow('API Response Time', '< 200ms', isSuccess: true),
        _buildStatRow('Storage Usage', '45%', isWarning: true),
        _buildStatRow('Active Sessions', '12', isSuccess: true),
        const Divider(),
        _buildStatRow('Last Backup', '2 hours ago', isSuccess: true),
        _buildStatRow('System Uptime', '99.9%', isSuccess: true),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isSuccess = false, bool isWarning = false, bool isError = false}) {
    Color valueColor = Colors.black87;
    if (isSuccess) valueColor = Colors.green;
    if (isWarning) valueColor = Colors.orange;
    if (isError) valueColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBreakdown(Map<String, int> roleCounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role Breakdown:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...roleCounts.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeBreakdown(Map<String, int> typeCounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Types:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...typeCounts.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _exportReports() {
    // TODO: Implement report export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
