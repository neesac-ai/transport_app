import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/advance_model.dart';
import '../services/supabase_service.dart';

class DriverAdvanceManagementScreen extends StatefulWidget {
  final UserModel user;

  const DriverAdvanceManagementScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<DriverAdvanceManagementScreen> createState() => _DriverAdvanceManagementScreenState();
}

class _DriverAdvanceManagementScreenState extends State<DriverAdvanceManagementScreen> {
  bool _isLoading = true;
  List<AdvanceModel> _advances = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    setState(() => _isLoading = true);
    
    try {
      final advances = await SupabaseService.getDriverAdvances(widget.user.id);
      setState(() => _advances = advances);
    } catch (e) {
      print('Error loading advances: $e');
      _showErrorSnackBar('Failed to load advances');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<AdvanceModel> _getFilteredAdvances() {
    switch (_selectedFilter) {
      case 'pending':
        return _advances.where((advance) => advance.status == 'pending').toList();
      case 'approved':
        return _advances.where((advance) => advance.status == 'approved').toList();
      case 'rejected':
        return _advances.where((advance) => advance.status == 'rejected').toList();
      default:
        return _advances;
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'rejected', 'label': 'Rejected'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter['key']!);
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdvanceCard(AdvanceModel advance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  advance.advanceType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(advance.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    advance.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(advance.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  '₹${advance.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDate(advance.givenDate),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (advance.purpose != null && advance.purpose!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advance.purpose!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (advance.notes != null && advance.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${advance.notes}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
            if (advance.status == 'rejected' && advance.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection Reason: ${advance.rejectionReason}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (advance.approvedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Approved on ${_formatDate(advance.approvedAt!)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _requestAdvance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestAdvanceScreen(
          user: widget.user,
          onAdvanceRequested: _loadAdvances,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdvances,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAdvances,
                    child: _getFilteredAdvances().isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _getFilteredAdvances().length,
                            itemBuilder: (context, index) {
                              final advance = _getFilteredAdvances()[index];
                              return _buildAdvanceCard(advance);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestAdvance,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_money_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No advances found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any advances in this category',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestAdvanceScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onAdvanceRequested;

  const RequestAdvanceScreen({
    Key? key,
    required this.user,
    required this.onAdvanceRequested,
  }) : super(key: key);

  @override
  State<RequestAdvanceScreen> createState() => _RequestAdvanceScreenState();
}

class _RequestAdvanceScreenState extends State<RequestAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'trip_advance';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _advanceTypes = [
    'trip_advance',
    'general_advance',
    'emergency',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitAdvanceRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final advance = AdvanceModel(
        id: '', // Will be auto-generated by database
        driverId: widget.user.id,
        tripId: null, // General advance, not trip-specific
        amount: double.parse(_amountController.text),
        advanceType: _selectedType,
        purpose: _purposeController.text.isNotEmpty ? _purposeController.text : null,
        givenBy: widget.user.id,
        givenDate: _selectedDate,
        status: 'pending',
        approvedBy: null,
        approvedAt: null,
        rejectionReason: null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      await SupabaseService.createAdvance(advance);
      
      Navigator.pop(context);
      widget.onAdvanceRequested();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advance request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error creating advance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit advance request'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Advance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Advance Type Selection
              const Text(
                'Advance Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _advanceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an advance type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              const Text(
                'Amount (₹)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Purpose
              const Text(
                'Purpose',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter purpose for advance',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a purpose';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              const Text(
                'Request Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter any additional notes',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAdvanceRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
