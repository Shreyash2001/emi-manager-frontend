import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';
import 'package:mobile_emi_manager/core/widgets/app_error_view.dart';
import 'package:mobile_emi_manager/features/admin/presentation/bloc/admin_bloc.dart';

/// Admin page placeholder — SUPER_ADMIN only.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>()..add(const LoadStores()),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) return const AppLoader();
          if (state is AdminError) {
            return AppErrorView(
              message: state.failure.message,
              onRetry: () =>
                  context.read<AdminBloc>().add(const LoadStores()),
            );
          }
          if (state is StoresLoaded) {
            return const Center(child: Text('Admin Store Management — Architecture Ready'));
          }
          return const Center(child: Text('Admin Panel'));
        },
      ),
    );
  }
}
