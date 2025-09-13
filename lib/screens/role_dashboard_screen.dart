import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_email_screen.dart';
import 'profile_setup_screen.dart';
import 'admin_dashboard_screen.dart';
import 'driver_dashboard_screen.dart';
import 'trip_manager_dashboard_screen.dart';
import 'accountant_dashboard_screen.dart';
import 'pump_partner_dashboard_screen.dart';

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
        // Return the new AccountantDashboardScreen directly
        return AccountantDashboardScreen(user: widget.user);
      case UserRole.pumpPartner:
        // Return the new PumpPartnerDashboardScreen directly
        return PumpPartnerDashboardScreen(user: widget.user);
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
      bottomNavigationBar: (widget.user.role == UserRole.admin || widget.user.role == UserRole.driver || 
          widget.user.role == UserRole.tripManager || widget.user.role == UserRole.accountant ||
          widget.user.role == UserRole.pumpPartner)
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
}
