import 'package:mobile_emi_manager/core/constants/api_constants.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';
import 'package:mobile_emi_manager/features/reports/data/models/reports_models.dart';

abstract class ReportsRemoteDataSource {
  Future<ReportsSummaryModel> getSummary();
  Future<List<MonthlyTrendModel>> getMonthlyTrend({String? year});
  Future<List<WeeklyCollectionModel>> getWeeklyCollection();
  Future<List<SmartphoneBreakdownModel>> getSmartphoneBreakdown();
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final ApiClient _apiClient;

  ReportsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ReportsSummaryModel> getSummary() async {
    final response = await _apiClient.get<ReportsSummaryModel>(
      ApiEndpoints.reportsSummary,
      fromJson: (json) =>
          ReportsSummaryModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<List<MonthlyTrendModel>> getMonthlyTrend({String? year}) async {
    final queryParams = <String, dynamic>{
      if (year != null) 'year': year,
    };
    final response = await _apiClient.get<List<MonthlyTrendModel>>(
      ApiEndpoints.monthlyTrend,
      queryParameters: queryParams,
      fromJson: (json) => (json as List<dynamic>)
          .map((e) => MonthlyTrendModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data!;
  }

  @override
  Future<List<WeeklyCollectionModel>> getWeeklyCollection() async {
    final response = await _apiClient.get<List<WeeklyCollectionModel>>(
      ApiEndpoints.weeklyCollection,
      fromJson: (json) => (json as List<dynamic>)
          .map(
              (e) => WeeklyCollectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data!;
  }

  @override
  Future<List<SmartphoneBreakdownModel>> getSmartphoneBreakdown() async {
    final response = await _apiClient.get<List<SmartphoneBreakdownModel>>(
      ApiEndpoints.smartphoneBreakdown,
      fromJson: (json) => (json as List<dynamic>)
          .map((e) =>
              SmartphoneBreakdownModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data!;
  }
}
