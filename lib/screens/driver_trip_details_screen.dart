import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String _expenseFilter = 'all';
  String _advanceFilter = 'all';
  
  // Add these state variables at the top of the class
  List<Map<String, dynamic>> _odometerPhotos = [];

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
      
      // Load existing photos
      await _loadOdometerPhotos();
    } catch (e) {
      print('Error loading trip details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Add method to load odometer photos
  Future<void> _loadOdometerPhotos() async {
    try {
      final photos = await SupabaseService.getOdometerPhotos(widget.trip.id);
      setState(() {
        _odometerPhotos = photos;
      });
    } catch (e) {
      print('Error loading odometer photos: $e');
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trip status can only be updated by Trip Manager',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  List<ExpenseModel> _getFilteredExpenses() {
    switch (_expenseFilter) {
      case 'pending':
        return _expenses.where((e) => e.status == 'pending').toList();
      case 'approved':
        return _expenses.where((e) => e.status == 'approved').toList();
      case 'rejected':
        return _expenses.where((e) => e.status == 'rejected').toList();
      default:
        return _expenses;
    }
  }

  List<AdvanceModel> _getFilteredAdvances() {
    switch (_advanceFilter) {
      case 'pending':
        return _advances.where((a) => a.status == 'pending').toList();
      case 'approved':
        return _advances.where((a) => a.status == 'approved').toList();
      case 'rejected':
        return _advances.where((a) => a.status == 'rejected').toList();
      default:
        return _advances;
    }
  }

  Widget _buildExpenseFilters() {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': _expenses.length},
      {'key': 'pending', 'label': 'Pending', 'count': _expenses.where((e) => e.status == 'pending').length},
      {'key': 'approved', 'label': 'Approved', 'count': _expenses.where((e) => e.status == 'approved').length},
      {'key': 'rejected', 'label': 'Rejected', 'count': _expenses.where((e) => e.status == 'rejected').length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _expenseFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${filter['label']} (${filter['count']})'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _expenseFilter = filter['key'] as String);
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdvanceFilters() {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': _advances.length},
      {'key': 'pending', 'label': 'Pending', 'count': _advances.where((a) => a.status == 'pending').length},
      {'key': 'approved', 'label': 'Approved', 'count': _advances.where((a) => a.status == 'approved').length},
      {'key': 'rejected', 'label': 'Rejected', 'count': _advances.where((a) => a.status == 'rejected').length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _advanceFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${filter['label']} (${filter['count']})'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _advanceFilter = filter['key'] as String);
              },
              selectedColor: Colors.green.withOpacity(0.2),
              checkmarkColor: Colors.green,
            ),
          );
        }).toList(),
      ),
    );
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
    final filteredExpenses = _getFilteredExpenses();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Expenses (${filteredExpenses.length})',
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
        _buildExpenseFilters(),
        Expanded(
          child: filteredExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _expenses.isEmpty ? 'No expenses added yet' : 'No expenses match the filter',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _expenses.isEmpty 
                            ? 'Add expenses for fuel, tolls, maintenance, etc.'
                            : 'Try changing the filter to see more expenses',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.receipt, color: Colors.blue.shade700),
                        ),
                        title: Text(expense.description),
                        subtitle: Text('${expense.category} • ${_formatDateTime(expense.expenseDate)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: expense.status == 'approved' ? Colors.green.shade100 : 
                                       expense.status == 'rejected' ? Colors.red.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                expense.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: expense.status == 'approved' ? Colors.green.shade700 : 
                                         expense.status == 'rejected' ? Colors.red.shade700 : Colors.orange.shade700,
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

  Widget _buildAdvancesTab() {
    final filteredAdvances = _getFilteredAdvances();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Advances (${filteredAdvances.length})',
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
        _buildAdvanceFilters(),
        Expanded(
          child: filteredAdvances.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _advances.isEmpty ? 'No advances requested yet' : 'No advances match the filter',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _advances.isEmpty 
                            ? 'Request advances for trip expenses'
                            : 'Try changing the filter to see more advances',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredAdvances.length,
                  itemBuilder: (context, index) {
                    final advance = filteredAdvances[index];
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Odometer Photos',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showPhotoUploadDialog,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Photo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildPhotosList(),
        ),
      ],
    );
  }

  Widget _buildPhotosList() {
    if (_odometerPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No photos uploaded yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload odometer photos at trip start and end',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _odometerPhotos.length,
      itemBuilder: (context, index) {
        final photo = _odometerPhotos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: photo['photo_type'] == 'start' 
                  ? Colors.green.shade100 
                  : Colors.blue.shade100,
              child: Icon(
                photo['photo_type'] == 'start' 
                    ? Icons.play_arrow 
                    : Icons.stop,
                color: photo['photo_type'] == 'start' 
                    ? Colors.green.shade700 
                    : Colors.blue.shade700,
              ),
            ),
            title: Text(
              '${photo['photo_type'].toString().toUpperCase()} Odometer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reading: ${photo['odometer_reading']} km'),
                Text('Uploaded: ${_formatDateTime(DateTime.parse(photo['uploaded_at']))}'),
                if (photo['location'] != null)
                  Text('Location: ${photo['location']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewPhoto(photo),
                  icon: const Icon(Icons.visibility),
                ),
                IconButton(
                  onPressed: () => _deletePhoto(photo),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPhotoUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Odometer Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select photo type:'),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: const Text('Start Odometer'),
              subtitle: const Text('Photo at trip start'),
              onTap: () {
                Navigator.pop(context);
                _uploadPhoto('start');
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop, color: Colors.red),
              title: const Text('End Odometer'),
              subtitle: const Text('Photo at trip end'),
              onTap: () {
                Navigator.pop(context);
                _uploadPhoto('end');
              },
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

  void _uploadPhoto(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload ${type == 'start' ? 'Start' : 'End'} Odometer Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 64, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              'Select photo source:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromCamera(type);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery(type);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
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




  Future<void> _pickImageFromCamera(String type) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        _processSelectedImage(type, image);
      }
    } catch (e) {
      _showErrorDialog('Camera Error', 'Failed to access camera: $e');
    }
  }

  Future<void> _pickImageFromGallery(String type) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        _processSelectedImage(type, image);
      }
    } catch (e) {
      _showErrorDialog('Gallery Error', 'Failed to access gallery: $e');
    }
  }

  void _processSelectedImage(String type, XFile image) async {
    // Show odometer reading input dialog
    final odometerReading = await _showOdometerReadingDialog(type);
    if (odometerReading == null) return;
    
    // Show processing dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Processing ${type == 'start' ? 'Start' : 'End'} Odometer Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Uploading photo to database...'),
            const SizedBox(height: 8),
            Text(
              'File: ${image.name}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reading: $odometerReading km',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Upload photo to Supabase
      final photoId = await SupabaseService.uploadOdometerPhoto(
        tripId: widget.trip.id,
        vehicleId: widget.trip.vehicleId,
        photoType: type,
        photo: image,
        odometerReading: odometerReading,
        location: 'Current Location',
        notes: 'Uploaded via mobile app',
      );
      
      // Close processing dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type == 'start' ? 'Start' : 'End'} odometer photo uploaded successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              _viewPhoto({
                'type': '${type == 'start' ? 'Start' : 'End'} Odometer',
                'time': 'Just now',
                'reading': '$odometerReading km',
                'filename': image.name,
                'photoId': photoId,
              });
            },
          ),
        ),
      );
      
      // Refresh the photos list
      await _loadOdometerPhotos();
      
    } catch (e) {
      // Close processing dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  // Add odometer reading input dialog
  Future<int?> _showOdometerReadingDialog(String type) async {
    final controller = TextEditingController();
    
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${type == 'start' ? 'Start' : 'End'} Odometer Reading'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter the odometer reading in kilometers:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Odometer Reading (km)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reading = int.tryParse(controller.text);
              if (reading != null && reading > 0) {
                Navigator.pop(context, reading);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid odometer reading'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(Map<String, dynamic> photo) {
    // Handle both database photos and manually created photos
    final String photoType = photo['photo_type'] ?? photo['type'] ?? 'Odometer Photo';
    final String photoTypeDisplay = photoType.toString().toUpperCase();
    final dynamic reading = photo['odometer_reading'] ?? photo['reading'] ?? 'Unknown';
    final String readingDisplay = reading is int || reading is num ? '$reading km' : reading.toString();
    final String timeDisplay = photo['uploaded_at'] != null 
        ? _formatDateTime(DateTime.parse(photo['uploaded_at']))
        : (photo['time'] ?? 'Unknown time');
    final String photoUrl = photo['photo_url'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$photoTypeDisplay Odometer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      ));
                    },
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  )
                : Icon(
                    Icons.image,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
            ),
            const SizedBox(height: 12),
            Text('Reading: $readingDisplay'),
            Text('Time: $timeDisplay'),
            if (photo['filename'] != null || photo['name'] != null) ...[
              const SizedBox(height: 8),
              Text('File: ${photo['filename'] ?? photo['name'] ?? 'Unknown'}', 
                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            if (photo['size'] != null) ...[
              Text('Size: ${photo['size']}', 
                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deletePhoto(Map<String, dynamic> photo) {
    // Handle both database photos and manually created photos
    final String photoType = photo['photo_type'] ?? photo['type'] ?? 'Odometer';
    final String photoTypeDisplay = photoType.toString().toLowerCase();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: Text('Are you sure you want to delete this $photoTypeDisplay odometer photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Determine the photo ID to delete
                String? photoId;
                if (photo['photoId'] != null) {
                  photoId = photo['photoId'];
                } else if (photo['id'] != null) {
                  photoId = photo['id'];
                }
                
                if (photoId != null) {
                  print('Deleting photo with ID: $photoId');
                  await SupabaseService.deleteOdometerPhoto(photoId);
                  await _loadOdometerPhotos();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Photo deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not identify photo ID for deletion'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                print('Error deleting photo: $e');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete photo: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
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
                // Get the proper driver ID for this user
                final driverId = await SupabaseService.getDriverIdForUser(widget.user!.id);
                if (driverId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Driver profile not found. Please contact admin.')),
                  );
                  return;
                }

                final expense = ExpenseModel(
                  id: '',
                  tripId: widget.trip.id,
                  category: selectedCategory,
                  description: descriptionController.text,
                  amount: double.parse(amountController.text),
                  expenseDate: DateTime.now(),
                  enteredBy: driverId,
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
                // Get the proper driver ID for this user
                final driverId = await SupabaseService.getDriverIdForUser(widget.user!.id);
                if (driverId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Driver profile not found. Please contact admin.')),
                  );
                  return;
                }

                final advance = AdvanceModel(
                  id: '',
                  driverId: driverId,
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
