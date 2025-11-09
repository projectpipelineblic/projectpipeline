import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features_web/common/widgets/web_sidebar.dart';
import 'package:project_pipeline/features_web/home/pages/web_dashboard_page.dart';
import 'package:project_pipeline/features_web/projects/pages/web_projects_page.dart';
import 'package:project_pipeline/features_web/projects/pages/web_tasks_board_page.dart';
import 'package:project_pipeline/features_web/profile/pages/web_invites_page.dart';
import 'package:project_pipeline/features_web/profile/pages/web_profile_page.dart';
import 'package:sidebarx/sidebarx.dart';

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  
  // Create page instances without keys to prevent state caching
  final _dashboardPage = const WebDashboardPage();
  final _projectsPage = const WebProjectsPage();
  final _tasksBoardPage = const WebTasksBoardPage();
  final _invitesPage = const WebInvitesPage();
  final _profilePage = const WebProfilePage();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Redirect to login if user is not authenticated
        if (state is AuthUnauthenticated || state is AuthInitial) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/web-login',
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Show loading while checking auth
          if (state is AuthLoading) {
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Redirect to login if not authenticated
          if (state is AuthUnauthenticated || state is AuthInitial) {
            // Navigation will be handled by listener
            return const SizedBox.shrink();
          }
          
          // User is authenticated, show home page
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Hide sidebar on narrow screens (< 768px)
                final showSidebar = constraints.maxWidth >= 768;
                
                if (!showSidebar) {
                  // Mobile/tablet layout - sidebar hidden, use bottom nav or drawer
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return IndexedStack(
                        index: _controller.selectedIndex,
                        children: [
                          _dashboardPage,
                          _projectsPage,
                          _tasksBoardPage,
                          _invitesPage,
                          _profilePage,
                        ],
                      );
                    },
                  );
                }
                
                // Desktop layout - sidebar visible
                return Row(
        children: [
          // Sidebar Navigation (LEFT SIDE)
          WebSidebar(controller: _controller),
          
          // Main Content Area (RIGHT SIDE)
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Use IndexedStack to keep all pages alive and maintain their state
                return IndexedStack(
                  index: _controller.selectedIndex,
                  children: [
                    _dashboardPage,
                    _projectsPage,
                    _tasksBoardPage,
                    _invitesPage,
                    _profilePage,
                  ],
                );
              },
            ),
          ),
        ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

