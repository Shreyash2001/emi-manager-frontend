import 'package:mobile_emi_manager/features/reports/data/models/reports_models.dart';

abstract class ReportsRepository {
  Future<ReportsSummaryModel> getSummary();
  Future<List<MonthlyTrendModel>> getMonthlyTrend({String? year});
  Future<List<WeeklyCollectionModel>> getWeeklyCollection();
  Future<List<SmartphoneBreakdownModel>> getSmartphoneBreakdown();
}
