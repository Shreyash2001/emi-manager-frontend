import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';
import 'package:mobile_emi_manager/core/widgets/app_error_view.dart';
import 'package:mobile_emi_manager/features/emi/presentation/bloc/emi_bloc.dart';

/// EMI Details page — receives emiPlanId as a route parameter.
class EmiDetailsPage extends StatelessWidget {
  final String emiPlanId;

  const EmiDetailsPage({super.key, required this.emiPlanId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EMIBloc>()..add(LoadEMIPlan(emiPlanId: emiPlanId)),
      child: _EmiDetailsView(emiPlanId: emiPlanId),
    );
  }
}

class _EmiDetailsView extends StatelessWidget {
  final String emiPlanId;

  const _EmiDetailsView({required this.emiPlanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EMI Details')),
      body: BlocBuilder<EMIBloc, EMIState>(
        builder: (context, state) {
          if (state is EMILoading) return const AppLoader();
          if (state is EMIError) {
            return AppErrorView(
              message: state.failure.message,
              onRetry: () => context.read<EMIBloc>().add(
                    LoadEMIPlan(emiPlanId: emiPlanId),
                  ),
            );
          }
          if (state is EMILoaded) {
            return Center(child: Text('EMI Plan: ${state.emiPlan.id}'));
          }
          return Center(child: Text('EMI Plan ID: $emiPlanId'));
        },
      ),
    );
  }
}
