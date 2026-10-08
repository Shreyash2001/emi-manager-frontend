/// Response model for GET /api/v1/dashboard
class DashboardModel {
  final int totalCustomers;
  final int newCustomersThisMonth;
  final int activeCustomers;
  final int activeEmis;
  final double activeLoanAmount;
  final double totalCollection;
  final double pendingAmount;
  final int overdueCount;
  final double monthlyCollection;
  final String storeName;
  final String? storeLocation;
  final String ownerName;

  const DashboardModel({
    required this.totalCustomers,
    required this.newCustomersThisMonth,
    required this.activeCustomers,
    required this.activeEmis,
    required this.activeLoanAmount,
    required this.totalCollection,
    required this.pendingAmount,
    required this.overdueCount,
    required this.monthlyCollection,
    required this.storeName,
    this.storeLocation,
    required this.ownerName,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      newCustomersThisMonth: (json['newCustomersThisMonth'] as num?)?.toInt() ?? 0,
      activeCustomers: (json['activeCustomers'] as num?)?.toInt() ?? 0,
      activeEmis: (json['activeEmis'] as num?)?.toInt() ?? 0,
      activeLoanAmount: (json['activeLoanAmount'] as num?)?.toDouble() ?? 0.0,
      totalCollection: (json['totalCollection'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
      monthlyCollection: (json['monthlyCollection'] as num?)?.toDouble() ?? 0.0,
      storeName: json['storeName'] as String? ?? '',
      storeLocation: json['storeLocation'] as String?,
      ownerName: json['ownerName'] as String? ?? '',
    );
  }
}
