import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/core/services/local_storage_service.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/home/presentation/bloc/dashboard_bloc.dart';
import 'package:project_pipeline/features/home/presentation/widgets/dashboard_header_widget.dart';
import 'package:project_pipeline/features/home/presentation/widgets/todays_tasks_section_widget.dart';
import 'package:project_pipeline/features/home/presentation/widgets/open_projects_section_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = sl<DashboardBloc>();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final user = await sl<LocalStorageService>().getCachedUser();
    if (user != null && user.uid != null) {
      _dashboardBloc.add(DashboardLoadRequested(user.uid!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dashboardBloc,
      child: Scaffold(
        body: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              // Reload dashboard when username is updated
              if (authState is UsernameUpdated || authState is AuthAuthenticated) {
                _loadDashboardData();
              }
            },
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is DashboardFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.error),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is DashboardSuccess) {
                return RefreshIndicator(
                  onRefresh: () async => _loadDashboardData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DashboardHeaderWidget(),
                        TodaysTasksSectionWidget(tasks: state.tasks),
                        const SizedBox(height: 32),
                        OpenProjectsSectionWidget(projects: state.projects),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}


