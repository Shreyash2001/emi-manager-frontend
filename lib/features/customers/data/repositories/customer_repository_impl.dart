import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:mobile_emi_manager/features/customers/data/models/customer_models.dart';
import 'package:mobile_emi_manager/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource _remoteDataSource;

  CustomerRepositoryImpl({required CustomerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<CustomerListResponse> listCustomers({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      return await _remoteDataSource.listCustomers(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<CreateCustomerResponseModel> createCustomer(
    CreateCustomerRequestModel request,
  ) async {
    try {
      return await _remoteDataSource.createCustomer(request);
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerDetails(String id) async {
    try {
      return await _remoteDataSource.getCustomerDetails(id);
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }
}
