import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';
import 'package:project_pipeline/features_web/projects/widgets/web_project_grid_card.dart';
import 'package:project_pipeline/features_web/projects/widgets/create_project_wizard.dart';

class WebProjectsPage extends StatefulWidget {
  const WebProjectsPage({super.key});

  @override
  State<WebProjectsPage> createState() => _WebProjectsPageState();
}

class _WebProjectsPageState extends State<WebProjectsPage> {
  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload projects when page is revisited
    _loadProjects();
  }

  void _loadProjects() {
    final authState = context.read<AuthBloc>().state;
    String? uid;
    
    if (authState is AuthSuccess) {
      uid = authState.user.uid;
    } else if (authState is AuthAuthenticated) {
      uid = authState.user.uid;
    } else if (authState is AuthOffline) {
      uid = authState.user.uid;
    }
    
      if (uid != null && uid.isNotEmpty) {
      print('🔄 [WebProjects] Loading projects for user: $uid');
        context.read<ProjectBloc>().add(
              GetProjectsRequested(userId: uid),
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        // Reload projects after create, update, or delete
        if (state is ProjectCreated || state is ProjectUpdated || state is ProjectDeleted) {
          print('🔄 [WebProjects] Project changed, reloading list...');
          _loadProjects();
        }
      },
      child: BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
          print('🎨 [WebProjects] Building UI with state: ${state.runtimeType}');
          if (state is ProjectLoaded) {
            print('🎨 [WebProjects] ProjectLoaded state has ${state.projects.length} projects');
          }
          
        return Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Projects',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'Manage and track all your projects',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CreateProjectWizard(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
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
                ],
              ),
              const Gap(32),

              // Loading State
              if (state is ProjectLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(64.0),
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              
              // Error State
              if (state is ProjectError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        const Gap(16),
                        Text(
                          'Error: ${state.message}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const Gap(16),
                        ElevatedButton(
                          onPressed: _loadProjects,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Projects Grid or Other States
              if (state is ProjectCreated || 
                  state is ProjectUpdated || 
                  state is ProjectDeleted) ...[
                // Reload projects after state changes
                Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _loadProjects();
                      }
                    });
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(64.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    );
                  },
                ),
              ] else if (state is ProjectLoaded) ...[
                if (state.projects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(64.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 80,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const Gap(16),
                          Text(
                            'No projects yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Create your first project to get started',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid columns
                      int crossAxisCount;
                      if (constraints.maxWidth > 1200) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 800) {
                        crossAxisCount = 2;
                      } else {
                        crossAxisCount = 1;
                      }

                      return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: state.projects.length,
                    itemBuilder: (context, index) {
                      return WebProjectGridCard(
                        project: state.projects[index],
                        isDark: isDark,
                      );
                    },
                      );
                    },
                ),
              ],
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}

