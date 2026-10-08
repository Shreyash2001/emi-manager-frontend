import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:mobile_emi_manager/features/payments/data/models/payment_models.dart';
import 'package:mobile_emi_manager/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  PaymentRepositoryImpl({required PaymentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<PaymentListResponse> listPayments({
    int page = 1,
    int limit = 20,
    String? emiPlanId,
    String? customerId,
  }) async {
    try {
      return await _remoteDataSource.listPayments(
        page: page,
        limit: limit,
        emiPlanId: emiPlanId,
        customerId: customerId,
      );
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<PaymentModel> recordPayment(RecordPaymentRequestModel request) async {
    try {
      return await _remoteDataSource.recordPayment(request);
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }
}
