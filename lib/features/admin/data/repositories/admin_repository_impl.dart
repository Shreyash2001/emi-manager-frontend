import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:mobile_emi_manager/features/admin/data/models/admin_models.dart';
import 'package:mobile_emi_manager/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl({required AdminRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<AdminDashboardModel> getAdminDashboard() async {
    try {
      return await _remoteDataSource.getAdminDashboard();
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<StoreListResponse> listStores({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      return await _remoteDataSource.listStores(page: page, limit: limit, search: search);
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }

  @override
  Future<StoreModel> createStore(CreateStoreRequestModel request) async {
    try {
      return await _remoteDataSource.createStore(request);
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }
}
