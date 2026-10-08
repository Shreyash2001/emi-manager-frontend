import 'package:mobile_emi_manager/features/customers/data/models/customer_models.dart';

abstract class CustomerRepository {
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
