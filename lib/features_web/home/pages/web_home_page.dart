import 'package:flutter/material.dart';
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
  
  // Create page instances with keys to maintain state
  final _dashboardPage = const WebDashboardPage(key: PageStorageKey('dashboard'));
  final _projectsPage = const WebProjectsPage(key: PageStorageKey('projects'));
  final _tasksBoardPage = const WebTasksBoardPage(key: PageStorageKey('tasks_board'));
  final _invitesPage = const WebInvitesPage(key: PageStorageKey('invites'));
  final _profilePage = const WebProfilePage(key: PageStorageKey('profile'));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      body: Row(
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
      ),
    );
  }
}

