import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/home/presentation/bloc/dashboard_bloc.dart';
import 'package:project_pipeline/features_web/home/widgets/web_stat_card.dart';
import 'package:project_pipeline/features_web/home/widgets/web_project_card.dart';
import 'package:project_pipeline/features_web/home/widgets/web_task_card.dart';
import 'package:project_pipeline/features_web/projects/widgets/create_project_dialog.dart';

class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({super.key});

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Use post frame callback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload dashboard when dependencies change (e.g., after auth state update)
    _loadDashboard();
  }

  void _loadDashboard() {
    if (!mounted) return;
    
    final authState = context.read<AuthBloc>().state;
    final dashboardState = context.read<DashboardBloc>().state;
    String? userId;
    
    if (authState is AuthSuccess) {
      userId = authState.user.uid;
    } else if (authState is AuthAuthenticated) {
      userId = authState.user.uid;
    }
    
    // Only load if we have a userId and dashboard is not already loaded/loading
    if (userId != null && userId.isNotEmpty) {
      // Always reload on first render or if in initial state
      if (dashboardState is DashboardInitial) {
        context.read<DashboardBloc>().add(DashboardLoadRequested(userId));
      }
    }
  }

  void _refreshDashboard() {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    
    if (authState is AuthSuccess) {
      userId = authState.user.uid;
    } else if (authState is AuthAuthenticated) {
      userId = authState.user.uid;
    }
    
    if (userId != null && userId.isNotEmpty) {
      context.read<DashboardBloc>().add(DashboardRefreshRequested(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          // Reload dashboard when auth state changes to authenticated
          if (authState is AuthSuccess || authState is AuthAuthenticated) {
            final userId = authState is AuthSuccess 
              ? authState.user.uid 
              : (authState as AuthAuthenticated).user.uid;
            
            if (userId != null && userId.isNotEmpty) {
              // Force reload
              context.read<DashboardBloc>().add(DashboardLoadRequested(userId));
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with username
              _buildHeader(isDark),
              const Gap(32),

              // Dashboard Content
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                          ),
                          Gap(16),
                          Text('Loading dashboard...'),
                        ],
                      ),
                    ),
                  );
                }

                if (state is DashboardFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(64.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const Gap(16),
                          Text(
                            'Error: ${state.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const Gap(16),
                          ElevatedButton(
                            onPressed: _loadDashboard,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is DashboardSuccess) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards
                      _buildStatsRow(state, isDark),
                      const Gap(32),

                      // Projects and Tasks
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Open Projects
                          Expanded(
                            child: _buildProjectsSection(state, isDark),
                          ),
                          const Gap(24),
                          // My Tasks
                          Expanded(
                            child: _buildTasksSection(state, isDark),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                // Initial state
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Get username from auth state
        String userName = 'User';
        if (state is AuthSuccess) {
          userName = state.user.userName;
        } else if (state is AuthAuthenticated) {
          userName = state.user.userName;
        }
        
        final greeting = _getGreeting();

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $userName!',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Refresh button
            IconButton(
              onPressed: _refreshDashboard,
              icon: Icon(
                Icons.refresh,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              tooltip: 'Refresh Dashboard',
            ),
            const Gap(8),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreateProjectDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'New Project',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Gap(12),
            // Logout button
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(SignOutRequested());
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(
                Icons.logout,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              tooltip: 'Logout',
            ),
          ],
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildStatsRow(DashboardSuccess state, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: WebStatCard(
            title: 'Total Projects',
            value: state.totalProjects.toString(),
            icon: Icons.folder_outlined,
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),
        ),
        const Gap(16),
        Expanded(
          child: WebStatCard(
            title: 'Total Tasks',
            value: state.totalTasks.toString(),
            icon: Icons.task_alt_outlined,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
        const Gap(16),
        Expanded(
          child: WebStatCard(
            title: 'Completed',
            value: state.completedTasks.toString(),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const Gap(16),
        Expanded(
          child: WebStatCard(
            title: 'Pending',
            value: state.pendingTasks.toString(),
            icon: Icons.pending_outlined,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsSection(DashboardSuccess state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Open Projects',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CreateProjectDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all projects
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(16),
          if (state.projects.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No projects yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...state.projects.take(5).map((project) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WebProjectCard(
                    project: project,
                    isDark: isDark,
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildTasksSection(DashboardSuccess state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Tasks',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all tasks
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          if (state.tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No tasks yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...state.tasks.take(5).map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WebTaskCard(
                    task: task,
                    isDark: isDark,
                  ),
                )),
        ],
      ),
    );
  }
}
