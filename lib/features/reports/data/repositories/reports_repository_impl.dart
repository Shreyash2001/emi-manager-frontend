import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:mobile_emi_manager/features/reports/data/models/reports_models.dart';
import 'package:mobile_emi_manager/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource _remoteDataSource;

  ReportsRepositoryImpl({required ReportsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<ReportsSummaryModel> getSummary() async {
    try {
      return await _remoteDataSource.getSummary();
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<List<MonthlyTrendModel>> getMonthlyTrend({String? year}) async {
    try {
      return await _remoteDataSource.getMonthlyTrend(year: year);
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<List<WeeklyCollectionModel>> getWeeklyCollection() async {
    try {
      return await _remoteDataSource.getWeeklyCollection();
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<List<SmartphoneBreakdownModel>> getSmartphoneBreakdown() async {
    try {
      return await _remoteDataSource.getSmartphoneBreakdown();
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }
}
