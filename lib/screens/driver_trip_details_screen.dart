import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/vehicle_model.dart';
import '../models/broker_model.dart';
import '../models/expense_model.dart';
import '../models/advance_model.dart';
import '../services/supabase_service.dart';

class DriverTripDetailsScreen extends StatefulWidget {
  final TripModel trip;
  final UserModel? user;

  const DriverTripDetailsScreen({
    Key? key,
    required this.trip,
    this.user,
  }) : super(key: key);

  @override
  State<DriverTripDetailsScreen> createState() => _DriverTripDetailsScreenState();
}

class _DriverTripDetailsScreenState extends State<DriverTripDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  VehicleModel? _vehicle;
  BrokerModel? _broker;
  late TabController _tabController;
  
  // Trip-related data
  List<ExpenseModel> _expenses = [];
  List<AdvanceModel> _advances = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTripDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTripDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Load vehicle details
      final vehicles = await SupabaseService.getVehicles();
      try {
        _vehicle = vehicles.firstWhere((v) => v.id == widget.trip.vehicleId);
      } catch (e) {
        _vehicle = vehicles.isNotEmpty ? vehicles.first : null;
      }
      
      // Load broker details
      if (widget.trip.brokerId != null) {
        final brokers = await SupabaseService.getBrokers();
        _broker = brokers.firstWhere(
          (b) => b.id == widget.trip.brokerId,
          orElse: () => brokers.first,
        );
      }
      
      // Load trip expenses and advances
      if (widget.user != null) {
        _expenses = await SupabaseService.getDriverExpenses(widget.user!.id);
        _advances = await SupabaseService.getDriverAdvances(widget.user!.id);
      }
      
      // Filter expenses and advances for this specific trip
      _expenses = _expenses.where((expense) => expense.tripId == widget.trip.id).toList();
      _advances = _advances.where((advance) => advance.tripId == widget.trip.id).toList();
    } catch (e) {
      print('Error loading trip details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.trip.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(widget.trip.status),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.trip.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(widget.trip.status),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusDescription(widget.trip.status),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (widget.trip.status == 'assigned' || widget.trip.status == 'in_progress') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateTripStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    widget.trip.status == 'assigned' ? 'Start Trip' : 'Complete Trip',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'settled':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'assigned':
        return 'Trip has been assigned and is ready to start';
      case 'in_progress':
        return 'Trip is currently in progress';
      case 'completed':
        return 'Trip has been completed successfully';
      case 'settled':
        return 'Trip has been settled and paid';
      case 'cancelled':
        return 'Trip has been cancelled';
      default:
        return 'Unknown status';
    }
  }

  void _updateTripStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Trip Status - ${widget.trip.lrNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.trip.status == 'assigned')
              RadioListTile<String>(
                title: const Text('Start Trip (In Progress)'),
                value: 'in_progress',
                groupValue: widget.trip.status,
                onChanged: (value) => _changeTripStatus(value!),
              ),
            if (widget.trip.status == 'in_progress')
              RadioListTile<String>(
                title: const Text('Complete Trip'),
                value: 'completed',
                groupValue: widget.trip.status,
                onChanged: (value) => _changeTripStatus(value!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeTripStatus(String newStatus) async {
    try {
      await SupabaseService.updateTripStatus(widget.trip.id, newStatus);
      Navigator.pop(context);
      setState(() {
        widget.trip.status = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update trip status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip ${widget.trip.lrNumber}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.receipt), text: 'Expenses'),
            Tab(icon: Icon(Icons.attach_money), text: 'Advances'),
            Tab(icon: Icon(Icons.photo_camera), text: 'Photos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildExpensesTab(),
                _buildAdvancesTab(),
                _buildPhotosTab(),
              ],
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatusCard(),
          _buildInfoCard(
            'Trip Information',
            [
              _buildInfoRow('LR Number', widget.trip.lrNumber, icon: Icons.receipt),
              _buildInfoRow('From', widget.trip.fromLocation, icon: Icons.location_on),
              _buildInfoRow('To', widget.trip.toLocation, icon: Icons.location_on),
              _buildInfoRow('Distance', '${widget.trip.distanceKm} km', icon: Icons.straighten),
              _buildInfoRow('Tonnage', '${widget.trip.tonnage} tons', icon: Icons.local_shipping),
              _buildInfoRow('Rate per Ton', '₹${widget.trip.ratePerTon}', icon: Icons.attach_money),
              _buildInfoRow('Total Rate', '₹${widget.trip.totalRate}', icon: Icons.attach_money),
              if (widget.trip.commissionAmount > 0)
                _buildInfoRow('Commission', '₹${widget.trip.commissionAmount}', icon: Icons.percent),
            ],
          ),
          if (_vehicle != null)
            _buildInfoCard(
              'Vehicle Information',
              [
                _buildInfoRow('Registration', _vehicle!.registrationNumber, icon: Icons.directions_car),
                _buildInfoRow('Type', _vehicle!.vehicleType, icon: Icons.category),
                _buildInfoRow('Capacity', '${_vehicle!.capacity} tons', icon: Icons.straighten),
                _buildInfoRow('Status', _vehicle!.status, icon: Icons.info),
              ],
            ),
          if (_broker != null)
            _buildInfoCard(
              'Broker Information',
              [
                _buildInfoRow('Name', _broker!.name, icon: Icons.person),
                if (_broker!.company != null)
                  _buildInfoRow('Company', _broker!.company!, icon: Icons.business),
                if (_broker!.contactNumber != null)
                  _buildInfoRow('Contact', _broker!.contactNumber!, icon: Icons.phone),
                if (_broker!.email != null)
                  _buildInfoRow('Email', _broker!.email!, icon: Icons.email),
                if (_broker!.commissionRate > 0)
                  _buildInfoRow('Commission Rate', '${_broker!.commissionRate}%', icon: Icons.percent),
              ],
            ),
          _buildInfoCard(
            'Financial Details',
            [
              _buildInfoRow('Advance Given', '₹${widget.trip.advanceGiven}', icon: Icons.attach_money),
              _buildInfoRow('Diesel Issued', '₹${widget.trip.dieselIssued}', icon: Icons.local_gas_station),
              _buildInfoRow('Silak Amount', '₹${widget.trip.silakAmount}', icon: Icons.calculate),
            ],
          ),
          if (widget.trip.startDate != null || widget.trip.endDate != null)
            _buildInfoCard(
              'Timeline',
              [
                if (widget.trip.startDate != null)
                  _buildInfoRow('Start Date', _formatDateTime(widget.trip.startDate!), icon: Icons.play_arrow),
                if (widget.trip.endDate != null)
                  _buildInfoRow('End Date', _formatDateTime(widget.trip.endDate!), icon: Icons.stop),
              ],
            ),
          if (widget.trip.notes != null && widget.trip.notes!.isNotEmpty)
            _buildInfoCard(
              'Notes',
              [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    widget.trip.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Expenses (${_expenses.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses added yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add expenses for fuel, tolls, maintenance, etc.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.receipt, color: Colors.blue.shade700),
                        ),
                        title: Text(expense.description),
                        subtitle: Text('${expense.category} • ${_formatDateTime(expense.expenseDate)}'),
                        trailing: Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAdvancesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Advances (${_advances.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddAdvanceDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Request Advance'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _advances.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No advances requested yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Request advances for trip expenses',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _advances.length,
                  itemBuilder: (context, index) {
                    final advance = _advances[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.attach_money, color: Colors.green.shade700),
                        ),
                        title: Text('${advance.advanceType.replaceAll('_', ' ').toUpperCase()}'),
                        subtitle: Text('${advance.purpose ?? 'No description'} • ${_formatDateTime(advance.givenDate)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${advance.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: advance.status == 'approved' ? Colors.green.shade100 : 
                                       advance.status == 'rejected' ? Colors.red.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                advance.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: advance.status == 'approved' ? Colors.green.shade700 : 
                                         advance.status == 'rejected' ? Colors.red.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Odometer Photos',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload photos at trip start and end',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement photo upload functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo upload coming soon!')),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload Photo'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'fuel';
    final categories = ['fuel', 'toll', 'maintenance', 'food', 'other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category.toUpperCase()),
              )).toList(),
              onChanged: (value) => selectedCategory = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (descriptionController.text.isNotEmpty && amountController.text.isNotEmpty && widget.user != null) {
                final expense = ExpenseModel(
                  id: '',
                  tripId: widget.trip.id,
                  category: selectedCategory,
                  description: descriptionController.text,
                  amount: double.parse(amountController.text),
                  expenseDate: DateTime.now(),
                  enteredBy: widget.user!.id,
                  createdAt: DateTime.now(),
                );
                
                try {
                  await SupabaseService.createExpense(expense);
                  Navigator.pop(context);
                  _loadTripDetails(); // Refresh data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense added successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding expense: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddAdvanceDialog() {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    String selectedType = 'trip_advance';
    final types = ['trip_advance', 'general_advance', 'emergency'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Advance Type',
                border: OutlineInputBorder(),
              ),
              items: types.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (value) => selectedType = value!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty && widget.user != null) {
                final advance = AdvanceModel(
                  id: '',
                  driverId: widget.user!.id,
                  tripId: widget.trip.id,
                  amount: double.parse(amountController.text),
                  advanceType: selectedType,
                  purpose: purposeController.text,
                  givenDate: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                
                try {
                  await SupabaseService.createAdvance(advance);
                  Navigator.pop(context);
                  _loadTripDetails(); // Refresh data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Advance request submitted!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error requesting advance: $e')),
                  );
                }
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }
}
