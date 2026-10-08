import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:mobile_emi_manager/features/dashboard/data/models/dashboard_model.dart';
import 'package:mobile_emi_manager/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl({required DashboardRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<DashboardModel> getDashboard() async {
    try {
      return await _remoteDataSource.getDashboard();
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }
}
