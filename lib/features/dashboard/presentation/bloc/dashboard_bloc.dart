import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/dashboard/data/models/dashboard_model.dart';
import 'package:mobile_emi_manager/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'dashboard_bloc_exports.dart';
export 'dashboard_bloc_exports.dart';

/// DashboardBloc — connects to GET /api/v1/dashboard
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardBloc({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    AppLogger.bloc('DashboardBloc', 'LoadDashboard');
    emit(const DashboardLoading());
    try {
      final model = await _dashboardRepository.getDashboard();
      emit(DashboardLoaded(summary: _toSummary(model)));
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('DashboardBloc error: $failure');
      emit(DashboardError(failure: failure));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    AppLogger.bloc('DashboardBloc', 'RefreshDashboard');
    add(const LoadDashboard());
  }

  DashboardSummary _toSummary(DashboardModel model) {
    return DashboardSummary(
      totalCustomers: model.totalCustomers,
      newCustomersThisMonth: model.newCustomersThisMonth,
      activeCustomers: model.activeCustomers,
      activeEmis: model.activeEmis,
      activeLoanAmount: model.activeLoanAmount,
      totalCollection: model.totalCollection,
      pendingAmount: model.pendingAmount,
      overdueCount: model.overdueCount,
      monthlyCollection: model.monthlyCollection,
      storeName: model.storeName,
      storeLocation: model.storeLocation ?? '',
      ownerName: model.ownerName,
    );
  }
}
