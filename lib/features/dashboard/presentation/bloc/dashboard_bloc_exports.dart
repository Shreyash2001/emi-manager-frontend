import 'package:equatable/equatable.dart';
import 'package:mobile_emi_manager/core/errors/app_failure.dart';

// ─── Domain Entity ────────────────────────────────────────────────────────────

class DashboardSummary extends Equatable {
  final int totalCustomers;
  final int newCustomersThisMonth;
  final int activeCustomers;
  final int activeEmis;
  final double activeLoanAmount;
  final double totalCollection;
  final double pendingAmount;
  final int overdueCount;
  final double monthlyCollection;
  final String storeName;
  final String storeLocation;
  final String ownerName;

  const DashboardSummary({
    required this.totalCustomers,
    required this.newCustomersThisMonth,
    required this.activeCustomers,
    required this.activeEmis,
    required this.activeLoanAmount,
    required this.totalCollection,
    required this.pendingAmount,
    required this.overdueCount,
    required this.monthlyCollection,
    required this.storeName,
    required this.storeLocation,
    required this.ownerName,
  });

  @override
  List<Object?> get props => [
        totalCustomers,
        newCustomersThisMonth,
        activeCustomers,
        activeEmis,
        activeLoanAmount,
        totalCollection,
        pendingAmount,
        overdueCount,
        monthlyCollection,
        storeName,
        storeLocation,
        ownerName,
      ];
}

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  const DashboardLoaded({required this.summary});
  @override
  List<Object?> get props => [summary];
}

class DashboardError extends DashboardState {
  final AppFailure failure;
  const DashboardError({required this.failure});
  @override
  List<Object?> get props => [failure];
}
