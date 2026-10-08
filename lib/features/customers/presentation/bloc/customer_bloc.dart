import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/core/utils/logger.dart';
import 'package:mobile_emi_manager/features/customers/data/models/customer_models.dart';
import 'package:mobile_emi_manager/features/customers/domain/repositories/customer_repository.dart';

// ─── Domain Entity ────────────────────────────────────────────────────────────

// ─── Domain Entity ────────────────────────────────────────────────────────────

enum CustomerStatus { overdue, dueToday, onTrack, cleared }

enum CustomerSortOption {
  overdueFirst('Overdue First'),
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  outstandingDesc('Highest Outstanding'),
  outstandingAsc('Lowest Outstanding');

  final String label;
  const CustomerSortOption(this.label);
}

class Customer extends Equatable {
  final String id;
  final String name;
  final String mobileNumber;
  final String initials;
  final CustomerStatus status;
  final String statusDetail;
  final String deviceName;
  final String imei;
  final int currentEmiNumber;
  final int totalEmiMonths;
  final String installmentLabel;
  final double installmentAmount;
  final String outstandingLabel;
  final double outstandingAmount;
  final double paidAmount;
  final String? email;
  final String? address;

  const Customer({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.initials,
    required this.status,
    required this.statusDetail,
    required this.deviceName,
    required this.imei,
    required this.currentEmiNumber,
    required this.totalEmiMonths,
    required this.installmentLabel,
    required this.installmentAmount,
    required this.outstandingLabel,
    required this.outstandingAmount,
    required this.paidAmount,
    this.email,
    this.address,
  });

  @override
  List<Object?> get props => [id, name, mobileNumber, status];
}

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  const LoadCustomers();
}

class RefreshCustomers extends CustomerEvent {
  const RefreshCustomers();
}

class SearchCustomers extends CustomerEvent {
  final String query;
  const SearchCustomers({required this.query});
  @override
  List<Object?> get props => [query];
}

class FilterCustomers extends CustomerEvent {
  final String category;
  const FilterCustomers({required this.category});
  @override
  List<Object?> get props => [category];
}

class SortCustomers extends CustomerEvent {
  final CustomerSortOption sortOption;
  const SortCustomers({required this.sortOption});
  @override
  List<Object?> get props => [sortOption];
}

class LoadMoreCustomers extends CustomerEvent {
  const LoadMoreCustomers();
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

class CustomerLoaded extends CustomerState {
  final List<Customer> allCustomers;
  final List<Customer> displayedCustomers;
  final bool hasMore;
  final int currentPage;
  final String? searchQuery;
  final String activeFilter;
  final CustomerSortOption sortOption;

  const CustomerLoaded({
    required this.allCustomers,
    required this.displayedCustomers,
    required this.hasMore,
    required this.currentPage,
    this.searchQuery,
    this.activeFilter = 'All',
    this.sortOption = CustomerSortOption.overdueFirst,
  });

  /// Alias for backward compatibility
  List<Customer> get customers => displayedCustomers;

  // Dynamic getters for status counts
  int get allCount => allCustomers.length;
  int get activeEmisCount =>
      allCustomers.where((c) => c.status != CustomerStatus.cleared).length;
  int get overdueCount =>
      allCustomers.where((c) => c.status == CustomerStatus.overdue).length;
  int get dueTodayCount =>
      allCustomers.where((c) => c.status == CustomerStatus.dueToday).length;
  int get onTrackCount =>
      allCustomers.where((c) => c.status == CustomerStatus.onTrack).length;
  int get clearedCount =>
      allCustomers.where((c) => c.status == CustomerStatus.cleared).length;

  @override
  List<Object?> get props => [
        allCustomers,
        displayedCustomers,
        hasMore,
        currentPage,
        searchQuery,
        activeFilter,
        sortOption,
      ];
}

class CustomerError extends CustomerState {
  final AppFailure failure;
  const CustomerError({required this.failure});
  @override
  List<Object?> get props => [failure];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

/// CustomerBloc — connects to GET /api/v1/customers with in-memory filter & sort
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _customerRepository;
  List<Customer> _allCustomers = [];
  String _activeFilter = 'All';
  String? _searchQuery;
  CustomerSortOption _sortOption = CustomerSortOption.overdueFirst;
  bool _hasMore = false;
  int _currentPage = 1;

  CustomerBloc({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository,
        super(const CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<RefreshCustomers>(_onRefreshCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<FilterCustomers>(_onFilterCustomers);
    on<SortCustomers>(_onSortCustomers);
    on<LoadMoreCustomers>(_onLoadMoreCustomers);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    AppLogger.bloc('CustomerBloc', 'LoadCustomers');
    _searchQuery = null;
    _activeFilter = 'All';
    _sortOption = CustomerSortOption.overdueFirst;
    emit(const CustomerLoading());
    try {
      final result = await _customerRepository.listCustomers(page: 1, limit: 100);
      _allCustomers = result.items.map(_toCustomer).toList();
      _hasMore = result.page < result.totalPages;
      _currentPage = result.page;
      _applyFilterAndSort(emit);
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('CustomerBloc error: $failure');
      emit(CustomerError(failure: failure));
    }
  }

  Future<void> _onRefreshCustomers(
    RefreshCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    AppLogger.bloc('CustomerBloc', 'RefreshCustomers');
    add(const LoadCustomers());
  }

  Future<void> _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    AppLogger.bloc('CustomerBloc', 'SearchCustomers in memory: ${event.query}');
    _searchQuery = event.query;
    _applyFilterAndSort(emit);
  }

  Future<void> _onFilterCustomers(
    FilterCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    AppLogger.bloc('CustomerBloc', 'FilterCustomers in memory: ${event.category}');
    _activeFilter = event.category;
    _applyFilterAndSort(emit);
  }

  Future<void> _onSortCustomers(
    SortCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    AppLogger.bloc('CustomerBloc', 'SortCustomers in memory: ${event.sortOption.label}');
    _sortOption = event.sortOption;
    _applyFilterAndSort(emit);
  }

  Future<void> _onLoadMoreCustomers(
    LoadMoreCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    if (!_hasMore) return;
    AppLogger.bloc('CustomerBloc', 'LoadMoreCustomers page ${_currentPage + 1}');

    try {
      final result = await _customerRepository.listCustomers(
        page: _currentPage + 1,
        limit: 100,
      );
      final newCustomers = result.items.map(_toCustomer).toList();
      _allCustomers = [..._allCustomers, ...newCustomers];
      _hasMore = result.page < result.totalPages;
      _currentPage = result.page;
      _applyFilterAndSort(emit);
    } catch (e) {
      final failure = ErrorMapper.toFailure(e);
      AppLogger.error('CustomerBloc LoadMore error: $failure');
    }
  }

  void _applyFilterAndSort(Emitter<CustomerState> emit) {
    List<Customer> filtered = List.from(_allCustomers);

    // 1. Filter by category
    if (_activeFilter == 'Active EMIs') {
      filtered = filtered.where((c) => c.status != CustomerStatus.cleared).toList();
    } else if (_activeFilter == 'Overdue') {
      filtered = filtered.where((c) => c.status == CustomerStatus.overdue).toList();
    } else if (_activeFilter == 'Due Today') {
      filtered = filtered.where((c) => c.status == CustomerStatus.dueToday).toList();
    } else if (_activeFilter == 'Paid Off' || _activeFilter == 'Cleared') {
      filtered = filtered.where((c) => c.status == CustomerStatus.cleared).toList();
    } else if (_activeFilter == 'On Track') {
      filtered = filtered.where((c) => c.status == CustomerStatus.onTrack).toList();
    }

    // 2. Filter by search query
    if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
      final q = _searchQuery!.trim().toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.mobileNumber.toLowerCase().contains(q) ||
            c.deviceName.toLowerCase().contains(q) ||
            c.imei.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Apply sorting
    switch (_sortOption) {
      case CustomerSortOption.nameAsc:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case CustomerSortOption.nameDesc:
        filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case CustomerSortOption.outstandingDesc:
        filtered.sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));
      case CustomerSortOption.outstandingAsc:
        filtered.sort((a, b) => a.outstandingAmount.compareTo(b.outstandingAmount));
      case CustomerSortOption.overdueFirst:
        filtered.sort((a, b) {
          if (a.status == CustomerStatus.overdue && b.status != CustomerStatus.overdue) return -1;
          if (a.status != CustomerStatus.overdue && b.status == CustomerStatus.overdue) return 1;
          return b.outstandingAmount.compareTo(a.outstandingAmount);
        });
    }

    emit(CustomerLoaded(
      allCustomers: _allCustomers,
      displayedCustomers: filtered,
      hasMore: _hasMore,
      currentPage: _currentPage,
      searchQuery: _searchQuery,
      activeFilter: _activeFilter,
      sortOption: _sortOption,
    ));
  }

  // ─── Mapper: API model → Domain entity ───────────────────────────────────

  Customer _toCustomer(CustomerListItemModel model) {
    final status = _parseStatus(model.status);
    final statusDetail = _buildStatusDetail(status, model.overdueDays);
    final initials = _initials(model.name);

    return Customer(
      id: model.id,
      name: model.name,
      mobileNumber: model.mobileNumber,
      initials: initials,
      status: status,
      statusDetail: statusDetail,
      deviceName: model.deviceName ?? '—',
      imei: model.imei ?? '—',
      currentEmiNumber: model.currentEmiNumber ?? 0,
      totalEmiMonths: model.totalEmiMonths ?? 0,
      installmentLabel: _installmentLabel(status),
      installmentAmount: model.installmentAmount ?? 0.0,
      outstandingLabel: 'Outstanding Balance',
      outstandingAmount: model.outstandingAmount ?? 0.0,
      paidAmount: model.paidAmount ?? 0.0,
      email: model.email,
      address: model.address,
    );
  }

  CustomerStatus _parseStatus(String? status) {
    if (status == null) return CustomerStatus.onTrack;
    final s = status.toUpperCase().replaceAll('_', '');
    if (s == 'OVERDUE') return CustomerStatus.overdue;
    if (s == 'DUETODAY') return CustomerStatus.dueToday;
    if (s == 'CLEARED') return CustomerStatus.cleared;
    return CustomerStatus.onTrack;
  }

  String _buildStatusDetail(CustomerStatus status, int? overdueDays) {
    switch (status) {
      case CustomerStatus.overdue:
        return overdueDays != null && overdueDays > 0
            ? 'OVERDUE ($overdueDays Days)'
            : 'OVERDUE';
      case CustomerStatus.dueToday:
        return 'DUE TODAY';
      case CustomerStatus.cleared:
        return 'CLEARED / NOC ISSUED';
      case CustomerStatus.onTrack:
        return 'ON TRACK';
    }
  }

  String _installmentLabel(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.dueToday:
        return "Today's EMI";
      case CustomerStatus.cleared:
        return 'Outstanding';
      default:
        return 'Monthly Installment';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
