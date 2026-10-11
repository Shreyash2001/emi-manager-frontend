import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/payments/data/models/payment_models.dart';
import 'package:mobile_emi_manager/features/payments/domain/repositories/payment_repository.dart';
import 'package:mobile_emi_manager/features/reports/data/models/reports_models.dart';
import 'package:mobile_emi_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/network/api_cache_manager.dart';

// ─── Domain Entities ──────────────────────────────────────────────────────────

class ReportsSummary extends Equatable {
  final double totalRevenue;
  final double monthlyRevenue;
  final int totalCustomers;
  final int activeEmiPlans;
  final double collectionRate;
  final double overdueAmount;

  const ReportsSummary({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.totalCustomers,
    required this.activeEmiPlans,
    required this.collectionRate,
    required this.overdueAmount,
  });

  @override
  List<Object?> get props => [totalRevenue, monthlyRevenue];
}

class MonthlyTrend extends Equatable {
  final String month;
  final double collected;
  final double pending;

  const MonthlyTrend({
    required this.month,
    required this.collected,
    required this.pending,
  });

  @override
  List<Object?> get props => [month];
}

class WeeklyCollection extends Equatable {
  final String week;
  final double amount;

  const WeeklyCollection({required this.week, required this.amount});

  @override
  List<Object?> get props => [week];
}

class SmartphoneBreakdown extends Equatable {
  final String brand;
  final int count;
  final double totalValue;

  const SmartphoneBreakdown({
    required this.brand,
    required this.count,
    required this.totalValue,
  });

  @override
  List<Object?> get props => [brand];
}

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

class LoadReportsSummary extends ReportsEvent {
  const LoadReportsSummary();
}

class LoadMonthlyTrend extends ReportsEvent {
  final String? month;
  const LoadMonthlyTrend({this.month});
  @override
  List<Object?> get props => [month];
}

class LoadWeeklyCollection extends ReportsEvent {
  const LoadWeeklyCollection();
}

class LoadSmartphoneBreakdown extends ReportsEvent {
  const LoadSmartphoneBreakdown();
}

class RefreshReports extends ReportsEvent {
  const RefreshReports();
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsSummaryLoaded extends ReportsState {
  final ReportsSummary summary;
  final List<MonthlyTrend> monthlyTrend;
  final List<WeeklyCollection> weeklyCollection;
  final List<SmartphoneBreakdown> smartphones;
  final List<PaymentModel> recentTransactions;

  const ReportsSummaryLoaded({
    required this.summary,
    required this.monthlyTrend,
    required this.weeklyCollection,
    required this.smartphones,
    required this.recentTransactions,
  });

  @override
  List<Object?> get props =>
      [summary, monthlyTrend, weeklyCollection, smartphones, recentTransactions];
}

class ReportsError extends ReportsState {
  final AppFailure failure;
  const ReportsError({required this.failure});
  @override
  List<Object?> get props => [failure];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

/// ReportsBloc — connects to all /api/v1/reports/* endpoints & payments history
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository _reportsRepository;
  final PaymentRepository _paymentRepository;

  ReportsBloc({
    required ReportsRepository reportsRepository,
    required PaymentRepository paymentRepository,
  })  : _reportsRepository = reportsRepository,
        _paymentRepository = paymentRepository,
        super(const ReportsInitial()) {
    on<LoadReportsSummary>(_onLoadReportsSummary);
    on<LoadMonthlyTrend>(_onLoadMonthlyTrend);
    on<LoadWeeklyCollection>(_onLoadWeeklyCollection);
    on<LoadSmartphoneBreakdown>(_onLoadSmartphoneBreakdown);
    on<RefreshReports>(_onRefreshReports);
  }

  Future<void> _onLoadReportsSummary(
    LoadReportsSummary event,
    Emitter<ReportsState> emit,
  ) async {
    AppLogger.bloc('ReportsBloc', 'LoadReportsSummary');
    emit(const ReportsLoading());
    try {
      // Fetch report endpoints and recent payments in parallel
      List<PaymentModel> payments = [];
      final results = await Future.wait([
        _reportsRepository.getSummary(),
        _reportsRepository.getMonthlyTrend(),
        _reportsRepository.getWeeklyCollection(),
        _reportsRepository.getSmartphoneBreakdown(),
        _paymentRepository.listPayments(limit: 100).then((res) => res.items).catchError((_) => <PaymentModel>[]),
      ]);

      final summaryModel = results[0] as ReportsSummaryModel;
      final monthlyModels = results[1] as List<MonthlyTrendModel>;
      final weeklyModels = results[2] as List<WeeklyCollectionModel>;
      final smartphoneModels = results[3] as List<SmartphoneBreakdownModel>;
      payments = results[4] as List<PaymentModel>;

      emit(ReportsSummaryLoaded(
        summary: ReportsSummary(
          totalRevenue: summaryModel.totalRevenue,
          monthlyRevenue: summaryModel.monthlyRevenue,
          totalCustomers: summaryModel.totalCustomers,
          activeEmiPlans: summaryModel.activeEmiPlans,
          collectionRate: summaryModel.collectionRate,
          overdueAmount: summaryModel.overdueAmount,
        ),
        monthlyTrend: monthlyModels
            .map((m) => MonthlyTrend(
                  month: m.month,
                  collected: m.collected,
                  pending: m.pending,
                ))
            .toList(),
        weeklyCollection: weeklyModels
            .map((w) => WeeklyCollection(week: w.week, amount: w.amount))
            .toList(),
        smartphones: smartphoneModels
            .map((s) => SmartphoneBreakdown(
                  brand: s.brand,
                  count: s.count,
                  totalValue: s.totalValue,
                ))
            .toList(),
        recentTransactions: payments,
      ));
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('ReportsBloc error: $failure');
      emit(ReportsError(failure: failure));
    }
  }

  Future<void> _onLoadMonthlyTrend(
    LoadMonthlyTrend event,
    Emitter<ReportsState> emit,
  ) async {
    AppLogger.bloc('ReportsBloc', 'LoadMonthlyTrend');
    // This is handled as part of the full load; no separate state needed.
    add(const LoadReportsSummary());
  }

  Future<void> _onLoadWeeklyCollection(
    LoadWeeklyCollection event,
    Emitter<ReportsState> emit,
  ) async {
    AppLogger.bloc('ReportsBloc', 'LoadWeeklyCollection');
    add(const LoadReportsSummary());
  }

  Future<void> _onLoadSmartphoneBreakdown(
    LoadSmartphoneBreakdown event,
    Emitter<ReportsState> emit,
  ) async {
    AppLogger.bloc('ReportsBloc', 'LoadSmartphoneBreakdown');
    add(const LoadReportsSummary());
  }

  Future<void> _onRefreshReports(
    RefreshReports event,
    Emitter<ReportsState> emit,
  ) async {
    AppLogger.bloc('ReportsBloc', 'RefreshReports');
    sl<ApiCacheManager>().invalidate('/reports');
    sl<ApiCacheManager>().invalidate(ApiEndpoints.payments);
    add(const LoadReportsSummary());
  }
}
