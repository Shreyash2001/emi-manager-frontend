/// Payment model returned from GET/POST /payments
class PaymentModel {
  final String id;
  final String customerId;
  final String customerName;
  final String emiPlanId;
  final double amount;
  final String paymentMethod;
  final String? paymentType;
  final int? installmentNumber;
  final DateTime? paymentDate;
  final String? receiptNumber;
  final String? transactionReference;
  final String status;

  const PaymentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.emiPlanId,
    required this.amount,
    required this.paymentMethod,
    this.paymentType,
    this.installmentNumber,
    this.paymentDate,
    this.receiptNumber,
    this.transactionReference,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final rawCustomer = json['customerId'] ?? json['customer'];
    String custId = '';
    String custName = json['customerName'] as String? ?? '';

    if (rawCustomer is Map) {
      custId = rawCustomer['id']?.toString() ??
          rawCustomer['_id']?.toString() ??
          '';
      if (custName.isEmpty) {
        custName = rawCustomer['name']?.toString() ??
            rawCustomer['fullName']?.toString() ??
            rawCustomer['customerName']?.toString() ??
            '';
      }
    } else if (rawCustomer != null) {
      custId = rawCustomer.toString();
    }

    if (custId.contains('[object Object]') || custId.startsWith('{')) {
      custId = '';
    }

    String emiId = '';
    final rawEmi = json['emiPlanId'] ?? json['emiPlan'];
    if (rawEmi is Map) {
      emiId = rawEmi['id']?.toString() ?? rawEmi['_id']?.toString() ?? '';
    } else if (rawEmi != null) {
      emiId = rawEmi.toString();
      if (emiId.contains('[object Object]') || emiId.startsWith('{')) {
        emiId = '';
      }
    }

    return PaymentModel(
      id: json['id'] as String? ?? json['_id']?.toString() ?? '',
      customerId: custId,
      customerName: custName,
      emiPlanId: emiId,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentType: json['paymentType'] as String?,
      installmentNumber: (json['installmentNumber'] as num?)?.toInt(),
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'] as String)
          : null,
      receiptNumber: json['receiptNumber'] as String?,
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String? ?? 'PAID',
    );
  }
}

class PaymentListResponse {
  final List<PaymentModel> items;
  final int total;
  final int page;
  final int totalPages;

  const PaymentListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return PaymentListResponse(
      items: items,
      total: (pagination['total'] as num?)?.toInt() ?? items.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Request model for POST /payments
class RecordPaymentRequestModel {
  final String customerId;
  final String emiPlanId;
  final double amount;
  final String paymentMethod; // CASH | UPI | UPI_AUTOPAY | CARD
  final String paymentType; // EMI | DOWN_PAYMENT
  final int? installmentNumber;
  final String? paymentDate;
  final String? transactionReference;
  final String? notes;

  const RecordPaymentRequestModel({
    required this.customerId,
    required this.emiPlanId,
    required this.amount,
    required this.paymentMethod,
    this.paymentType = 'EMI',
    this.installmentNumber,
    this.paymentDate,
    this.transactionReference,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'emiPlanId': emiPlanId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentType': paymentType,
      if (installmentNumber != null) 'installmentNumber': installmentNumber,
      if (paymentDate != null) 'paymentDate': paymentDate,
      if (transactionReference != null && transactionReference!.isNotEmpty)
        'transactionReference': transactionReference,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
