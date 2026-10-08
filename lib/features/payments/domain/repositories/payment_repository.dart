import 'package:mobile_emi_manager/features/payments/data/models/payment_models.dart';

abstract class PaymentRepository {
  Future<PaymentListResponse> listPayments({
    int page = 1,
    int limit = 20,
    String? emiPlanId,
    String? customerId,
  });

  Future<PaymentModel> recordPayment(RecordPaymentRequestModel request);
}
