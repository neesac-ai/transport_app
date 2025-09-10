import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/services/supabase_service.dart';
import 'admin_approval_screen.dart';
import 'admin_fleet_overview_screen.dart';
import 'admin_users_management_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardOverviewScreen extends StatefulWidget {
  const AdminDashboardOverviewScreen({super.key});

  @override
  State<AdminDashboardOverviewScreen> createState() => _AdminDashboardOverviewScreenState();
}

class _AdminDashboardOverviewScreenState extends State<AdminDashboardOverviewScreen> {
  bool _isLoading = true;
  int _pendingApprovals = 0;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalVehicles = 0;
  int _activeVehicles = 0;
  int _maintenanceVehicles = 0;
  int _activeDrivers = 0;
  String _recentActivity = '';

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
      // Load pending approvals
      final pendingUsers = await SupabaseService.getPendingUsers();
      _pendingApprovals = pendingUsers.length;

      // Load all users
      final allUsers = await SupabaseService.getAllUsers();
      _totalUsers = allUsers.length;
      _activeUsers = allUsers.where((user) => user.approvalStatus.name == 'approved').length;

      // Load vehicles
      final vehicles = await SupabaseService.getVehicles();
      _totalVehicles = vehicles.length;
      _activeVehicles = vehicles.where((v) => v.status == 'active').length;
      _maintenanceVehicles = vehicles.where((v) => v.status == 'maintenance').length;

      // Load drivers
      final drivers = await SupabaseService.getDrivers();
      _activeDrivers = drivers.where((d) => d.status == 'active').length;

      // Generate recent activity summary
      _generateRecentActivity();

    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateRecentActivity() {
    final activities = <String>[];
    
    if (_pendingApprovals > 0) {
      activities.add('$_pendingApprovals user(s) waiting for approval');
    }
    
    if (_activeVehicles > 0) {
      activities.add('$_activeVehicles active vehicles');
    }
    
    if (_activeDrivers > 0) {
      activities.add('$_activeDrivers active drivers');
    }
    
    _recentActivity = activities.isNotEmpty 
        ? activities.join(', ')
        : 'No recent activity';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
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
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildPendingApprovalsCard(),
                    const SizedBox(height: 16),
                    _buildFleetStatusCard(),
                    const SizedBox(height: 16),
                    _buildUserSummaryCard(),
                    const SizedBox(height: 16),
                    _buildRecentActivityCard(),
                    const SizedBox(height: 16),
                    _buildSystemStatusCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
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
            'Welcome, Admin!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System Overview - Last updated: ${DateTime.now().toString().split('.')[0]}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalsCard() {
    return _buildOverviewCard(
      title: 'Pending Approvals',
      icon: Icons.pending_actions,
      color: Colors.orange,
      value: '$_pendingApprovals users waiting',
      actions: [
        _buildActionButton(
          'View All',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminApprovalScreen()),
          ),
        ),
        if (_pendingApprovals > 0)
          _buildActionButton(
            'Quick Approve',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminApprovalScreen()),
            ),
            isPrimary: true,
          ),
      ],
    );
  }

  Widget _buildFleetStatusCard() {
    return _buildOverviewCard(
      title: 'Fleet Status',
      icon: Icons.local_shipping,
      color: AppColors.primaryBlue,
      value: '$_activeVehicles Active, $_maintenanceVehicles Maintenance, ${_totalVehicles - _activeVehicles - _maintenanceVehicles} Inactive',
      actions: [
        _buildActionButton(
          'Manage Fleet',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminFleetOverviewScreen()),
          ),
        ),
        _buildActionButton(
          'Add Vehicle',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminFleetOverviewScreen()),
          ),
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildUserSummaryCard() {
    return _buildOverviewCard(
      title: 'User Summary',
      icon: Icons.people,
      color: Colors.green,
      value: '$_totalUsers Total, $_activeUsers Active, $_pendingApprovals Pending',
      actions: [
        _buildActionButton(
          'Manage Users',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminUsersManagementScreen()),
          ),
        ),
        _buildActionButton(
          'View All Users',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminUsersManagementScreen()),
          ),
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return _buildOverviewCard(
      title: 'Recent Activity',
      icon: Icons.timeline,
      color: Colors.purple,
      value: _recentActivity,
      actions: [
        _buildActionButton(
          'View Reports',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
          ),
        ),
        _buildActionButton(
          'View All Activity',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
          ),
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildSystemStatusCard() {
    return _buildOverviewCard(
      title: 'System Status',
      icon: Icons.settings,
      color: Colors.blue,
      value: 'All systems operational',
      actions: [
        _buildActionButton(
          'Settings',
          () {
            // TODO: Navigate to settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings coming soon!')),
            );
          },
        ),
        _buildActionButton(
          'Maintenance',
          () {
            // TODO: Navigate to maintenance
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maintenance panel coming soon!')),
            );
          },
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required List<Widget> actions,
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
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, {bool isPrimary = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? AppColors.primaryBlue : Colors.grey[200],
            foregroundColor: isPrimary ? Colors.white : Colors.black87,
            elevation: isPrimary ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
