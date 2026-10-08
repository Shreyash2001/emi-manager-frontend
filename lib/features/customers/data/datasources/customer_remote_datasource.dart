import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/features/customers/data/models/customer_models.dart';

abstract class CustomerRemoteDataSource {
  Future<CustomerListResponse> listCustomers({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  });

  Future<CreateCustomerResponseModel> createCustomer(
    CreateCustomerRequestModel request,
  );

  Future<Map<String, dynamic>> getCustomerDetails(String id);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final ApiClient _apiClient;

  CustomerRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<CustomerListResponse> listCustomers({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (category != null && category != 'All') 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiClient.get<CustomerListResponse>(
      ApiEndpoints.customers,
      queryParameters: queryParams,
      fromJson: (json) =>
          CustomerListResponse.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<CreateCustomerResponseModel> createCustomer(
    CreateCustomerRequestModel request,
  ) async {
    final response = await _apiClient.post<CreateCustomerResponseModel>(
      ApiEndpoints.customers,
      data: request.toJson(),
      fromJson: (json) =>
          CreateCustomerResponseModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> getCustomerDetails(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.customerDetails(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response.data!;
  }
}
