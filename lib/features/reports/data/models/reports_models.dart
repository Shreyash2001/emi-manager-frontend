// Models for all /reports/* endpoints

class ReportsSummaryModel {
  final double totalRevenue;
  final double monthlyRevenue;
  final int totalCustomers;
  final int activeEmiPlans;
  final double collectionRate;
  final double overdueAmount;

  const ReportsSummaryModel({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.totalCustomers,
    required this.activeEmiPlans,
    required this.collectionRate,
    required this.overdueAmount,
  });

  factory ReportsSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportsSummaryModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      activeEmiPlans: (json['activeEmiPlans'] as num?)?.toInt() ?? 0,
      collectionRate: (json['collectionRate'] as num?)?.toDouble() ?? 0.0,
      overdueAmount: (json['overdueAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyTrendModel {
  final String month;
  final double collected;
  final double pending;

  const MonthlyTrendModel({
    required this.month,
    required this.collected,
    required this.pending,
  });

  factory MonthlyTrendModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendModel(
      month: json['month'] as String? ?? '',
      collected: (json['collected'] as num?)?.toDouble() ?? 0.0,
      pending: (json['pending'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeeklyCollectionModel {
  final String week;
  final double amount;

  const WeeklyCollectionModel({required this.week, required this.amount});

  factory WeeklyCollectionModel.fromJson(Map<String, dynamic> json) {
    return WeeklyCollectionModel(
      week: json['week'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SmartphoneBreakdownModel {
  final String brand;
  final int count;
  final double totalValue;

  const SmartphoneBreakdownModel({
    required this.brand,
    required this.count,
    required this.totalValue,
  });

  factory SmartphoneBreakdownModel.fromJson(Map<String, dynamic> json) {
    return SmartphoneBreakdownModel(
      brand: json['brand'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
