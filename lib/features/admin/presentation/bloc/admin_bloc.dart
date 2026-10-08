import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/admin/data/models/admin_models.dart';
import 'package:mobile_emi_manager/features/admin/domain/repositories/admin_repository.dart';

// ─── Domain Entity ────────────────────────────────────────────────────────────

class Store extends Equatable {
  final String id;
  final String name;
  final String ownerName;
  final String mobileNumber;
  final String status;
  final String? email;
  final String? address;
  final int totalCustomers;
  final double totalCollection;

  const Store({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.mobileNumber,
    required this.status,
    this.email,
    this.address,
    required this.totalCustomers,
    required this.totalCollection,
  });

  @override
  List<Object?> get props => [id, status];
}

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminDashboard extends AdminEvent {
  const LoadAdminDashboard();
}

class LoadStores extends AdminEvent {
  const LoadStores();
}

class RefreshStores extends AdminEvent {
  const RefreshStores();
}

class SearchStores extends AdminEvent {
  final String query;
  const SearchStores({required this.query});
  @override
  List<Object?> get props => [query];
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class StoresLoaded extends AdminState {
  final List<Store> stores;
  final bool hasMore;
  const StoresLoaded({required this.stores, required this.hasMore});
  @override
  List<Object?> get props => [stores, hasMore];
}

class AdminError extends AdminState {
  final AppFailure failure;
  const AdminError({required this.failure});
  @override
  List<Object?> get props => [failure];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

/// AdminBloc — SUPER_ADMIN only. Connects to all /api/v1/admin/* endpoints.
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _adminRepository;

  AdminBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const AdminInitial()) {
    on<LoadAdminDashboard>(_onLoadAdminDashboard);
    on<LoadStores>(_onLoadStores);
    on<RefreshStores>(_onRefreshStores);
    on<SearchStores>(_onSearchStores);
  }

  Future<void> _onLoadAdminDashboard(
    LoadAdminDashboard event,
    Emitter<AdminState> emit,
  ) async {
    AppLogger.bloc('AdminBloc', 'LoadAdminDashboard');
    emit(const AdminLoading());
    try {
      // Also trigger stores load after dashboard
      add(const LoadStores());
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      emit(AdminError(failure: failure));
    }
  }

  Future<void> _onLoadStores(
    LoadStores event,
    Emitter<AdminState> emit,
  ) async {
    AppLogger.bloc('AdminBloc', 'LoadStores');
    emit(const AdminLoading());
    try {
      final result = await _adminRepository.listStores(page: 1, limit: 20);
      final stores = result.items.map(_toStore).toList();
      emit(StoresLoaded(
        stores: stores,
        hasMore: result.page < result.totalPages,
      ));
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('AdminBloc error: $failure');
      emit(AdminError(failure: failure));
    }
  }

  Future<void> _onRefreshStores(
    RefreshStores event,
    Emitter<AdminState> emit,
  ) async {
    add(const LoadStores());
  }

  Future<void> _onSearchStores(
    SearchStores event,
    Emitter<AdminState> emit,
  ) async {
    AppLogger.bloc('AdminBloc', 'SearchStores: ${event.query}');
    emit(const AdminLoading());
    try {
      final result = await _adminRepository.listStores(
        page: 1,
        limit: 20,
        search: event.query.isNotEmpty ? event.query : null,
      );
      final stores = result.items.map(_toStore).toList();
      emit(StoresLoaded(
        stores: stores,
        hasMore: result.page < result.totalPages,
      ));
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      emit(AdminError(failure: failure));
    }
  }

  Store _toStore(StoreModel model) {
    return Store(
      id: model.id,
      name: model.name,
      ownerName: model.ownerName,
      mobileNumber: model.mobileNumber,
      status: model.status,
      email: model.email,
      address: model.address,
      totalCustomers: model.totalCustomers,
      totalCollection: model.totalCollection,
    );
  }
}
