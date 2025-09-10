class VehicleModel {
  final String id;
  final String registrationNumber;
  final String vehicleType;
  final String capacity;
  final String? driverId;
  final String status;
  final String? rcNumber;
  final String? permitNumber;
  final String? insuranceNumber;
  final DateTime? insuranceExpiry;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VehicleModel({
    required this.id,
    required this.registrationNumber,
    required this.vehicleType,
    required this.capacity,
    this.driverId,
    required this.status,
    this.rcNumber,
    this.permitNumber,
    this.insuranceNumber,
    this.insuranceExpiry,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'vehicle_type': vehicleType,
      'capacity': capacity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Convert to JSON for database insertion (only fields that exist in DB)
  Map<String, dynamic> toJsonForDatabase() {
    return {
      'registration_number': registrationNumber,
      'vehicle_type': vehicleType,
      'capacity': capacity,
      'status': status,
    };
  }

  // Create from JSON
  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      registrationNumber: json['registration_number'],
      vehicleType: json['vehicle_type'],
      capacity: json['capacity'],
      driverId: json['driver_id'],
      status: json['status'],
      rcNumber: json['rc_number'],
      permitNumber: json['permit_number'],
      insuranceNumber: json['insurance_number'],
      insuranceExpiry: json['insurance_expiry'] != null 
          ? DateTime.parse(json['insurance_expiry']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  VehicleModel copyWith({
    String? id,
    String? registrationNumber,
    String? vehicleType,
    String? capacity,
    String? driverId,
    String? status,
    String? rcNumber,
    String? permitNumber,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      capacity: capacity ?? this.capacity,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      rcNumber: rcNumber ?? this.rcNumber,
      permitNumber: permitNumber ?? this.permitNumber,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum VehicleStatus {
  active('Active', 'Vehicle is operational'),
  maintenance('Maintenance', 'Vehicle is under maintenance'),
  inactive('Inactive', 'Vehicle is not in use'),
  retired('Retired', 'Vehicle has been retired');

  const VehicleStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}

enum VehicleType {
  truck('Truck', 'Heavy goods vehicle'),
  trailer('Trailer', 'Goods trailer'),
  pickup('Pickup', 'Light commercial vehicle'),
  van('Van', 'Commercial van');

  const VehicleType(this.displayName, this.description);

  final String displayName;
  final String description;
}

