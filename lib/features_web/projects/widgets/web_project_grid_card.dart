import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/presentation/pages/project_detail_page.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';
import 'package:project_pipeline/features_web/projects/widgets/edit_project_dialog.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';

class WebProjectGridCard extends StatefulWidget {
  final ProjectEntity project;
  final bool isDark;

  const WebProjectGridCard({
    super.key,
    required this.project,
    this.isDark = false,
  });

  @override
  State<WebProjectGridCard> createState() => _WebProjectGridCardState();
}

class _WebProjectGridCardState extends State<WebProjectGridCard> {
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _memberCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (widget.project.id == null) return;

    try {
      // Fetch tasks
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('tasks')
          .get();

      final completed = tasksSnapshot.docs
          .where((doc) => doc.data()['status'] == 'done')
          .length;

      if (mounted) {
        setState(() {
          _totalTasks = tasksSnapshot.docs.length;
          _completedTasks = completed;
          _memberCount = widget.project.members.length;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  ProjectEntity get project => widget.project;
  bool get isDark => widget.isDark;

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<ProjectBloc>(context),
        child: EditProjectDialog(project: project),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const Gap(12),
            Text(
              'Delete Project?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${project.name}"?',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
              ),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'This will permanently delete the project and all its tasks.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              _deleteProject(context);
            },
            icon: const Icon(Icons.delete_forever, size: 20),
            label: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteProject(BuildContext context) {
    if (project.id == null) return;

    final projectBloc = context.read<ProjectBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final authState = context.read<AuthBloc>().state;
    
    String? userId;
    if (authState is AuthSuccess) {
      userId = authState.user.uid;
    } else if (authState is AuthAuthenticated) {
      userId = authState.user.uid;
    }

    projectBloc.add(DeleteProjectRequested(projectId: project.id!));

    // Listen for result
    final subscription = projectBloc.stream.listen((state) {
      if (state is ProjectDeleted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Project "${project.name}" deleted successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Refresh the projects list
        if (userId != null) {
          projectBloc.add(GetProjectsRequested(userId: userId));
        }
      } else if (state is ProjectError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      subscription.cancel();
    });
  }

  String _getProjectKey() {
    // Generate project key from name (first 2-4 letters, uppercase)
    final words = project.name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (project.name.length >= 3) {
      return project.name.substring(0, 3).toUpperCase();
    }
    return project.name.substring(0, 1).toUpperCase();
  }

  Color _getProjectColor() {
    // Generate consistent color based on project name
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
    ];
    final index = project.name.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final projectColor = _getProjectColor();
    final projectKey = _getProjectKey();
    final progress = _totalTasks > 0 ? (_completedTasks / _totalTasks) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailPage(project: project),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Project Key + Name + Actions (Jira Style)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Avatar (Jira Style)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: projectColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          projectKey,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Star/Favorite Icon
                              IconButton(
                                icon: Icon(
                                  Icons.star_border,
                                  size: 18,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  // TODO: Implement favorite functionality
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const Gap(4),
                              // More options
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_horiz,
                                  size: 18,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditDialog(context);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(context);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 16),
                                        Gap(8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        Gap(8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '${project.projectType ?? 'Project'} • $projectKey',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Gap(12),
                
                // Description
                Text(
                  project.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                // Progress Bar (Jira Style)
                if (!_loading && _totalTasks > 0) ...[
                  const Gap(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '$_completedTasks of $_totalTasks completed',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark 
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 
                              ? const Color(0xFF10B981) 
                              : const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const Gap(12),
                const Divider(height: 1),
                const Gap(12),
                
                // Footer - Stats (Jira Style)
                Row(
                  children: [
                    // Team Members
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const Gap(4),
                        Text(
                          '$_memberCount',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    // Tasks
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const Gap(4),
                        Text(
                          '$_completedTasks/$_totalTasks',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Last Updated
                    Text(
                      DateFormat('MMM d').format(project.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

