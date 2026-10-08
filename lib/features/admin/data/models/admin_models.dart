class AdminDashboardModel {
  final int totalStores;
  final int activeStores;
  final int totalCustomers;
  final double totalCollection;

  const AdminDashboardModel({
    required this.totalStores,
    required this.activeStores,
    required this.totalCustomers,
    required this.totalCollection,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalStores: (json['totalStores'] as num?)?.toInt() ?? 0,
      activeStores: (json['activeStores'] as num?)?.toInt() ?? 0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalCollection: (json['totalCollection'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StoreModel {
  final String id;
  final String name;
  final String ownerName;
  final String mobileNumber;
  final String status;
  final String? email;
  final String? address;
  final int totalCustomers;
  final double totalCollection;

  const StoreModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.mobileNumber,
    required this.status,
    this.email,
    this.address,
    required this.totalCustomers,
    required this.totalCollection,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String? ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      email: json['email'] as String?,
      address: json['address'] as String?,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalCollection: (json['totalCollection'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StoreListResponse {
  final List<StoreModel> items;
  final int total;
  final int page;
  final int totalPages;

  const StoreListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory StoreListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return StoreListResponse(
      items: items,
      total: (pagination['total'] as num?)?.toInt() ?? items.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class CreateStoreRequestModel {
  final String name;
  final String ownerName;
  final String mobileNumber;
  final String password;
  final String? email;
  final String? address;

  const CreateStoreRequestModel({
    required this.name,
    required this.ownerName,
    required this.mobileNumber,
    required this.password,
    this.email,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ownerName': ownerName,
      'mobileNumber': mobileNumber,
      'password': password,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (address != null && address!.isNotEmpty) 'address': address,
    };
  }
}
