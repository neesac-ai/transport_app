class TripFinancialReportModel {
  final String id;
  final String tripId;
  final String tripLrNumber;
  final String fromLocation;
  final String toLocation;
  final double distanceKm;
  final double tonnage;
  final double ratePerTon;
  
  // Revenue
  final double totalRevenue;
  final double commissionAmount;
  final double netRevenue;
  
  // Expenses
  final double advanceAmount;
  final double expensesAmount;
  final double silakAmount;
  final double dieselAmount;
  final double otherCosts;
  final double totalExpenses;
  
  // Profit/Loss
  final double profitLoss;
  final double profitMarginPercentage;
  
  final String tripStatus;
  final bool isFinal;
  final DateTime reportDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TripFinancialReportModel({
    required this.id,
    required this.tripId,
    required this.tripLrNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.distanceKm,
    required this.tonnage,
    required this.ratePerTon,
    required this.totalRevenue,
    required this.commissionAmount,
    required this.netRevenue,
    required this.advanceAmount,
    required this.expensesAmount,
    required this.silakAmount,
    required this.dieselAmount,
    required this.otherCosts,
    required this.totalExpenses,
    required this.profitLoss,
    required this.profitMarginPercentage,
    required this.tripStatus,
    required this.isFinal,
    required this.reportDate,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'trip_lr_number': tripLrNumber,
      'from_location': fromLocation,
      'to_location': toLocation,
      'distance_km': distanceKm,
      'tonnage': tonnage,
      'rate_per_ton': ratePerTon,
      'total_revenue': totalRevenue,
      'commission_amount': commissionAmount,
      'net_revenue': netRevenue,
      'advance_amount': advanceAmount,
      'expenses_amount': expensesAmount,
      'silak_amount': silakAmount,
      'diesel_amount': dieselAmount,
      'other_costs': otherCosts,
      'total_expenses': totalExpenses,
      'profit_loss': profitLoss,
      'profit_margin_percentage': profitMarginPercentage,
      'trip_status': tripStatus,
      'is_final': isFinal,
      'report_date': reportDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory TripFinancialReportModel.fromJson(Map<String, dynamic> json) {
    return TripFinancialReportModel(
      id: json['id'],
      tripId: json['trip_id'],
      tripLrNumber: json['trip_lr_number'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      tonnage: (json['tonnage'] ?? 0.0).toDouble(),
      ratePerTon: (json['rate_per_ton'] ?? 0.0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      commissionAmount: (json['commission_amount'] ?? 0.0).toDouble(),
      netRevenue: (json['net_revenue'] ?? 0.0).toDouble(),
      advanceAmount: (json['advance_amount'] ?? 0.0).toDouble(),
      expensesAmount: (json['expenses_amount'] ?? 0.0).toDouble(),
      silakAmount: (json['silak_amount'] ?? 0.0).toDouble(),
      dieselAmount: (json['diesel_amount'] ?? 0.0).toDouble(),
      otherCosts: (json['other_costs'] ?? 0.0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0.0).toDouble(),
      profitLoss: (json['profit_loss'] ?? 0.0).toDouble(),
      profitMarginPercentage: (json['profit_margin_percentage'] ?? 0.0).toDouble(),
      tripStatus: json['trip_status'] ?? 'in_progress',
      isFinal: json['is_final'] ?? false,
      reportDate: DateTime.parse(json['report_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  TripFinancialReportModel copyWith({
    String? id,
    String? tripId,
    String? tripLrNumber,
    String? fromLocation,
    String? toLocation,
    double? distanceKm,
    double? tonnage,
    double? ratePerTon,
    double? totalRevenue,
    double? commissionAmount,
    double? netRevenue,
    double? advanceAmount,
    double? expensesAmount,
    double? silakAmount,
    double? dieselAmount,
    double? otherCosts,
    double? totalExpenses,
    double? profitLoss,
    double? profitMarginPercentage,
    String? tripStatus,
    bool? isFinal,
    DateTime? reportDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripFinancialReportModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      tripLrNumber: tripLrNumber ?? this.tripLrNumber,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      distanceKm: distanceKm ?? this.distanceKm,
      tonnage: tonnage ?? this.tonnage,
      ratePerTon: ratePerTon ?? this.ratePerTon,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      netRevenue: netRevenue ?? this.netRevenue,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      expensesAmount: expensesAmount ?? this.expensesAmount,
      silakAmount: silakAmount ?? this.silakAmount,
      dieselAmount: dieselAmount ?? this.dieselAmount,
      otherCosts: otherCosts ?? this.otherCosts,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      profitLoss: profitLoss ?? this.profitLoss,
      profitMarginPercentage: profitMarginPercentage ?? this.profitMarginPercentage,
      tripStatus: tripStatus ?? this.tripStatus,
      isFinal: isFinal ?? this.isFinal,
      reportDate: reportDate ?? this.reportDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

