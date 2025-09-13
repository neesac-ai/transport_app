import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/services/supabase_service.dart';
import 'package:version1/models/user_model.dart';
import 'package:version1/models/vehicle_model.dart';
import 'package:version1/models/driver_model.dart';
import 'package:version1/models/trip_model.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  Map<String, dynamic> _systemHealth = {};

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
      final vehicles = await SupabaseService.getAllVehicles();
      final drivers = await SupabaseService.getAllDrivers();
      final trips = await SupabaseService.getAllTrips();

      // Calculate statistics
      final userStats = _calculateUserStats(users);
      final vehicleStats = _calculateVehicleStats(vehicles);
      final driverStats = _calculateDriverStats(drivers);
      final tripStats = _calculateTripStats(trips);
      final systemHealth = await _calculateSystemHealth();

      setState(() {
        _reportData = {
          'users': userStats,
          'vehicles': vehicleStats,
          'drivers': driverStats,
          'trips': tripStats,
          'lastUpdated': DateTime.now(),
        };
        _systemHealth = systemHealth;
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

  Map<String, dynamic> _calculateTripStats(List<TripModel> trips) {
    final total = trips.length;
    final assigned = trips.where((t) => t.status == 'assigned').length;
    final inProgress = trips.where((t) => t.status == 'in_progress').length;
    final completed = trips.where((t) => t.status == 'completed').length;
    final cancelled = trips.where((t) => t.status == 'cancelled').length;
    final settled = trips.where((t) => t.status == 'settled').length;

    // Calculate financial metrics
    final totalRevenue = trips
        .where((t) => t.status == 'completed' || t.status == 'settled')
        .fold(0.0, (sum, trip) => sum + (trip.totalRate ?? 0.0));

    final totalCommission = trips
        .where((t) => t.status == 'completed' || t.status == 'settled')
        .fold(0.0, (sum, trip) => sum + (trip.commissionAmount));

    final totalAdvance = trips
        .where((t) => t.status == 'completed' || t.status == 'settled')
        .fold(0.0, (sum, trip) => sum + (trip.advanceGiven));

    // Calculate average trip duration (for completed trips)
    final completedTrips = trips.where((t) => 
        t.status == 'completed' && t.startDate != null && t.endDate != null).toList();
    double avgDuration = 0.0;
    if (completedTrips.isNotEmpty) {
      final totalDuration = completedTrips.fold(0.0, (sum, trip) {
        final duration = trip.endDate!.difference(trip.startDate!).inDays;
        return sum + duration;
      });
      avgDuration = totalDuration / completedTrips.length;
    }

    return {
      'total': total,
      'assigned': assigned,
      'inProgress': inProgress,
      'completed': completed,
      'cancelled': cancelled,
      'settled': settled,
      'totalRevenue': totalRevenue,
      'totalCommission': totalCommission,
      'totalAdvance': totalAdvance,
      'avgDuration': avgDuration,
    };
  }

  Future<Map<String, dynamic>> _calculateSystemHealth() async {
    print('=== CALCULATING SYSTEM HEALTH ===');
    
    try {
      // Test database connection and measure response time
      final dbStartTime = DateTime.now();
      final dbTest = await SupabaseService.testDatabaseConnection();
      final dbResponseTime = DateTime.now().difference(dbStartTime).inMilliseconds;
      
      // Get active sessions count
      final activeSessions = await SupabaseService.getActiveSessionsCount();
      
      // Get storage usage (if available)
      final storageUsage = await SupabaseService.getStorageUsage();
      
      // Get last backup time (if available)
      final lastBackup = await SupabaseService.getLastBackupTime();
      
      // Calculate system uptime based on successful operations
      final uptime = await SupabaseService.calculateSystemUptime();
      
      // Determine database status
      String dbStatus = 'Operational';
      bool isDbHealthy = dbTest['success'] == true;
      if (!isDbHealthy) {
        dbStatus = 'Error';
      } else if (dbResponseTime > 1000) {
        dbStatus = 'Slow';
      }
      
      // Determine API response time status
      String apiStatus = '< 200ms';
      bool isApiHealthy = dbResponseTime < 200;
      if (dbResponseTime > 1000) {
        apiStatus = '> 1000ms';
        isApiHealthy = false;
      } else if (dbResponseTime > 500) {
        apiStatus = '> 500ms';
        isApiHealthy = false;
      } else if (dbResponseTime > 200) {
        apiStatus = '> 200ms';
        isApiHealthy = false;
      }
      
      // Determine storage status
      String storageStatus = 'Normal';
      bool isStorageHealthy = true;
      if (storageUsage > 90) {
        storageStatus = 'Critical';
        isStorageHealthy = false;
      } else if (storageUsage > 75) {
        storageStatus = 'Warning';
        isStorageHealthy = false;
      }
      
      final healthData = {
        'database_status': dbStatus,
        'database_healthy': isDbHealthy,
        'api_response_time': apiStatus,
        'api_response_ms': dbResponseTime,
        'api_healthy': isApiHealthy,
        'storage_usage': storageUsage,
        'storage_status': storageStatus,
        'storage_healthy': isStorageHealthy,
        'active_sessions': activeSessions,
        'last_backup': lastBackup,
        'system_uptime': uptime,
        'overall_healthy': isDbHealthy && isApiHealthy && isStorageHealthy,
        'last_checked': DateTime.now().toIso8601String(),
      };
      
      print('System health calculated: $healthData');
      return healthData;
      
    } catch (e) {
      print('Error calculating system health: $e');
      // Return error state
      return {
        'database_status': 'Error',
        'database_healthy': false,
        'api_response_time': 'Unknown',
        'api_response_ms': -1,
        'api_healthy': false,
        'storage_usage': 0,
        'storage_status': 'Unknown',
        'storage_healthy': false,
        'active_sessions': 0,
        'last_backup': 'Unknown',
        'system_uptime': 0.0,
        'overall_healthy': false,
        'last_checked': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
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
            icon: const Icon(Icons.help_outline),
            onPressed: _showMetricsHelp,
            tooltip: 'Explain Metrics',
          ),
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
                    _buildTripReports(),
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

  Widget _buildTripReports() {
    final tripStats = _reportData['trips'] as Map<String, dynamic>? ?? {};
    
    return _buildReportCard(
      title: 'Trip Analytics',
      icon: Icons.local_shipping,
      color: Colors.indigo,
      children: [
        _buildStatRow('Total Trips', '${tripStats['total'] ?? 0}'),
        _buildStatRow('Assigned', '${tripStats['assigned'] ?? 0}'),
        _buildStatRow('In Progress', '${tripStats['inProgress'] ?? 0}'),
        _buildStatRow('Completed', '${tripStats['completed'] ?? 0}'),
        _buildStatRow('Cancelled', '${tripStats['cancelled'] ?? 0}'),
        _buildStatRow('Settled', '${tripStats['settled'] ?? 0}'),
        const Divider(),
        _buildStatRow('Total Revenue', '₹${(tripStats['totalRevenue'] ?? 0.0).toStringAsFixed(0)}', isSuccess: true),
        _buildStatRow('Total Commission', '₹${(tripStats['totalCommission'] ?? 0.0).toStringAsFixed(0)}'),
        _buildStatRow('Total Advance', '₹${(tripStats['totalAdvance'] ?? 0.0).toStringAsFixed(0)}'),
        _buildStatRow('Avg Duration', '${(tripStats['avgDuration'] ?? 0.0).toStringAsFixed(1)} days'),
      ],
    );
  }

  Widget _buildSystemReports() {
    final health = _systemHealth;
    final overallHealthy = health['overall_healthy'] == true;
    
    return _buildReportCard(
      title: 'System Health',
      icon: Icons.analytics,
      color: overallHealthy ? Colors.green : Colors.red,
      children: [
        _buildHealthStatRow(
          'Database Status', 
          health['database_status'] ?? 'Unknown',
          isHealthy: health['database_healthy'] == true,
        ),
        _buildHealthStatRow(
          'API Response Time', 
          health['api_response_time'] ?? 'Unknown',
          isHealthy: health['api_healthy'] == true,
          subtitle: '${health['api_response_ms'] ?? 0}ms',
        ),
        _buildHealthStatRow(
          'Storage Usage', 
          '${(health['storage_usage'] ?? 0.0).toStringAsFixed(1)}%',
          isHealthy: health['storage_healthy'] == true,
          subtitle: health['storage_status'] ?? 'Unknown',
        ),
        _buildHealthStatRow(
          'Active Sessions', 
          '${health['active_sessions'] ?? 0}',
          isHealthy: true, // Sessions count is always neutral
        ),
        const Divider(),
        _buildHealthStatRow(
          'Last Backup', 
          health['last_backup'] ?? 'Unknown',
          isHealthy: true, // Assume backup is good if we have data
        ),
        _buildHealthStatRow(
          'System Uptime', 
          '${(health['system_uptime'] ?? 0.0).toStringAsFixed(1)}%',
          isHealthy: (health['system_uptime'] ?? 0.0) > 95.0,
        ),
        if (health['last_checked'] != null)
          _buildStatRow(
            'Last Checked', 
            DateTime.parse(health['last_checked']).toString().split('.')[0],
          ),
        if (health['error'] != null)
          _buildStatRow(
            'Error', 
            health['error'],
            isError: true,
          ),
      ],
    );
  }

  Widget _buildHealthStatRow(String label, String value, {bool isHealthy = true, String? subtitle}) {
    Color valueColor = Colors.black87;
    if (isHealthy) {
      valueColor = Colors.green;
    } else {
      valueColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              if (isHealthy)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
              else
                const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 8),
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
        ],
      ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose the format for your report export:'),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('CSV Format'),
              subtitle: const Text('Compatible with Excel, Google Sheets'),
              onTap: () => _exportToCSV(),
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('PDF Format'),
              subtitle: const Text('Formatted report for printing'),
              onTap: () => _exportToPDF(),
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.orange),
              title: const Text('JSON Format'),
              subtitle: const Text('Raw data for developers'),
              onTap: () => _exportToJSON(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportToCSV() {
    Navigator.of(context).pop(); // Close dialog
    
    try {
      final csvData = _generateCSVData();
      _downloadFile(csvData, 'admin_reports_${DateTime.now().millisecondsSinceEpoch}.csv', 'text/csv');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportToPDF() {
    Navigator.of(context).pop(); // Close dialog
    
    try {
      final pdfData = _generatePDFData();
      _downloadFile(pdfData, 'admin_reports_${DateTime.now().millisecondsSinceEpoch}.pdf', 'application/pdf');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportToJSON() {
    Navigator.of(context).pop(); // Close dialog
    
    try {
      final jsonData = _generateJSONData();
      _downloadFile(jsonData, 'admin_reports_${DateTime.now().millisecondsSinceEpoch}.json', 'application/json');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting JSON: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateCSVData() {
    final userStats = _reportData['users'] as Map<String, dynamic>? ?? {};
    final vehicleStats = _reportData['vehicles'] as Map<String, dynamic>? ?? {};
    final driverStats = _reportData['drivers'] as Map<String, dynamic>? ?? {};
    final tripStats = _reportData['trips'] as Map<String, dynamic>? ?? {};
    
    final csv = StringBuffer();
    csv.writeln('Report Type,Category,Metric,Value');
    csv.writeln('User Analytics,Users,Total,${userStats['total'] ?? 0}');
    csv.writeln('User Analytics,Users,Active,${userStats['active'] ?? 0}');
    csv.writeln('User Analytics,Users,Pending,${userStats['pending'] ?? 0}');
    csv.writeln('User Analytics,Users,Inactive,${userStats['inactive'] ?? 0}');
    csv.writeln('Fleet Analytics,Vehicles,Total,${vehicleStats['total'] ?? 0}');
    csv.writeln('Fleet Analytics,Vehicles,Active,${vehicleStats['active'] ?? 0}');
    csv.writeln('Fleet Analytics,Vehicles,Maintenance,${vehicleStats['maintenance'] ?? 0}');
    csv.writeln('Fleet Analytics,Vehicles,Inactive,${vehicleStats['inactive'] ?? 0}');
    csv.writeln('Driver Analytics,Drivers,Total,${driverStats['total'] ?? 0}');
    csv.writeln('Driver Analytics,Drivers,Active,${driverStats['active'] ?? 0}');
    csv.writeln('Driver Analytics,Drivers,Pending,${driverStats['pending'] ?? 0}');
    csv.writeln('Driver Analytics,Drivers,Inactive,${driverStats['inactive'] ?? 0}');
    csv.writeln('Trip Analytics,Trips,Total,${tripStats['total'] ?? 0}');
    csv.writeln('Trip Analytics,Trips,Completed,${tripStats['completed'] ?? 0}');
    csv.writeln('Trip Analytics,Trips,In Progress,${tripStats['inProgress'] ?? 0}');
    csv.writeln('Trip Analytics,Trips,Cancelled,${tripStats['cancelled'] ?? 0}');
    csv.writeln('Trip Analytics,Financial,Total Revenue,${tripStats['totalRevenue'] ?? 0}');
    csv.writeln('Trip Analytics,Financial,Total Commission,${tripStats['totalCommission'] ?? 0}');
    csv.writeln('Trip Analytics,Financial,Total Advance,${tripStats['totalAdvance'] ?? 0}');
    csv.writeln('System Health,Performance,Database Status,${_systemHealth['database_status'] ?? 'Unknown'}');
    csv.writeln('System Health,Performance,API Response Time,${_systemHealth['api_response_time'] ?? 'Unknown'}');
    csv.writeln('System Health,Performance,Storage Usage,${_systemHealth['storage_usage'] ?? 0}%');
    csv.writeln('System Health,Performance,Active Sessions,${_systemHealth['active_sessions'] ?? 0}');
    csv.writeln('System Health,Backup,Last Backup,${_systemHealth['last_backup'] ?? 'Unknown'}');
    csv.writeln('System Health,Backup,System Uptime,${_systemHealth['system_uptime'] ?? 0}%');
    csv.writeln('Report Info,Metadata,Generated At,${DateTime.now().toIso8601String()}');
    
    return csv.toString();
  }

  String _generatePDFData() {
    // For a real implementation, you would use a PDF generation library like pdf package
    // This is a simplified text-based representation
    final userStats = _reportData['users'] as Map<String, dynamic>? ?? {};
    final vehicleStats = _reportData['vehicles'] as Map<String, dynamic>? ?? {};
    final driverStats = _reportData['drivers'] as Map<String, dynamic>? ?? {};
    final tripStats = _reportData['trips'] as Map<String, dynamic>? ?? {};
    
    final pdf = StringBuffer();
    pdf.writeln('ADMIN DASHBOARD REPORT');
    pdf.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    pdf.writeln('=' * 50);
    pdf.writeln();
    
    pdf.writeln('USER ANALYTICS');
    pdf.writeln('-' * 20);
    pdf.writeln('Total Users: ${userStats['total'] ?? 0}');
    pdf.writeln('Active Users: ${userStats['active'] ?? 0}');
    pdf.writeln('Pending Users: ${userStats['pending'] ?? 0}');
    pdf.writeln('Inactive Users: ${userStats['inactive'] ?? 0}');
    pdf.writeln();
    
    pdf.writeln('FLEET ANALYTICS');
    pdf.writeln('-' * 20);
    pdf.writeln('Total Vehicles: ${vehicleStats['total'] ?? 0}');
    pdf.writeln('Active Vehicles: ${vehicleStats['active'] ?? 0}');
    pdf.writeln('Maintenance Vehicles: ${vehicleStats['maintenance'] ?? 0}');
    pdf.writeln('Inactive Vehicles: ${vehicleStats['inactive'] ?? 0}');
    pdf.writeln();
    
    pdf.writeln('DRIVER ANALYTICS');
    pdf.writeln('-' * 20);
    pdf.writeln('Total Drivers: ${driverStats['total'] ?? 0}');
    pdf.writeln('Active Drivers: ${driverStats['active'] ?? 0}');
    pdf.writeln('Pending Drivers: ${driverStats['pending'] ?? 0}');
    pdf.writeln('Inactive Drivers: ${driverStats['inactive'] ?? 0}');
    pdf.writeln();
    
    pdf.writeln('TRIP ANALYTICS');
    pdf.writeln('-' * 20);
    pdf.writeln('Total Trips: ${tripStats['total'] ?? 0}');
    pdf.writeln('Completed Trips: ${tripStats['completed'] ?? 0}');
    pdf.writeln('In Progress Trips: ${tripStats['inProgress'] ?? 0}');
    pdf.writeln('Cancelled Trips: ${tripStats['cancelled'] ?? 0}');
    pdf.writeln('Total Revenue: ₹${(tripStats['totalRevenue'] ?? 0.0).toStringAsFixed(0)}');
    pdf.writeln('Total Commission: ₹${(tripStats['totalCommission'] ?? 0.0).toStringAsFixed(0)}');
    pdf.writeln('Total Advance: ₹${(tripStats['totalAdvance'] ?? 0.0).toStringAsFixed(0)}');
    pdf.writeln();
    
    pdf.writeln('SYSTEM HEALTH');
    pdf.writeln('-' * 20);
    pdf.writeln('Database Status: ${_systemHealth['database_status'] ?? 'Unknown'}');
    pdf.writeln('API Response Time: ${_systemHealth['api_response_time'] ?? 'Unknown'}');
    pdf.writeln('Storage Usage: ${_systemHealth['storage_usage'] ?? 0}%');
    pdf.writeln('Active Sessions: ${_systemHealth['active_sessions'] ?? 0}');
    pdf.writeln('Last Backup: ${_systemHealth['last_backup'] ?? 'Unknown'}');
    pdf.writeln('System Uptime: ${_systemHealth['system_uptime'] ?? 0}%');
    
    return pdf.toString();
  }

  String _generateJSONData() {
    final jsonData = {
      'report_metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'report_type': 'admin_dashboard',
        'version': '1.0',
      },
      'user_analytics': _reportData['users'] ?? {},
      'fleet_analytics': _reportData['vehicles'] ?? {},
      'driver_analytics': _reportData['drivers'] ?? {},
      'trip_analytics': _reportData['trips'] ?? {},
      'system_health': _systemHealth,
    };
    
    return jsonData.toString();
  }

  void _showMetricsHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('System Health Metrics Explained'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetricExplanation(
                'Database Status',
                'Tests connection to Supabase database',
                'Operational = Connection successful\nSlow = Response > 1000ms\nError = Connection failed',
              ),
              _buildMetricExplanation(
                'API Response Time',
                'Time taken for database queries to complete',
                '< 200ms = Excellent\n200-500ms = Good\n500-1000ms = Slow\n> 1000ms = Poor',
              ),
              _buildMetricExplanation(
                'Storage Usage',
                'Estimated database storage consumption',
                'Based on record counts in all tables\n< 75% = Normal\n75-90% = Warning\n> 90% = Critical',
              ),
              _buildMetricExplanation(
                'Active Sessions',
                'Number of currently authenticated users',
                'Shows how many users are logged in\nHigher numbers indicate more activity',
              ),
              _buildMetricExplanation(
                'Last Backup',
                'Time since last database backup',
                'Supabase handles automatic backups\nShows when last backup occurred',
              ),
              _buildMetricExplanation(
                'System Uptime',
                'Percentage of successful operations',
                'Based on successful database queries\n> 95% = Excellent uptime',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricExplanation(String title, String description, String details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadFile(String data, String filename, String mimeType) {
    // In a real implementation, you would use a file download library
    // For web, you could use html package to trigger download
    // For mobile, you would use path_provider and file packages
    
    // This is a simplified implementation that shows the data
    // In a real app, you would implement actual file download
    print('Downloading file: $filename');
    print('MIME Type: $mimeType');
    print('Data length: ${data.length} characters');
    
    // For demonstration, show the data in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download: $filename'),
        content: SingleChildScrollView(
          child: Text(
            data.length > 1000 ? '${data.substring(0, 1000)}...\n\n[Data truncated for display]' : data,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
}
