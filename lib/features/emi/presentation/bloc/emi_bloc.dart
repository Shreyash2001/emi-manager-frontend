import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/emi/data/models/emi_plan_model.dart';
import 'package:mobile_emi_manager/features/emi/domain/repositories/emi_repository.dart';

// ─── Domain Entity ────────────────────────────────────────────────────────────

class EMIPlan extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String handsetModel;
  final double totalAmount;
  final double emiAmount;
  final int totalInstallments;
  final int paidInstallments;
  final int remainingInstallments;
  final String status;
  final DateTime? startDate;
  final DateTime? nextDueDate;
  final String? handsetBrand;
  final String? imei;
  final double? downPayment;
  final double? outstandingAmount;
  final String? notes;

  const EMIPlan({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.handsetModel,
    required this.totalAmount,
    required this.emiAmount,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.remainingInstallments,
    required this.status,
    this.startDate,
    this.nextDueDate,
    this.handsetBrand,
    this.imei,
    this.downPayment,
    this.outstandingAmount,
    this.notes,
  });

  @override
  List<Object?> get props => [id, customerId, status];
}

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class EMIEvent extends Equatable {
  const EMIEvent();
  @override
  List<Object?> get props => [];
}

class LoadEMIPlan extends EMIEvent {
  final String emiPlanId;
  const LoadEMIPlan({required this.emiPlanId});
  @override
  List<Object?> get props => [emiPlanId];
}

class RefreshEMIPlan extends EMIEvent {
  final String emiPlanId;
  const RefreshEMIPlan({required this.emiPlanId});
  @override
  List<Object?> get props => [emiPlanId];
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class EMIState extends Equatable {
  const EMIState();
  @override
  List<Object?> get props => [];
}

class EMIInitial extends EMIState {
  const EMIInitial();
}

class EMILoading extends EMIState {
  const EMILoading();
}

class EMILoaded extends EMIState {
  final EMIPlan emiPlan;
  const EMILoaded({required this.emiPlan});
  @override
  List<Object?> get props => [emiPlan];
}

class EMIError extends EMIState {
  final AppFailure failure;
  const EMIError({required this.failure});
  @override
  List<Object?> get props => [failure];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

/// EMIBloc — connects to GET /api/v1/emi-plans/:id
class EMIBloc extends Bloc<EMIEvent, EMIState> {
  final EmiRepository _emiRepository;

  EMIBloc({required EmiRepository emiRepository})
      : _emiRepository = emiRepository,
        super(const EMIInitial()) {
    on<LoadEMIPlan>(_onLoadEMIPlan);
    on<RefreshEMIPlan>(_onRefreshEMIPlan);
  }

  Future<void> _onLoadEMIPlan(
    LoadEMIPlan event,
    Emitter<EMIState> emit,
  ) async {
    AppLogger.bloc('EMIBloc', 'LoadEMIPlan: ${event.emiPlanId}');
    emit(const EMILoading());
    try {
      final model = await _emiRepository.getEmiPlan(event.emiPlanId);
      emit(EMILoaded(emiPlan: _toEMIPlan(model)));
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('EMIBloc error: $failure');
      emit(EMIError(failure: failure));
    }
  }

  Future<void> _onRefreshEMIPlan(
    RefreshEMIPlan event,
    Emitter<EMIState> emit,
  ) async {
    AppLogger.bloc('EMIBloc', 'RefreshEMIPlan');
    add(LoadEMIPlan(emiPlanId: event.emiPlanId));
  }

  EMIPlan _toEMIPlan(EmiPlanModel model) {
    return EMIPlan(
      id: model.id,
      customerId: model.customerId,
      customerName: model.customerName,
      handsetModel: '${model.handsetBrand} ${model.handsetModel}'.trim(),
      totalAmount: model.loanAmount,
      emiAmount: model.monthlyInstallment,
      totalInstallments: model.tenureMonths,
      paidInstallments: model.paidInstallments,
      remainingInstallments: model.remainingInstallments,
      status: model.status,
      startDate: model.startDate,
      nextDueDate: model.nextDueDate,
      handsetBrand: model.handsetBrand,
      imei: model.imei,
      downPayment: model.downPayment,
      outstandingAmount: model.outstandingAmount,
      notes: model.notes,
    );
  }
}
