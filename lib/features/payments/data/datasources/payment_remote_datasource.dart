import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/features/payments/data/models/payment_models.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentListResponse> listPayments({
    int page = 1,
    int limit = 20,
    String? emiPlanId,
    String? customerId,
  });

  Future<PaymentModel> recordPayment(RecordPaymentRequestModel request);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient _apiClient;

  PaymentRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<PaymentListResponse> listPayments({
    int page = 1,
    int limit = 20,
    String? emiPlanId,
    String? customerId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (emiPlanId != null) 'emiPlanId': emiPlanId,
      if (customerId != null) 'customerId': customerId,
    };

    final response = await _apiClient.get<PaymentListResponse>(
      ApiEndpoints.payments,
      queryParameters: queryParams,
      fromJson: (json) =>
          PaymentListResponse.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<PaymentModel> recordPayment(RecordPaymentRequestModel request) async {
    final response = await _apiClient.post<PaymentModel>(
      ApiEndpoints.payments,
      data: request.toJson(),
      fromJson: (json) => PaymentModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
