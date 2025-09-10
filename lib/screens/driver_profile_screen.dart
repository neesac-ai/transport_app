import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../services/supabase_service.dart';

class DriverProfileScreen extends StatefulWidget {
  final UserModel user;

  const DriverProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  DriverModel? _driverDetails;

  @override
  void initState() {
    super.initState();
    _loadDriverDetails();
  }

  Future<void> _loadDriverDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final drivers = await SupabaseService.getDrivers();
      _driverDetails = drivers.firstWhere(
        (driver) => driver.id == widget.user.id,
        orElse: () => drivers.first,
      );
    } catch (e) {
      print('Error loading driver details: $e');
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
              'Account Status',
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
                color: _getStatusColor(widget.user.approvalStatus.name).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(widget.user.approvalStatus.name),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.user.approvalStatus.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(widget.user.approvalStatus.name),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.approvalStatus.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
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
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatusCard(),
                  _buildInfoCard(
                    'Personal Information',
                    [
                      _buildInfoRow('Name', widget.user.name, icon: Icons.person),
                      _buildInfoRow('Email', widget.user.email, icon: Icons.email),
                      _buildInfoRow('Phone', widget.user.phoneNumber, icon: Icons.phone),
                      _buildInfoRow('Address', widget.user.address, icon: Icons.location_on),
                      _buildInfoRow('Role', widget.user.role?.displayName ?? 'Not assigned', icon: Icons.work),
                    ],
                  ),
                  if (_driverDetails != null)
                    _buildInfoCard(
                      'Driver Information',
                      [
                        _buildInfoRow('License Number', _driverDetails!.licenseNumber, icon: Icons.credit_card),
                        if (_driverDetails!.licenseExpiry != null)
                          _buildInfoRow('License Expiry', _formatDate(_driverDetails!.licenseExpiry!), icon: Icons.calendar_today),
                        _buildInfoRow('Status', _driverDetails!.status, icon: Icons.info),
                        _buildInfoRow('Member Since', _formatDate(_driverDetails!.createdAt), icon: Icons.date_range),
                      ],
                    ),
                  _buildInfoCard(
                    'Account Information',
                    [
                      _buildInfoRow('User ID', widget.user.id, icon: Icons.badge),
                      _buildInfoRow('Created At', _formatDate(widget.user.createdAt), icon: Icons.date_range),
                      if (widget.user.updatedAt != null)
                        _buildInfoRow('Last Updated', _formatDate(widget.user.updatedAt!), icon: Icons.update),
                      if (widget.user.approvedBy != null)
                        _buildInfoRow('Approved By', widget.user.approvedBy!, icon: Icons.check_circle),
                      if (widget.user.approvedAt != null)
                        _buildInfoRow('Approved At', _formatDate(widget.user.approvedAt!), icon: Icons.check_circle),
                    ],
                  ),
                  if (widget.user.rejectionReason != null)
                    _buildInfoCard(
                      'Rejection Information',
                      [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.user.rejectionReason!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

