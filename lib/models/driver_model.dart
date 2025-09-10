class DriverModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String licenseNumber;
  final DateTime? licenseExpiry;
  final String? assignedVehicleId;
  final String status;
  final String address;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.licenseNumber,
    this.licenseExpiry,
    this.assignedVehicleId,
    required this.status,
    required this.address,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'license_number': licenseNumber,
      'license_expiry': licenseExpiry?.toIso8601String(),
      'assigned_vehicle_id': assignedVehicleId,
      'status': status,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      licenseNumber: json['license_number'],
      licenseExpiry: json['license_expiry'] != null 
          ? DateTime.parse(json['license_expiry']) 
          : null,
      assignedVehicleId: json['assigned_vehicle_id'],
      status: json['status'],
      address: json['address'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  DriverModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? assignedVehicleId,
    String? status,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
      status: status ?? this.status,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum DriverStatus {
  active('Active', 'Driver is available for assignments'),
  onTrip('On Trip', 'Driver is currently on a trip'),
  onLeave('On Leave', 'Driver is on leave'),
  inactive('Inactive', 'Driver is not available');

  const DriverStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}

