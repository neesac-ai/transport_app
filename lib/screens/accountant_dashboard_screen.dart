import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/models/user_model.dart';
import 'package:version1/models/expense_model.dart';
import 'package:version1/models/advance_model.dart';
import 'package:version1/services/supabase_service.dart';
import 'accountant_expense_approval_screen.dart';
import 'accountant_advance_approval_screen.dart';
import 'accountant_profile_screen.dart';

class AccountantDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AccountantDashboardScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<AccountantDashboardScreen> createState() => _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState extends State<AccountantDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  int _pendingExpenses = 0;
  int _pendingAdvances = 0;
  double _totalPendingExpenseAmount = 0;
  double _totalPendingAdvanceAmount = 0;
  List<ExpenseModel> _recentExpenses = [];
  List<AdvanceModel> _recentAdvances = [];

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
      // Load all expenses
      final expenses = await SupabaseService.getAllExpenses();
      final pendingExpenses = expenses.where((e) => e.status == 'pending').toList();
      _pendingExpenses = pendingExpenses.length;
      _totalPendingExpenseAmount = pendingExpenses.fold(0, (sum, expense) => sum + expense.amount);
      _recentExpenses = expenses.take(5).toList();

      // Load all advances
      final advances = await SupabaseService.getAllAdvances();
      final pendingAdvances = advances.where((a) => a.status == 'pending').toList();
      _pendingAdvances = pendingAdvances.length;
      _totalPendingAdvanceAmount = pendingAdvances.fold(0, (sum, advance) => sum + advance.amount);
      _recentAdvances = advances.take(5).toList();

    } catch (e) {
      print('Error loading accountant dashboard data: $e');
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
            icon: Icon(Icons.receipt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Advances',
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
      AccountantExpenseApprovalScreen(user: widget.user),
      AccountantAdvanceApprovalScreen(user: widget.user),
      AccountantProfileScreen(user: widget.user),
    ];
  }

  Widget _buildDashboardTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountant Dashboard'),
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
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentExpensesSection(),
                    const SizedBox(height: 24),
                    _buildRecentAdvancesSection(),
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
              Icons.account_balance_wallet,
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
                  'You have $_pendingExpenses expenses and $_pendingAdvances advances pending approval',
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

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
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
                'Pending Expenses',
                '$_pendingExpenses',
                '₹${_totalPendingExpenseAmount.toStringAsFixed(2)}',
                Icons.receipt,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending Advances',
                '$_pendingAdvances',
                '₹${_totalPendingAdvanceAmount.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, String amount, IconData icon, Color color) {
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
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
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
                'Approve Expenses',
                Icons.receipt,
                Colors.orange,
                () => setState(() => _currentIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Approve Advances',
                Icons.attach_money,
                Colors.green,
                () => setState(() => _currentIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Pending Approvals',
                Icons.pending_actions,
                Colors.amber,
                () {
                  if (_pendingExpenses > 0) {
                    setState(() => _currentIndex = 1);
                  } else if (_pendingAdvances > 0) {
                    setState(() => _currentIndex = 2);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No pending approvals'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Trip-wise View',
                Icons.list_alt,
                Colors.indigo,
                () => _showTripWiseExpensesDialog(),
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

  Widget _buildRecentExpensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentExpenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No recent expenses'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentExpenses.length,
            itemBuilder: (context, index) {
              final expense = _recentExpenses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.receipt, color: Colors.orange.shade700),
                  ),
                  title: Text(expense.description),
                  subtitle: Text('${expense.category} • ${_formatDate(expense.expenseDate)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(expense.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          expense.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(expense.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentAdvancesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Advances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 2),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentAdvances.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No recent advances'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentAdvances.length,
            itemBuilder: (context, index) {
              final advance = _recentAdvances[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.attach_money, color: Colors.green.shade700),
                  ),
                  title: Text(advance.purpose ?? 'Advance Request'),
                  subtitle: Text('${advance.advanceType.replaceAll('_', ' ')} • ${_formatDate(advance.givenDate)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${advance.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(advance.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          advance.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(advance.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _showTripWiseExpensesDialog() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading trip data...'),
          ],
        ),
      ),
    );
    
    try {
      // Load all trips with their expenses and advances
      final trips = await SupabaseService.getAllTrips();
      final expenses = await SupabaseService.getAllExpenses();
      final advances = await SupabaseService.getAllAdvances();
      
      // Group expenses and advances by trip ID
      final Map<String?, List<ExpenseModel>> expensesByTrip = {};
      for (final expense in expenses) {
        if (expense.tripId != null) {
          if (!expensesByTrip.containsKey(expense.tripId)) {
            expensesByTrip[expense.tripId] = [];
          }
          expensesByTrip[expense.tripId]!.add(expense);
        }
      }
      
      final Map<String?, List<AdvanceModel>> advancesByTrip = {};
      for (final advance in advances) {
        if (advance.tripId != null) {
          if (!advancesByTrip.containsKey(advance.tripId)) {
            advancesByTrip[advance.tripId] = [];
          }
          advancesByTrip[advance.tripId]!.add(advance);
        }
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show trip-wise expenses and advances
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Trip-wise Financial Summary'),
          content: SizedBox(
            width: double.maxFinite,
            child: trips.isEmpty
                ? const Center(child: Text('No trips found'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final tripExpenses = expensesByTrip[trip.id] ?? [];
                      final tripAdvances = advancesByTrip[trip.id] ?? [];
                      final totalExpenses = tripExpenses.fold(0.0, (sum, e) => sum + e.amount);
                      final totalAdvances = tripAdvances.fold(0.0, (sum, a) => sum + a.amount);
                      final pendingExpenses = tripExpenses.where((e) => e.status == 'pending').length;
                      final pendingAdvances = tripAdvances.where((a) => a.status == 'pending').length;
                      
                      final String tripTitle = trip.lrNumber.isNotEmpty ? trip.lrNumber : 'Trip ${index + 1}';
                      return ExpansionTile(
                        title: Text('$tripTitle (${trip.status})'),
                        subtitle: Text('${trip.fromLocation} to ${trip.toLocation}'),
                        children: [
                          ListTile(
                            title: const Text('Expenses'),
                            subtitle: Text('Total: ₹${totalExpenses.toStringAsFixed(2)}'),
                            trailing: pendingExpenses > 0
                                ? Chip(
                                    label: Text('$pendingExpenses pending'),
                                    backgroundColor: Colors.orange.withOpacity(0.2),
                                    labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                  )
                                : null,
                            onTap: () => _showTripExpensesDetails(trip, tripExpenses),
                          ),
                          ListTile(
                            title: const Text('Advances'),
                            subtitle: Text('Total: ₹${totalAdvances.toStringAsFixed(2)}'),
                            trailing: pendingAdvances > 0
                                ? Chip(
                                    label: Text('$pendingAdvances pending'),
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                    labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  )
                                : null,
                            onTap: () => _showTripAdvancesDetails(trip, tripAdvances),
                          ),
                          const Divider(),
                        ],
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
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading trip data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showTripExpensesDetails(dynamic trip, List<ExpenseModel> expenses) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Expenses for ${trip.lrNumber.isNotEmpty ? trip.lrNumber : 'Trip'}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: expenses.isEmpty
              ? const Center(child: Text('No expenses for this trip'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(expense.category),
                        child: Icon(_getCategoryIcon(expense.category), color: Colors.white, size: 16),
                      ),
                      title: Text(expense.description),
                      subtitle: Text('${_formatDate(expense.expenseDate)} • ${expense.category}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(expense.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              expense.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(expense.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: expense.status == 'pending'
                          ? () {
                              Navigator.of(context).pop();
                              setState(() => _currentIndex = 1);
                            }
                          : null,
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
  
  void _showTripAdvancesDetails(dynamic trip, List<AdvanceModel> advances) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Advances for ${trip.lrNumber.isNotEmpty ? trip.lrNumber : 'Trip'}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: advances.isEmpty
              ? const Center(child: Text('No advances for this trip'))
              : ListView.builder(
                  itemCount: advances.length,
                  itemBuilder: (context, index) {
                    final advance = advances[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.attach_money, color: Colors.white, size: 16),
                      ),
                      title: Text(advance.purpose ?? 'Advance'),
                      subtitle: Text('${_formatDate(advance.givenDate)} • ${advance.advanceType.replaceAll('_', ' ')}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${advance.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(advance.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              advance.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(advance.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: advance.status == 'pending'
                          ? () {
                              Navigator.of(context).pop();
                              setState(() => _currentIndex = 2);
                            }
                          : null,
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
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Colors.blue;
      case 'toll':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'food':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'toll':
        return Icons.money;
      case 'maintenance':
        return Icons.build;
      case 'food':
        return Icons.fastfood;
      default:
        return Icons.receipt;
    }
  }
}
