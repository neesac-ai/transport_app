import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_email_screen.dart';
import 'profile_setup_screen.dart';
import 'admin_dashboard_screen.dart';
import 'driver_dashboard_screen.dart';
import 'trip_manager_dashboard_screen.dart';

class RoleDashboardScreen extends StatefulWidget {
  final UserModel user;

  const RoleDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  int _selectedIndex = 0;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('phoneNumber');
    await prefs.remove('userData');
    await prefs.remove('profileCompleted');
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthEmailScreen()),
    );
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    if (widget.user.role == null) {
      // If no role is set, show basic navigation
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
    
    switch (widget.user.role!) {
      case UserRole.admin:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Fleet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ];
      case UserRole.tripManager:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Trips',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Fleet',
          ),
        ];
      case UserRole.driver:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'My Trips',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Odometer',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Silak',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Issues',
          ),
        ];
      case UserRole.accountant:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Expenses',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Advances',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ];
      case UserRole.pumpPartner:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Diesel',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Photos',
          ),
        ];
    }
  }

  Widget _getCurrentScreen() {
    if (widget.user.role == null) {
      return _buildNoRoleScreen();
    }
    
    switch (widget.user.role!) {
      case UserRole.admin:
        // For admin users, return the new AdminDashboardScreen directly
        // This will handle its own navigation and layout
        return const AdminDashboardScreen();
      case UserRole.tripManager:
        // For trip manager users, return the new TripManagerDashboardScreen directly
        return TripManagerDashboardScreen(user: widget.user);
      case UserRole.driver:
        // For driver users, return the new DriverDashboardScreen directly
        // This will handle its own navigation and layout
        return DriverDashboardScreen(user: widget.user);
      case UserRole.accountant:
        return _buildAccountantDashboard();
      case UserRole.pumpPartner:
        return _buildPumpPartnerDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.role?.displayName ?? 'User'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: (widget.user.role == UserRole.admin || widget.user.role == UserRole.driver || widget.user.role == UserRole.tripManager)
          ? null // Admin, Driver, and Trip Manager users use their own dashboard screens which have their own navigation
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: _getBottomNavItems(),
            ),
    );
  }




  Widget _buildAccountantDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          const Text(
            'Financial Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  icon: Icons.receipt,
                  title: 'Enter Expenses',
                  color: Colors.green,
                  onTap: () => _showComingSoon('Expense Entry'),
                ),
                _buildActionCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Track Advances',
                  color: Colors.blue,
                  onTap: () => _showComingSoon('Advance Tracking'),
                ),
                _buildActionCard(
                  icon: Icons.local_gas_station,
                  title: 'Diesel Reconciliation',
                  color: Colors.orange,
                  onTap: () => _showComingSoon('Diesel Reconciliation'),
                ),
                _buildActionCard(
                  icon: Icons.analytics,
                  title: 'Financial Reports',
                  color: Colors.purple,
                  onTap: () => _showComingSoon('Financial Reports'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpPartnerDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          const Text(
            'Pump Operations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  icon: Icons.local_gas_station,
                  title: 'Upload Diesel Data',
                  color: Colors.green,
                  onTap: () => _showComingSoon('Diesel Data Upload'),
                ),
                _buildActionCard(
                  icon: Icons.camera_alt,
                  title: 'Vehicle Photos',
                  color: Colors.blue,
                  onTap: () => _showComingSoon('Vehicle Photos'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${widget.user.name}!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Role: ${widget.user.role?.displayName ?? 'Not Set'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: ${widget.user.phoneNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoRoleScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Profile Incomplete',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Please complete your profile to access the dashboard'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to profile setup
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProfileSetupScreen(
                    phoneNumber: '',
                    email: widget.user.email,
                  ),
                ),
              );
            },
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}
