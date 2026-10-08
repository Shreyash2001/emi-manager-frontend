/// EMI plan detail model for GET /emi-plans/:id
class EmiPlanModel {
  final String id;
  final String customerId;
  final String customerName;
  final String handsetBrand;
  final String handsetModel;
  final String? handsetStorage;
  final String? handsetColor;
  final String imei;
  final double sellingPrice;
  final double downPayment;
  final double loanAmount;
  final int tenureMonths;
  final double monthlyInstallment;
  final int paidInstallments;
  final double paidAmount;
  final int remainingInstallments;
  final double outstandingAmount;
  final String status;
  final DateTime? firstEmiDueDate;
  final DateTime? nextDueDate;
  final DateTime? startDate;
  final DateTime? clearedAt;
  final String? notes;

  const EmiPlanModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.handsetBrand,
    required this.handsetModel,
    this.handsetStorage,
    this.handsetColor,
    required this.imei,
    required this.sellingPrice,
    required this.downPayment,
    required this.loanAmount,
    required this.tenureMonths,
    required this.monthlyInstallment,
    required this.paidInstallments,
    required this.paidAmount,
    required this.remainingInstallments,
    required this.outstandingAmount,
    required this.status,
    this.firstEmiDueDate,
    this.nextDueDate,
    this.startDate,
    this.clearedAt,
    this.notes,
  });

  factory EmiPlanModel.fromJson(Map<String, dynamic> json) {
    final handset = json['handset'] as Map<String, dynamic>? ?? {};
    final customerData = json['customerId'];
    String customerName = '';
    String customerId = '';
    if (customerData is Map<String, dynamic>) {
      customerName = customerData['name'] as String? ?? '';
      customerId = customerData['_id']?.toString() ?? '';
    } else {
      customerId = customerData?.toString() ?? '';
    }

    return EmiPlanModel(
      id: json['id'] as String? ?? json['_id']?.toString() ?? '',
      customerId: customerId,
      customerName: customerName,
      handsetBrand: handset['brand'] as String? ?? '',
      handsetModel: handset['modelName'] as String? ?? '',
      handsetStorage: handset['storage'] as String?,
      handsetColor: handset['color'] as String?,
      imei: handset['imei'] as String? ?? '',
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      downPayment: (json['downPayment'] as num?)?.toDouble() ?? 0.0,
      loanAmount: (json['loanAmount'] as num?)?.toDouble() ?? 0.0,
      tenureMonths: (json['tenureMonths'] as num?)?.toInt() ?? 0,
      monthlyInstallment: (json['monthlyInstallment'] as num?)?.toDouble() ?? 0.0,
      paidInstallments: (json['paidInstallments'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingInstallments: (json['remainingInstallments'] as num?)?.toInt() ?? 0,
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ON_TRACK',
      firstEmiDueDate: json['firstEmiDueDate'] != null
          ? DateTime.tryParse(json['firstEmiDueDate'] as String)
          : null,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.tryParse(json['nextDueDate'] as String)
          : null,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      clearedAt: json['clearedAt'] != null
          ? DateTime.tryParse(json['clearedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
