class OdometerPhotoModel {
  final String id;
  final String tripId;
  final String vehicleId;
  final String photoType;
  final String photoUrl;
  final double odometerReading;
  final String? location;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;
  final DateTime createdAt;

  OdometerPhotoModel({
    required this.id,
    required this.tripId,
    required this.vehicleId,
    required this.photoType,
    required this.photoUrl,
    required this.odometerReading,
    this.location,
    this.uploadedBy,
    required this.uploadedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
    required this.createdAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'vehicle_id': vehicleId,
      'photo_type': photoType,
      'photo_url': photoUrl,
      'odometer_reading': odometerReading,
      'location': location,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory OdometerPhotoModel.fromJson(Map<String, dynamic> json) {
    return OdometerPhotoModel(
      id: json['id'],
      tripId: json['trip_id'],
      vehicleId: json['vehicle_id'],
      photoType: json['photo_type'],
      photoUrl: json['photo_url'],
      odometerReading: (json['odometer_reading'] ?? 0.0).toDouble(),
      location: json['location'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Copy with method for updates
  OdometerPhotoModel copyWith({
    String? id,
    String? tripId,
    String? vehicleId,
    String? photoType,
    String? photoUrl,
    double? odometerReading,
    String? location,
    String? uploadedBy,
    DateTime? uploadedAt,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return OdometerPhotoModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      vehicleId: vehicleId ?? this.vehicleId,
      photoType: photoType ?? this.photoType,
      photoUrl: photoUrl ?? this.photoUrl,
      odometerReading: odometerReading ?? this.odometerReading,
      location: location ?? this.location,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool get isStartPhoto => photoType == 'start';
  bool get isEndPhoto => photoType == 'end';
  bool get isVerified => verifiedBy != null && verifiedAt != null;
  bool get isPendingVerification => !isVerified;
  
  String get photoTypeDisplayName {
    switch (photoType) {
      case 'start':
        return 'Start Odometer';
      case 'end':
        return 'End Odometer';
      default:
        return 'Unknown';
    }
  }
}

enum OdometerPhotoType {
  start('start', 'Start Odometer', 'Odometer reading at trip start'),
  end('end', 'End Odometer', 'Odometer reading at trip end');

  const OdometerPhotoType(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}


