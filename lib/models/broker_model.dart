class BrokerModel {
  final String id;
  final String name;
  final String? company;
  final String? contactNumber;
  final String? email;
  final String? address;
  final double commissionRate;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BrokerModel({
    required this.id,
    required this.name,
    this.company,
    this.contactNumber,
    this.email,
    this.address,
    this.commissionRate = 0.0,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'contact_number': contactNumber,
      'email': email,
      'address': address,
      'commission_rate': commissionRate,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory BrokerModel.fromJson(Map<String, dynamic> json) {
    return BrokerModel(
      id: json['id'],
      name: json['name'],
      company: json['company'],
      contactNumber: json['contact_number'],
      email: json['email'],
      address: json['address'],
      commissionRate: (json['commission_rate'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  BrokerModel copyWith({
    String? id,
    String? name,
    String? company,
    String? contactNumber,
    String? email,
    String? address,
    double? commissionRate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrokerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      commissionRate: commissionRate ?? this.commissionRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum BrokerStatus {
  active('Active', 'Broker is active and available'),
  inactive('Inactive', 'Broker is not available');

  const BrokerStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}


