import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/payments/data/models/payment_models.dart';
import 'package:mobile_emi_manager/features/payments/domain/repositories/payment_repository.dart';

// ─── Domain Entity ────────────────────────────────────────────────────────────

class Payment extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String emiPlanId;
  final double amount;
  final String method;
  final int installmentNumber;
  final DateTime? paymentDate;
  final String status;
  final String? receiptNumber;
  final String? transactionReference;

  const Payment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.emiPlanId,
    required this.amount,
    required this.method,
    required this.installmentNumber,
    this.paymentDate,
    required this.status,
    this.receiptNumber,
    this.transactionReference,
  });

  @override
  List<Object?> get props => [id];
}

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class LoadPaymentHistory extends PaymentEvent {
  final String? emiPlanId;
  final String? customerId;
  const LoadPaymentHistory({this.emiPlanId, this.customerId});
  @override
  List<Object?> get props => [emiPlanId, customerId];
}

class RefreshPayments extends PaymentEvent {
  final String? emiPlanId;
  final String? customerId;
  const RefreshPayments({this.emiPlanId, this.customerId});
  @override
  List<Object?> get props => [emiPlanId, customerId];
}

class RecordPayment extends PaymentEvent {
  final String customerId;
  final String emiPlanId;
  final double amount;
  final String method; // CASH | UPI | UPI_AUTOPAY | CARD
  final String paymentType; // EMI | DOWN_PAYMENT
  final int? installmentNumber;
  final String? transactionReference;
  final String? notes;

  const RecordPayment({
    required this.customerId,
    required this.emiPlanId,
    required this.amount,
    required this.method,
    this.paymentType = 'EMI',
    this.installmentNumber,
    this.transactionReference,
    this.notes,
  });

  @override
  List<Object?> get props => [emiPlanId, amount, method];
}

class LoadMorePayments extends PaymentEvent {
  const LoadMorePayments();
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentSubmitting extends PaymentState {
  const PaymentSubmitting();
}

class PaymentsLoaded extends PaymentState {
  final List<Payment> payments;
  final bool hasMore;
  final int currentPage;
  const PaymentsLoaded({
    required this.payments,
    required this.hasMore,
    this.currentPage = 1,
  });
  @override
  List<Object?> get props => [payments, hasMore, currentPage];
}

class PaymentRecorded extends PaymentState {
  final Payment payment;
  const PaymentRecorded({required this.payment});
  @override
  List<Object?> get props => [payment];
}

class PaymentError extends PaymentState {
  final AppFailure failure;
  const PaymentError({required this.failure});
  @override
  List<Object?> get props => [failure];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

/// PaymentBloc — connects to POST/GET /api/v1/payments
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  List<Payment> _currentPayments = [];
  String? _emiPlanId;
  String? _customerId;

  PaymentBloc({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(const PaymentInitial()) {
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<RefreshPayments>(_onRefreshPayments);
    on<RecordPayment>(_onRecordPayment);
    on<LoadMorePayments>(_onLoadMorePayments);
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    AppLogger.bloc('PaymentBloc', 'LoadPaymentHistory');
    _emiPlanId = event.emiPlanId;
    _customerId = event.customerId;
    emit(const PaymentLoading());
    try {
      final result = await _paymentRepository.listPayments(
        page: 1,
        limit: 20,
        emiPlanId: event.emiPlanId,
        customerId: event.customerId,
      );
      _currentPayments = result.items.map(_toPayment).toList();
      emit(PaymentsLoaded(
        payments: _currentPayments,
        hasMore: result.page < result.totalPages,
        currentPage: result.page,
      ));
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('PaymentBloc error: $failure');
      emit(PaymentError(failure: failure));
    }
  }

  Future<void> _onRefreshPayments(
    RefreshPayments event,
    Emitter<PaymentState> emit,
  ) async {
    add(LoadPaymentHistory(
      emiPlanId: event.emiPlanId ?? _emiPlanId,
      customerId: event.customerId ?? _customerId,
    ));
  }

  Future<void> _onRecordPayment(
    RecordPayment event,
    Emitter<PaymentState> emit,
  ) async {
    AppLogger.bloc('PaymentBloc', 'RecordPayment');
    emit(const PaymentSubmitting());
    try {
      final request = RecordPaymentRequestModel(
        customerId: event.customerId,
        emiPlanId: event.emiPlanId,
        amount: event.amount,
        paymentMethod: event.method,
        paymentType: event.paymentType,
        installmentNumber: event.installmentNumber,
        transactionReference: event.transactionReference,
        notes: event.notes,
      );
      final model = await _paymentRepository.recordPayment(request);
      emit(PaymentRecorded(payment: _toPayment(model)));
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('PaymentBloc RecordPayment error: $failure');
      emit(PaymentError(failure: failure));
    }
  }

  Future<void> _onLoadMorePayments(
    LoadMorePayments event,
    Emitter<PaymentState> emit,
  ) async {
    final current = state;
    if (current is! PaymentsLoaded || !current.hasMore) return;
    AppLogger.bloc(
        'PaymentBloc', 'LoadMorePayments page ${current.currentPage + 1}');
    try {
      final result = await _paymentRepository.listPayments(
        page: current.currentPage + 1,
        limit: 20,
        emiPlanId: _emiPlanId,
        customerId: _customerId,
      );
      final newPayments = result.items.map(_toPayment).toList();
      _currentPayments = [..._currentPayments, ...newPayments];
      emit(PaymentsLoaded(
        payments: _currentPayments,
        hasMore: result.page < result.totalPages,
        currentPage: result.page,
      ));
    } catch (e) {
      AppLogger.error('PaymentBloc LoadMore error: ${ErrorMapper.toFailure(e)}');
    }
  }

  // ─── Mapper: API model → Domain entity ──────────────────────────────────
  Payment _toPayment(PaymentModel model) {
    return Payment(
      id: model.id,
      customerId: model.customerId,
      customerName: model.customerName,
      emiPlanId: model.emiPlanId,
      amount: model.amount,
      method: model.paymentMethod,
      installmentNumber: model.installmentNumber ?? 0,
      paymentDate: model.paymentDate,
      status: model.status,
      receiptNumber: model.receiptNumber,
      transactionReference: model.transactionReference,
    );
  }
}
