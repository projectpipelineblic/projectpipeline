import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart' as domain;
import 'package:project_pipeline/features/projects/presentation/pages/task_detail_page.dart';
import 'package:project_pipeline/features/projects/presentation/shared/task_types.dart';
import 'package:project_pipeline/features/projects/domain/usecases/stream_tasks_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/create_task_usecase.dart';
import 'package:project_pipeline/features/projects/presentation/widgets/create_task_sheet.dart';
import 'package:project_pipeline/core/di/service_locator.dart';

class WebTasksBoardPage extends StatefulWidget {
  const WebTasksBoardPage({super.key});

  @override
  State<WebTasksBoardPage> createState() => _WebTasksBoardPageState();
}

class _WebTasksBoardPageState extends State<WebTasksBoardPage> {
  ProjectEntity? _selectedProject;
  Stream<List<domain.TaskEntity>>? _tasksStream;
  String? _currentUserId;
  bool _isTimelineView = false; // Toggle between Task Board and Timeline view

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _currentUserId = authState.user.uid;
    } else if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.uid;
    } else if (authState is AuthOffline) {
      _currentUserId = authState.user.uid;
    }
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
      context.read<ProjectBloc>().add(GetProjectsRequested(userId: uid));
    }
  }

  void _selectProject(ProjectEntity project) {
    setState(() {
      _selectedProject = project;
      if (project.id != null) {
        final streamTasks = sl<StreamTasks>();
        _tasksStream = streamTasks(project.id!);
      }
    });
  }

  Future<void> _updateTaskStatus(
    domain.TaskEntity task,
    String statusName,
    domain.TaskStatus status,
  ) async {
    if (_selectedProject?.id == null || task.id.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(_selectedProject!.id)
          .collection('tasks')
          .doc(task.id)
          .update({
        'status': _statusToString(status),
        'statusName': statusName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  String _statusToString(domain.TaskStatus s) {
    switch (s) {
      case domain.TaskStatus.todo:
        return 'todo';
      case domain.TaskStatus.inProgress:
        return 'inProgress';
      case domain.TaskStatus.done:
        return 'done';
    }
  }

  List<domain.TaskEntity> _filterTasksByStatus(
    List<domain.TaskEntity> tasks,
    CustomStatus status,
    List<CustomStatus> allStatuses,
  ) {
    return tasks.where((task) {
      // If task has statusName, match by name (exact match)
      if (task.statusName != null && task.statusName!.isNotEmpty) {
        return task.statusName == status.name;
      }
      
      // Fallback: match by enum position
      // For default statuses (To Do, In Progress, Done), match by enum
      if (allStatuses.length == 3 && 
          allStatuses[0].name == 'To Do' && 
          allStatuses[1].name == 'In Progress' && 
          allStatuses[2].name == 'Done') {
        final statusIndex = allStatuses.indexOf(status);
        if (statusIndex == 0 && task.status == domain.TaskStatus.todo) {
          return true;
        } else if (statusIndex == 1 && task.status == domain.TaskStatus.inProgress) {
          return true;
        } else if (statusIndex == 2 && task.status == domain.TaskStatus.done) {
          return true;
        }
      }
      
      // For custom statuses, try to match by position
      final statusIndex = allStatuses.indexOf(status);
      final isFirst = statusIndex == 0;
      final isLast = statusIndex == allStatuses.length - 1;
      
      if (isFirst && task.status == domain.TaskStatus.todo) {
        return true;
      } else if (isLast && task.status == domain.TaskStatus.done) {
        return true;
      } else if (!isFirst && !isLast && task.status == domain.TaskStatus.inProgress) {
        return true;
      }
      
      return false;
    }).toList();
  }

  domain.TaskStatus _mapCustomStatusToEnum(String statusName, List<CustomStatus> customStatuses) {
    // Map custom status to enum based on position or name
    // First status = todo, middle = inProgress, last = done
    if (customStatuses.isEmpty) return domain.TaskStatus.todo;
    
    final index = customStatuses.indexWhere((s) => s.name == statusName);
    if (index == -1) return domain.TaskStatus.todo;
    
    if (index == 0) return domain.TaskStatus.todo;
    if (index == customStatuses.length - 1) return domain.TaskStatus.done;
    return domain.TaskStatus.inProgress;
  }

  void _onTaskTap(domain.TaskEntity task) async {
    if (_selectedProject == null) return;

    final taskItem = TaskItem(
      id: task.id,
      title: task.title,
      description: task.description,
      assigneeId: task.assigneeId,
      assigneeName: task.assigneeName,
      priority: task.priority == domain.TaskPriority.high
          ? TaskPriority.high
          : task.priority == domain.TaskPriority.medium
              ? TaskPriority.medium
              : TaskPriority.low,
      subTasks: task.subTasks,
      dueDate: task.dueDate,
      status: task.status == domain.TaskStatus.todo
          ? TaskStatus.todo
          : task.status == domain.TaskStatus.inProgress
              ? TaskStatus.inProgress
              : TaskStatus.done,
      statusName: task.statusName,
      timeSpentMinutes: task.timeSpentMinutes,
      startedAt: task.startedAt,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(
          task: taskItem,
          projectId: task.projectId,
          project: _selectedProject,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        // Reload projects after create, update, or delete
        if (state is ProjectCreated || state is ProjectUpdated || state is ProjectDeleted) {
          print('🔄 [TasksBoard] Project changed, reloading list...');
          _loadProjects();
        }
      },
      child: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, projectState) {
          print('🎨 [TasksBoard] Building UI with state: ${projectState.runtimeType}');
          if (projectState is ProjectLoaded) {
            print('🎨 [TasksBoard] ProjectLoaded with ${projectState.projects.length} projects');
          }
          
            return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
            body: _selectedProject == null
                ? _buildProjectSelectionView(projectState, isDark)
                : _isTimelineView
                    ? _buildTimelineView(isDark)
                    : _buildKanbanBoard(isDark),
          );
        },
      ),
    );
  }

  Widget _buildProjectSelectionView(ProjectState projectState, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        
        return Container(
          padding: EdgeInsets.all(isSmall ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks Board',
            style: GoogleFonts.poppins(
                  fontSize: isSmall ? 24 : 28,
              fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
              const Gap(8),
              Text(
                'Select a project to view and manage tasks',
                style: GoogleFonts.inter(
                  fontSize: isSmall ? 13 : 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Gap(isSmall ? 20 : 32),
              Expanded(
                child: _buildProjectsGrid(projectState, isDark, constraints.maxWidth),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectsGrid(ProjectState state, bool isDark, double availableWidth) {
    print('🎨 [TasksBoard] Building projects grid with state: ${state.runtimeType}');
    
    if (state is ProjectLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is ProjectError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const Gap(16),
          Text(
              state.message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
            const Gap(16),
            ElevatedButton(
              onPressed: _loadProjects,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is ProjectLoaded) {
      print('🎨 [TasksBoard] ProjectLoaded with ${state.projects.length} projects');
      
      if (state.projects.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),
        );
      }

      // Responsive grid
      int crossAxisCount;
      if (availableWidth < 600) {
        crossAxisCount = 1;  // Mobile: 1 column
      } else if (availableWidth < 900) {
        crossAxisCount = 2;  // Tablet: 2 columns
      } else if (availableWidth < 1200) {
        crossAxisCount = 3;  // Small desktop: 3 columns
      } else {
        crossAxisCount = 4;  // Large desktop: 4 columns
      }
      
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: availableWidth < 600 ? 12 : 20,
          mainAxisSpacing: availableWidth < 600 ? 12 : 20,
          childAspectRatio: availableWidth < 600 ? 1.5 : 1.2,
        ),
        itemCount: state.projects.length,
        itemBuilder: (context, index) {
          final project = state.projects[index];
          return InkWell(
            onTap: () => _selectProject(project),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(availableWidth < 600 ? 16 : 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(availableWidth < 600 ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: const Color(0xFF6366F1),
                      size: availableWidth < 600 ? 20 : 24,
                    ),
                  ),
                  Gap(availableWidth < 600 ? 12 : 16),
                  Text(
                    project.name,
                    style: GoogleFonts.inter(
                      fontSize: availableWidth < 600 ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (project.description.isNotEmpty && availableWidth >= 600) ...[
                    const Gap(8),
                    Text(
                      project.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    // For any other state (ProjectCreated, ProjectUpdated, etc.), reload projects
    print('⚠️ [TasksBoard] Unhandled state: ${state.runtimeType}, reloading projects...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProjects();
      }
    });
    
    return const Center(
      child: CircularProgressIndicator(),
    );
  }


  Widget _buildKanbanBoard(bool isDark) {
    if (_selectedProject == null || _tasksStream == null) {
      return Center(
            child: Text(
          'No project selected',
              style: GoogleFonts.inter(
                fontSize: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
        ),
      );
    }

    // Get custom statuses or use defaults
    final customStatuses = _selectedProject!.customStatuses;
    final statuses = customStatuses != null && customStatuses.isNotEmpty
        ? customStatuses
        : [
            const CustomStatus(name: 'To Do', colorHex: '#F59E0B'),
            const CustomStatus(name: 'In Progress', colorHex: '#8B5CF6'),
            const CustomStatus(name: 'Done', colorHex: '#10B981'),
          ];
    
    print('🔍 [TasksBoard] Project: ${_selectedProject!.name}');
    print('🔍 [TasksBoard] Custom statuses: ${statuses.length}');
    statuses.forEach((s) => print('  - ${s.name} (${s.colorHex})'));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedProject = null;
                        _tasksStream = null;
                      });
                    },
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProject!.name,
                          style: GoogleFonts.poppins(
                            fontSize: constraints.maxWidth < 600 ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (_selectedProject!.description.isNotEmpty && constraints.maxWidth >= 600) ...[
                          const Gap(4),
                          Text(
                            _selectedProject!.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Sprint Management Button
                  if (constraints.maxWidth >= 900) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showSprintManagementDialog(context, isDark),
                      icon: const Icon(Icons.rocket_launch, size: 18),
                      label: const Text('Manage Sprints'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Gap(12),
                  ],
                  // Toggle Switch between Task Board and Timeline
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewToggleButton(
                          context,
                          icon: Icons.view_column,
                          label: constraints.maxWidth >= 600 ? 'Board' : '',
                          isSelected: !_isTimelineView,
                          onTap: () => setState(() => _isTimelineView = false),
                          isDark: isDark,
                        ),
                        _buildViewToggleButton(
                          context,
                          icon: Icons.timeline,
                          label: constraints.maxWidth >= 600 ? 'Timeline' : '',
                          isSelected: _isTimelineView,
                          onTap: () => setState(() => _isTimelineView = true),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  if (constraints.maxWidth < 900) ...[
                    const Gap(8),
                    IconButton(
                      icon: const Icon(Icons.rocket_launch),
                      onPressed: () => _showSprintManagementDialog(context, isDark),
                      color: const Color(0xFF6366F1),
                      tooltip: 'Manage Sprints',
                    ),
                  ],
                ],
              ),
            ),
        // Kanban Columns
        Expanded(
          child: StreamBuilder<List<domain.TaskEntity>>(
            stream: _tasksStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                );
              }

              final allTasks = snapshot.data ?? [];
              
              print('🔍 [TasksBoard] Total tasks from stream: ${allTasks.length}');
              if (allTasks.isNotEmpty) {
                final sample = allTasks.first;
                print('🔍 [TasksBoard] Sample task: "${sample.title}", assigneeId: "${sample.assigneeId}", statusName: "${sample.statusName}", status: ${sample.status}');
              }
              print('🔍 [TasksBoard] Current user ID: $_currentUserId');
              
              // Filter tasks assigned to current user
              final userTasks = _currentUserId != null
                  ? allTasks.where((t) => t.assigneeId == _currentUserId).toList()
                  : <domain.TaskEntity>[];
              
              print('🔍 [TasksBoard] User tasks: ${userTasks.length}');
              
              // Show all tasks if user filtering returns empty (might be assigneeId mismatch)
              // This helps debug and ensures tasks are visible
              final tasksToShow = userTasks.isNotEmpty ? userTasks : allTasks;
              
              print('🔍 [TasksBoard] Tasks to show: ${tasksToShow.length}');
              
              // Debug: Show task distribution
              for (final status in statuses) {
                final filtered = _filterTasksByStatus(tasksToShow, status, statuses);
                print('📊 [TasksBoard] Status "${status.name}": ${filtered.length} tasks');
              }

              // Responsive column count
              final columnWidth = constraints.maxWidth < 600 
                  ? constraints.maxWidth - 32  // Small screen: full width
                  : constraints.maxWidth < 1200
                      ? 320.0  // Medium screen: fixed width with scroll
                      : null;  // Large screen: flexible width
              
              final shouldScroll = constraints.maxWidth < 1200 || statuses.length > 4;
              
              return Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: shouldScroll
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: statuses.map((status) {
                            return SizedBox(
                              width: columnWidth ?? 320,
                              child: _buildStatusColumn(
                                status,
                                _filterTasksByStatus(tasksToShow, status, statuses),
                                isDark,
                                constraints.maxWidth,
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: statuses.map((status) {
                            return Expanded(
                              child: _buildStatusColumn(
                                status,
                                _filterTasksByStatus(tasksToShow, status, statuses),
                                isDark,
                                constraints.maxWidth,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              );
            },
          ),
        ),
          ],
        );
      },
    );
  }

  Widget _buildStatusColumn(
    CustomStatus status,
    List<domain.TaskEntity> tasks,
    bool isDark,
    double availableWidth,
  ) {
    final hexColor = status.colorHex.replaceAll('#', '');
    final color = Color(int.parse('FF$hexColor', radix: 16));

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Responsive
          Container(
            padding: EdgeInsets.all(availableWidth < 600 ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: availableWidth < 600 ? 10 : 12,
                  height: availableWidth < 600 ? 10 : 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Gap(availableWidth < 600 ? 8 : 12),
                Expanded(
                  child: Text(
                    status.name,
                    style: GoogleFonts.inter(
                      fontSize: availableWidth < 600 ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: availableWidth < 600 ? 6 : 8,
                    vertical: availableWidth < 600 ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: GoogleFonts.inter(
                      fontSize: availableWidth < 600 ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tasks
          Expanded(
            child: DragTarget<domain.TaskEntity>(
              onAcceptWithDetails: (details) {
                final task = details.data;
                if (task.statusName != status.name) {
                  final newStatusEnum = _mapCustomStatusToEnum(status.name, _selectedProject!.customStatuses ?? []);
                  _updateTaskStatus(task, status.name, newStatusEnum);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isTargeted = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isTargeted ? color.withOpacity(0.05) : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tasks List
                      Expanded(
                        child: tasks.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 48,
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                      const Gap(8),
                                      Text(
                                        'No tasks',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return _buildTaskCard(task, color, isDark);
                                },
                              ),
                      ),
                      // Add Task Button - Responsive
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                          onTap: () => _showCreateTaskDialog(status),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: availableWidth < 600 ? 10 : 12,
                              horizontal: availableWidth < 600 ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: availableWidth < 600 ? 16 : 18,
                                  color: color,
                                ),
                                if (availableWidth >= 400) ...[
                                  const Gap(8),
                                  Flexible(
                                    child: Text(
                                      'Add Task',
                                      style: GoogleFonts.inter(
                                        fontSize: availableWidth < 600 ? 12 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(domain.TaskEntity task, Color statusColor, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 250 ? 250.0 : constraints.maxWidth - 24;
        
        return Draggable<domain.TaskEntity>(
          key: ValueKey(task.id),
          data: task,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Opacity(
              opacity: 0.9,
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: _buildTaskContent(task, isDark),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildTaskCardContent(task, statusColor, isDark),
          ),
          child: _buildTaskCardContent(task, statusColor, isDark),
        );
      },
    );
  }

  Widget _buildTaskCardContent(domain.TaskEntity task, Color statusColor, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 250;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: InkWell(
            onTap: () => _onTaskTap(task),
            child: _buildTaskContent(task, isDark),
          ),
        );
      },
    );
  }

  Widget _buildTaskContent(domain.TaskEntity task, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 250;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.title,
              style: GoogleFonts.inter(
                fontSize: isSmall ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                decoration: task.status == domain.TaskStatus.done ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description.isNotEmpty && !isSmall) ...[
              const Gap(4),
              Text(
                task.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Gap(8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 4 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPriorityText(task.priority),
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 9 : 10,
                      fontWeight: FontWeight.w500,
                      color: _getPriorityColor(task.priority),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _getPriorityText(domain.TaskPriority priority) {
    switch (priority) {
      case domain.TaskPriority.high:
        return 'High';
      case domain.TaskPriority.medium:
        return 'Medium';
      case domain.TaskPriority.low:
        return 'Low';
    }
  }

  Color _getPriorityColor(domain.TaskPriority priority) {
    switch (priority) {
      case domain.TaskPriority.high:
        return const Color(0xFFEF4444);
      case domain.TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case domain.TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  void _showCreateTaskDialog(CustomStatus status) {
    if (_selectedProject == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateTaskSheet(
                  project: _selectedProject!,
                  onSubmit: (taskEntity) async {
                    Navigator.of(sheetContext).pop();

                    // Map status to the correct enum and statusName
                    final statusEnum = _mapCustomStatusToEnum(status.name, _selectedProject!.customStatuses ?? []);

                    // Create task with the selected status
                    final taskWithStatus = domain.TaskEntity(
                      id: taskEntity.id,
                      projectId: taskEntity.projectId,
                      title: taskEntity.title,
                      description: taskEntity.description,
                      assigneeId: taskEntity.assigneeId,
                      assigneeName: taskEntity.assigneeName,
                      priority: taskEntity.priority,
                      subTasks: taskEntity.subTasks,
                      dueDate: taskEntity.dueDate,
                      status: statusEnum,
                      statusName: status.name, // Set to the column's status
                      createdAt: taskEntity.createdAt,
                      updatedAt: taskEntity.updatedAt,
                      timeSpentMinutes: 0,
                      startedAt: null,
                    );

                    final result = await sl<CreateTask>()(taskWithStatus);

                    result.fold(
                      (failure) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create task: ${failure.message}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Task created in "${status.name}"'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineView(bool isDark) {
    if (_selectedProject == null || _tasksStream == null) {
      return Center(
        child: Text(
          'No project selected',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (same as Kanban board)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedProject = null;
                        _tasksStream = null;
                      });
                    },
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProject!.name,
                          style: GoogleFonts.poppins(
                            fontSize: constraints.maxWidth < 600 ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (_selectedProject!.description.isNotEmpty && constraints.maxWidth >= 600) ...[
                          const Gap(4),
                          Text(
                            _selectedProject!.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Sprint Management Button
                  if (constraints.maxWidth >= 900) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showSprintManagementDialog(context, isDark),
                      icon: const Icon(Icons.rocket_launch, size: 18),
                      label: const Text('Manage Sprints'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Gap(12),
                  ],
                  // Toggle Switch
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewToggleButton(
                          context,
                          icon: Icons.view_column,
                          label: constraints.maxWidth >= 600 ? 'Board' : '',
                          isSelected: !_isTimelineView,
                          onTap: () => setState(() => _isTimelineView = false),
                          isDark: isDark,
                        ),
                        _buildViewToggleButton(
                          context,
                          icon: Icons.timeline,
                          label: constraints.maxWidth >= 600 ? 'Timeline' : '',
                          isSelected: _isTimelineView,
                          onTap: () => setState(() => _isTimelineView = true),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  if (constraints.maxWidth < 900) ...[
                    const Gap(8),
                    IconButton(
                      icon: const Icon(Icons.rocket_launch),
                      onPressed: () => _showSprintManagementDialog(context, isDark),
                      color: const Color(0xFF6366F1),
                      tooltip: 'Manage Sprints',
                    ),
                  ],
                ],
              ),
            ),
            // Timeline Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: constraints.maxWidth < 600 ? double.infinity : 250,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search timeline',
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Timeline Content
            Expanded(
              child: StreamBuilder<List<domain.TaskEntity>>(
                stream: _tasksStream,
                builder: (context, snapshot) {
                  // Show timeline immediately with available data
                  final allTasks = snapshot.data ?? [];
                  final userTasks = _currentUserId != null
                      ? allTasks.where((t) => t.assigneeId == _currentUserId).toList()
                      : allTasks;

                  // Show error if there's an error
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading tasks',
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.red.withOpacity(0.7)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Always show the timeline grid (even if loading or empty)
                  return _buildTimelineGrid(userTasks, isDark, constraints.maxWidth);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineGrid(List<domain.TaskEntity> tasks, bool isDark, double availableWidth) {
    // Get months starting from current month (always show 6 months)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final months = List.generate(6, (index) {
      final month = now.month + index;
      final year = now.year + (month - 1) ~/ 12;
      return DateTime(year, ((month - 1) % 12) + 1);
    });
    
    // Group tasks by sprint (for now, showing all in "Backlog")
    final sprintTasks = tasks.where((t) => t.storyPoints != null).toList();
    final backlogTasks = tasks.where((t) => t.storyPoints == null).toList();
    final allWorkItems = [...sprintTasks, ...backlogTasks];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel - Work Items
        Container(
          width: availableWidth < 900 ? 200 : 280,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              right: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Work" Header
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Text(
                  'Work',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              // Work Items List
              Expanded(
                child: allWorkItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No tasks yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const Gap(16),
                              ElevatedButton.icon(
                                onPressed: () => _showSprintManagementDialog(context, isDark),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Sprint'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: allWorkItems.length + 2, // +1 for header, +1 for Create Epic button
                        itemBuilder: (context, index) {
                          // Sprints header
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Sprints',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            );
                          }
                          
                          // Create Epic button
                          if (index == allWorkItems.length + 1) {
                            return Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Create Epic'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1),
                                  side: const BorderSide(color: Color(0xFF6366F1)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            );
                          }
                          
                          // Task row
                          final task = allWorkItems[index - 1];
                          return Container(
                            key: ValueKey(task.id),
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: false,
                                  onChanged: (val) {},
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  task.storyPoints != null ? Icons.bolt : Icons.circle_outlined,
                                  size: 16,
                                  color: task.storyPoints != null 
                                      ? const Color(0xFF8B5CF6) 
                                      : const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (task.storyPoints != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${task.storyPoints} SP',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Right Panel - Timeline Grid
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: months.length * 400.0,
                child: Column(
                  children: [
                    // Month Headers
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Row(
                        children: months.map((month) => _buildMonthHeader(month, isDark)).toList(),
                      ),
                    ),
                    // Timeline Grid with explicit height
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, gridConstraints) {
                          return Stack(
                            children: [
                              // Background grid
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: TimelineGridPainter(
                                    isDark: isDark,
                                    monthCount: months.length,
                                    rowCount: allWorkItems.length + 1,
                                    today: today,
                                    months: months,
                                  ),
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                              // Task bars
                              if (allWorkItems.isNotEmpty)
                                ...allWorkItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final task = entry.value;
                                  
                                  if (task.dueDate == null) return const SizedBox.shrink();
                                  
                                  return Positioned(
                                    top: 60.0 * (index + 1) + 14,
                                    left: _calculateTaskPosition(task, months),
                                    child: _buildTaskBarWidget(task, isDark),
                                  );
                                }),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateTaskPosition(domain.TaskEntity task, List<DateTime> months) {
    if (task.dueDate == null) return -1000; // Off-screen
    
    final dueDate = task.dueDate!;
    
    // Find which month the task belongs to
    int monthIndex = -1;
    for (int i = 0; i < months.length; i++) {
      if (dueDate.year == months[i].year && dueDate.month == months[i].month) {
        monthIndex = i;
        break;
      }
    }
    
    if (monthIndex == -1) return -1000; // Off-screen if not in visible months
    
    // Calculate position within the month
    final monthStart = months[monthIndex];
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final dayOfMonth = dueDate.day;
    final positionInMonth = (dayOfMonth / daysInMonth);
    
    return (monthIndex * 400.0) + (positionInMonth * 400.0) - 50;
  }

  Widget _buildTaskBarWidget(domain.TaskEntity task, bool isDark) {
    return Container(
      width: 100,
      height: 32,
      decoration: BoxDecoration(
        color: _getTaskColor(task),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        task.title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getTaskColor(domain.TaskEntity task) {
    switch (task.priority) {
      case domain.TaskPriority.high:
        return const Color(0xFFEF4444);
      case domain.TaskPriority.medium:
        return const Color(0xFF8B5CF6);
      case domain.TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  Widget _buildMonthHeader(DateTime month, bool isDark) {
    final monthName = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month.month - 1];

    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        monthName,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 10 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
            ),
            if (label.isNotEmpty) ...[
              const Gap(6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSprintManagementDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Sprint Management',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ],
              ),
              const Gap(24),
              // Coming soon message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 Sprint Management Coming Soon!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Create and manage sprints, track velocity, and analyze your team\'s performance with powerful scrum tools.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const Gap(16),
                    Text(
                      'Features:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const Gap(8),
                    ...[
                      '• Create and start sprints',
                      '• Assign tasks with story points',
                      '• Track sprint progress and velocity',
                      '• View burndown charts',
                      '• Complete and archive sprints',
                    ].map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          feature,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Text(
                'For now, you can assign tasks to sprints when creating them.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Timeline Grid
class TimelineGridPainter extends CustomPainter {
  final bool isDark;
  final int monthCount;
  final int rowCount;
  final DateTime today;
  final List<DateTime> months;

  TimelineGridPainter({
    required this.isDark,
    required this.monthCount,
    required this.rowCount,
    required this.today,
    required this.months,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical lines (month separators)
    final monthWidth = size.width / monthCount;
    for (int i = 0; i <= monthCount; i++) {
      final x = i * monthWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }

    // Draw horizontal lines (row separators)
    final rowHeight = 60.0;
    int rowsToDraw = (size.height / rowHeight).ceil();
    if (rowCount > 0 && rowsToDraw > rowCount) {
      rowsToDraw = rowCount;
    }
    
    for (int i = 0; i <= rowsToDraw; i++) {
      final y = i * rowHeight;
      if (y <= size.height) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          linePaint,
        );
      }
    }

    // Draw TODAY indicator line (vertical "candle")
    final todayPosition = _calculateTodayPosition();
    if (todayPosition >= 0 && todayPosition <= size.width) {
      final todayPaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Draw vertical line
      canvas.drawLine(
        Offset(todayPosition, 0),
        Offset(todayPosition, size.height),
        todayPaint,
      );

      // Draw circle at top (candle flame)
      final circlePaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(todayPosition, 8),
        6,
        circlePaint,
      );

      // Draw label background
      final labelPaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(todayPosition - 25, 18, 50, 20),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, labelPaint);

      // Draw "Today" text
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Today',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(todayPosition - 18, 22));
    }
  }

  double _calculateTodayPosition() {
    // Find which month today falls in
    for (int i = 0; i < months.length; i++) {
      if (today.year == months[i].year && today.month == months[i].month) {
        final monthWidth = 400.0; // Fixed width per month
        final daysInMonth = DateTime(months[i].year, months[i].month + 1, 0).day;
        final dayOfMonth = today.day;
        final positionInMonth = (dayOfMonth / daysInMonth);
        
        return (i * monthWidth) + (positionInMonth * monthWidth);
      }
    }
    return -1; // Today not in visible range
  }

  @override
  bool shouldRepaint(covariant TimelineGridPainter oldDelegate) {
    return oldDelegate.today != today || 
           oldDelegate.monthCount != monthCount || 
           oldDelegate.rowCount != rowCount;
  }
}
