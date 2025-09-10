class UserModel {
  final String id;
  final String? username;
  final String phoneNumber;
  final String name;
  final String email;
  final String address;
  final UserRole? role;
  final ApprovalStatus approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    this.username,
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.address,
    this.role,
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone_number': phoneNumber, // Match database column name
      'name': name,
      'email': email,
      'address': address,
      'role': role?.name == 'tripManager' ? 'trip_manager' : role?.name,
      'approval_status': approvalStatus.name,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(), // Match database column name
      'updated_at': updatedAt?.toIso8601String(), // Match database column name
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '', // Handle both formats
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      role: json['role'] != null 
          ? UserRole.values.firstWhere(
              (e) => e.name == json['role'],
              orElse: () => UserRole.driver,
            )
          : null,
      approvalStatus: json['approval_status'] != null
          ? ApprovalStatus.values.firstWhere(
              (e) => e.name == json['approval_status'],
              orElse: () => ApprovalStatus.pending,
            )
          : ApprovalStatus.pending,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'])
              : null,
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? username,
    String? phoneNumber,
    String? name,
    String? email,
    String? address,
    UserRole? role,
    ApprovalStatus? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum UserRole {
  admin('Admin', 'Full access, manage users, system settings, overall oversight'),
  tripManager('Trip Manager', 'Create trips, assign drivers/vehicles, manage trip lifecycle'),
  driver('Driver', 'Work within assigned trips, add expenses/advances, upload photos'),
  accountant('Accountant', 'Enter expenses, track advances, reconcile diesel usage and settlements'),
  pumpPartner('Pump Partner', 'Upload diesel refueling data + vehicle photo (via credentials)');

  const UserRole(this.displayName, this.description);

  final String displayName;
  final String description;

  // Get role permissions
  List<String> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          'manage_users',
          'approve_expenses',
          'override_data',
          'view_all_reports',
          'manage_vehicles',
          'manage_trips',
          'manage_diesel',
          'manage_expenses',
        ];
      case UserRole.tripManager:
        return [
          'create_trips',
          'assign_drivers',
          'assign_vehicles',
          'manage_trip_lifecycle',
          'view_trips',
          'manage_vehicles',
          'view_drivers',
        ];
      case UserRole.driver:
        return [
          'view_assigned_trips',
          'add_trip_expenses',
          'request_trip_advances',
          'upload_odometer_photos',
          'update_trip_status',
          'view_silak',
        ];
      case UserRole.accountant:
        return [
          'enter_expenses',
          'track_advances',
          'reconcile_diesel',
          'view_financial_reports',
          'manage_settlements',
        ];
      case UserRole.pumpPartner:
        return [
          'upload_diesel_data',
          'upload_vehicle_photos',
        ];
    }
  }
}

enum ApprovalStatus {
  pending('Pending', 'Waiting for admin approval'),
  approved('Approved', 'User has been approved by admin'),
  rejected('Rejected', 'User registration has been rejected');

  const ApprovalStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}
