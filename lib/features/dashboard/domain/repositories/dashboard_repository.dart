import 'package:mobile_emi_manager/features/dashboard/data/models/dashboard_model.dart';

abstract class DashboardRepository {
  Future<DashboardModel> getDashboard();
}
