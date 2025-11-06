import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';
import 'package:project_pipeline/features_web/projects/widgets/web_project_grid_card.dart';
import 'package:project_pipeline/features_web/projects/widgets/create_project_dialog.dart';

class WebProjectsPage extends StatefulWidget {
  const WebProjectsPage({super.key});

  @override
  State<WebProjectsPage> createState() => _WebProjectsPageState();
}

class _WebProjectsPageState extends State<WebProjectsPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final uid = authState.user.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<ProjectBloc>().add(
              GetProjectsRequested(userId: uid),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
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
                        builder: (context) => const CreateProjectDialog(),
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

              // Projects Grid
              if (state is ProjectLoaded) ...[
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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
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
                  ),
                ] else if (state is ProjectLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (state is ProjectError) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Text(
                      state.message,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
              ],
            ),
          ),
        );
      },
    );
  }
}

