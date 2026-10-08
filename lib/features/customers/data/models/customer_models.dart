/// List item model for a customer returned by GET /customers
class CustomerListItemModel {
  final String id;
  final String name;
  final String mobileNumber;
  final String? status; // EMI plan status: ON_TRACK, OVERDUE, DUE_TODAY, CLEARED
  final String? deviceName;
  final String? imei;
  final int? currentEmiNumber;
  final int? totalEmiMonths;
  final double? installmentAmount;
  final double? outstandingAmount;
  final double? paidAmount;
  final String? email;
  final String? address;
  final String? nextDueDateLabel;
  final int? overdueDays;
  final List<dynamic>? emiPlans;

  const CustomerListItemModel({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.status,
    this.deviceName,
    this.imei,
    this.currentEmiNumber,
    this.totalEmiMonths,
    this.installmentAmount,
    this.outstandingAmount,
    this.paidAmount,
    this.email,
    this.address,
    this.nextDueDateLabel,
    this.overdueDays,
    this.emiPlans,
  });

  factory CustomerListItemModel.fromJson(Map<String, dynamic> json) {
    final emiPlans = json['emiPlans'] as List<dynamic>?;
    final firstPlan = (emiPlans != null && emiPlans.isNotEmpty)
        ? emiPlans.first as Map<String, dynamic>?
        : null;
    final handset = firstPlan?['handset'] as Map<String, dynamic>?;
    final activeLoan = json['activeLoan'] as Map<String, dynamic>?;

    final deviceName = json['deviceName'] as String? ??
        firstPlan?['deviceName'] as String? ??
        (handset != null && (handset['brand'] != null || handset['modelName'] != null)
            ? '${handset['brand'] ?? ''} ${handset['modelName'] ?? ''}'.trim()
            : null) ??
        (activeLoan != null
            ? '${activeLoan['brand'] ?? ''} ${activeLoan['model'] ?? ''}'.trim()
            : null);

    final imei = json['imei'] as String? ??
        firstPlan?['imei'] as String? ??
        handset?['imei'] as String? ??
        activeLoan?['imei'] as String?;

    final status = json['status'] as String? ??
        firstPlan?['status'] as String? ??
        activeLoan?['status'] as String?;

    final currentEmiNumber = (json['currentEmiNumber'] as num?)?.toInt() ??
        (firstPlan?['currentEmiNumber'] as num?)?.toInt() ??
        (firstPlan?['paidInstallments'] as num?)?.toInt() ??
        (activeLoan?['emiPaid'] as num?)?.toInt();

    final totalEmiMonths = (json['totalEmiMonths'] as num?)?.toInt() ??
        (firstPlan?['totalEmiMonths'] as num?)?.toInt() ??
        (firstPlan?['tenureMonths'] as num?)?.toInt() ??
        (activeLoan?['emiTotal'] as num?)?.toInt();

    final installmentAmount = (json['installmentAmount'] as num?)?.toDouble() ??
        (firstPlan?['installmentAmount'] as num?)?.toDouble() ??
        (firstPlan?['monthlyInstallment'] as num?)?.toDouble() ??
        (activeLoan?['monthlyEmi'] as num?)?.toDouble();

    final outstandingAmount = (json['outstandingAmount'] as num?)?.toDouble() ??
        (firstPlan?['outstandingAmount'] as num?)?.toDouble() ??
        (json['overdueAmount'] as num?)?.toDouble() ??
        (activeLoan != null
            ? ((activeLoan['principal'] as num?)?.toDouble() ?? 0.0) -
                ((json['totalRecovered'] as num?)?.toDouble() ?? 0.0)
            : null);

    final paidAmount = (json['paidAmount'] as num?)?.toDouble() ??
        (firstPlan?['paidAmount'] as num?)?.toDouble() ??
        (json['totalRecovered'] as num?)?.toDouble();

    final nextDueDateLabel = json['nextDueDate'] as String? ??
        firstPlan?['nextDueDate'] as String? ??
        json['upcomingDate'] as String?;

    final overdueDays = (json['overdueDays'] as num?)?.toInt() ??
        (firstPlan?['overdueDays'] as num?)?.toInt();

    return CustomerListItemModel(
      id: json['id'] as String? ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      mobileNumber: json['phone'] as String? ?? json['mobileNumber'] as String? ?? '',
      status: status,
      deviceName: deviceName,
      imei: imei,
      currentEmiNumber: currentEmiNumber,
      totalEmiMonths: totalEmiMonths,
      installmentAmount: installmentAmount,
      outstandingAmount: outstandingAmount,
      paidAmount: paidAmount,
      email: json['email'] as String?,
      address: json['address'] as String?,
      nextDueDateLabel: nextDueDateLabel,
      overdueDays: overdueDays,
      emiPlans: emiPlans,
    );
  }
}

/// Paginated list response wrapper
class CustomerListResponse {
  final List<CustomerListItemModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const CustomerListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> target = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      target = json['data'] as Map<String, dynamic>;
    }

    final itemsList = (target['items'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        [];

    final items = itemsList
        .map((e) => CustomerListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final pagination = (target['pagination'] as Map<String, dynamic>?) ??
        (json['pagination'] as Map<String, dynamic>?) ??
        {};

    return CustomerListResponse(
      items: items,
      total: (pagination['totalCount'] as num?)?.toInt() ??
          (pagination['total'] as num?)?.toInt() ??
          items.length,
      page: (pagination['currentPage'] as num?)?.toInt() ??
          (pagination['page'] as num?)?.toInt() ??
          1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Create customer request model supporting both EMI and CASH sales
class CreateCustomerRequestModel {
  final String saleType; // "EMI" | "CASH"
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? address;
  final String? aadhaarNumber;
  final String brand;
  final String modelName;
  final String? imei;
  final String? storageVariant;
  final String? color;
  final String? notes;
  final double sellingPrice;
  final double downPayment;
  final double loanAmount;
  final int tenureMonths;
  final double monthlyInstallment;
  final String? firstEmiDueDate;
  final String downPaymentMethod;
  final String? downPaymentReference;

  const CreateCustomerRequestModel({
    required this.saleType,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.address,
    this.aadhaarNumber,
    required this.brand,
    required this.modelName,
    this.imei,
    this.storageVariant,
    this.color,
    this.notes,
    required this.sellingPrice,
    this.downPayment = 0.0,
    this.loanAmount = 0.0,
    this.tenureMonths = 0,
    this.monthlyInstallment = 0.0,
    this.firstEmiDueDate,
    this.downPaymentMethod = 'CASH',
    this.downPaymentReference,
  });

  Map<String, dynamic> toJson() {
    final customerMap = <String, dynamic>{
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (aadhaarNumber != null && aadhaarNumber!.isNotEmpty)
        'aadhaarNumber': aadhaarNumber,
    };

    if (saleType == 'CASH') {
      return {
        'saleType': 'CASH',
        'customer': customerMap,
        'device': {
          'brand': brand,
          'modelName': modelName,
          if (imei != null && imei!.isNotEmpty) 'imei': imei,
          if (storageVariant != null && storageVariant!.isNotEmpty)
            'storageVariant': storageVariant,
          if (color != null && color!.isNotEmpty) 'color': color,
          if (notes != null && notes!.isNotEmpty) 'notes': notes,
          'sellingPrice': sellingPrice,
        },
      };
    } else {
      final dueDate = firstEmiDueDate ??
          DateTime.utc(DateTime.now().year, DateTime.now().month + 1, DateTime.now().day)
              .toIso8601String();

      return {
        'saleType': 'EMI',
        'customer': customerMap,
        'device': {
          'brand': brand,
          'modelName': modelName,
          if (imei != null && imei!.isNotEmpty) 'imei': imei,
          if (storageVariant != null && storageVariant!.isNotEmpty)
            'storageVariant': storageVariant,
          if (color != null && color!.isNotEmpty) 'color': color,
          if (notes != null && notes!.isNotEmpty) 'notes': notes,
        },
        'emiTerms': {
          'sellingPrice': sellingPrice,
          'downPayment': downPayment,
          'loanAmount': loanAmount,
          'tenureMonths': tenureMonths,
          'monthlyInstallment': monthlyInstallment,
          'firstEmiDueDate': dueDate,
          'downPaymentMethod': downPaymentMethod,
          if (downPaymentReference != null && downPaymentReference!.isNotEmpty)
            'downPaymentReference': downPaymentReference,
        },
      };
    }
  }
}

/// Response model after creating a customer
class CreateCustomerResponseModel {
  final String customerId;
  final String emiPlanId;
  final String? handsetId;

  const CreateCustomerResponseModel({
    required this.customerId,
    required this.emiPlanId,
    this.handsetId,
  });

  factory CreateCustomerResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> target = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      target = json['data'] as Map<String, dynamic>;
    }

    String custId = '';
    String emiId = '';
    String? hId;

    if (target['customer'] is Map) {
      final c = target['customer'] as Map;
      custId = c['_id']?.toString() ?? c['id']?.toString() ?? '';
    } else {
      custId = target['customerId']?.toString() ??
          target['id']?.toString() ??
          target['_id']?.toString() ??
          '';
    }

    if (target['emiPlan'] is Map) {
      final e = target['emiPlan'] as Map;
      emiId = e['_id']?.toString() ?? e['id']?.toString() ?? '';
    } else {
      emiId = target['emiPlanId']?.toString() ?? '';
    }

    if (target['handset'] is Map) {
      final h = target['handset'] as Map;
      hId = h['_id']?.toString() ?? h['id']?.toString();
    } else {
      hId = target['handsetId']?.toString();
    }

    return CreateCustomerResponseModel(
      customerId: custId,
      emiPlanId: emiId,
      handsetId: hId,
    );
  }
}
