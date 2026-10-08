import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/extensions/context_extensions.dart';
import 'package:mobile_emi_manager/core/widgets/app_empty_view.dart';
import 'package:mobile_emi_manager/core/widgets/app_error_view.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';
import 'package:mobile_emi_manager/features/payments/presentation/bloc/payment_bloc.dart';

/// Payments list page placeholder.
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentBloc>()..add(const LoadPaymentHistory()),
      child: const _PaymentsView(),
    );
  }
}

class _PaymentsView extends StatelessWidget {
  const _PaymentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.payments)),
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentLoading) return const AppLoader();
          if (state is PaymentError) {
            return AppErrorView(
              message: state.failure.message,
              onRetry: () =>
                  context.read<PaymentBloc>().add(const LoadPaymentHistory()),
            );
          }
          if (state is PaymentsLoaded && state.payments.isEmpty) {
            return AppEmptyView(
              message: context.l10n.noPayments,
              icon: Icons.payment_outlined,
            );
          }
          return const AppLoader();
        },
      ),
    );
  }
}
