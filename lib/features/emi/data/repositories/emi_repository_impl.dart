import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/emi/data/datasources/emi_remote_datasource.dart';
import 'package:mobile_emi_manager/features/emi/data/models/emi_plan_model.dart';
import 'package:mobile_emi_manager/features/emi/domain/repositories/emi_repository.dart';

class EmiRepositoryImpl implements EmiRepository {
  final EmiRemoteDataSource _remoteDataSource;

  EmiRepositoryImpl({required EmiRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<EmiPlanModel> getEmiPlan(String id) async {
    try {
      return await _remoteDataSource.getEmiPlan(id);
    } catch (e) {
      throw ErrorMapper.toFailure(e);
    }
  }
}
