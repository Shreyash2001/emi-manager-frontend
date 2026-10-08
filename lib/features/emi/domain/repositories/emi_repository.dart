import 'package:mobile_emi_manager/features/emi/data/models/emi_plan_model.dart';

abstract class EmiRepository {
  Future<EmiPlanModel> getEmiPlan(String id);
}
