import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/core/services/local_storage_service.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/usecases/stream_tasks_usecase.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';
import 'package:project_pipeline/features/projects/presentation/pages/task_detail_page.dart';
import 'package:project_pipeline/features/projects/presentation/shared/task_types.dart' as task_types;
import 'package:project_pipeline/features/tasks_board/presentation/bloc/tasks_board_bloc.dart';
import 'package:project_pipeline/features/tasks_board/presentation/widgets/vertical_task_section_widget.dart';
import 'package:project_pipeline/features/tasks_board/presentation/widgets/mobile_sprint_gantt_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TasksBoardPage extends StatefulWidget {
  const TasksBoardPage({super.key});

  @override
  State<TasksBoardPage> createState() => _TasksBoardPageState();
}

class _TasksBoardPageState extends State<TasksBoardPage> {
  late final TasksBoardBloc _tasksBoardBloc;
  late final ProjectBloc _projectBloc;
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  double _dragPosition = 0;
  
  // Project selection state
  ProjectEntity? _selectedProject;
  Stream<List<TaskEntity>>? _tasksStream;
  String? _currentUserId;
  
  // View toggle state - Board vs Timeline
  bool _isMobileTimelineView = false;

  @override
  void initState() {
    super.initState();
    _tasksBoardBloc = sl<TasksBoardBloc>();
    _projectBloc = sl<ProjectBloc>();
    _getCurrentUser();
    _loadProjects();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tasksBoardBloc.close();
    super.dispose();
  }
  
  void _getCurrentUser() async {
    final user = await sl<LocalStorageService>().getCachedUser();
    if (user != null && user.uid != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }
  
  void _loadProjects() async {
    final user = await sl<LocalStorageService>().getCachedUser();
    if (user != null && user.uid != null) {
      _projectBloc.add(GetProjectsRequested(userId: user.uid!));
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

  void _startAutoScroll() {
    // Check for auto-scroll every 16ms (60fps)
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return false;
      
      if (_isDragging && _scrollController.hasClients) {
        final screenHeight = MediaQuery.of(context).size.height;
        final scrollTriggerZone = 100.0; // pixels from edge to trigger scroll
        final scrollSpeed = 5.0; // pixels per frame
        
        // Auto-scroll down when dragging near bottom
        if (_dragPosition > screenHeight - scrollTriggerZone) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.offset;
          if (currentScroll < maxScroll) {
            _scrollController.jumpTo(
              (currentScroll + scrollSpeed).clamp(0.0, maxScroll),
            );
          }
        }
        // Auto-scroll up when dragging near top
        else if (_dragPosition < scrollTriggerZone + 100) {
          final currentScroll = _scrollController.offset;
          if (currentScroll > 0) {
            _scrollController.jumpTo(
              (currentScroll - scrollSpeed).clamp(0.0, _scrollController.position.maxScrollExtent),
            );
          }
        }
      }
      
      return true;
    });
  }

  void _onDragStart() {
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragEnd() {
    setState(() {
      _isDragging = false;
    });
  }

  void _updateDragPosition(double position) {
    setState(() {
      _dragPosition = position;
    });
  }

  Future<void> _updateTaskStatus(
    TaskEntity task,
    String statusName,
    TaskStatus status,
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

  String _statusToString(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'inProgress';
      case TaskStatus.done:
        return 'done';
    }
  }
  
  List<TaskEntity> _filterTasksByStatus(
    List<TaskEntity> tasks,
    CustomStatus status,
    List<CustomStatus> allStatuses,
  ) {
    return tasks.where((task) {
      // If task has statusName, match by name (exact match)
      if (task.statusName != null && task.statusName!.isNotEmpty) {
        return task.statusName == status.name;
      }
      
      // Fallback: match by enum position
      final statusIndex = allStatuses.indexOf(status);
      final isFirst = statusIndex == 0;
      final isLast = statusIndex == allStatuses.length - 1;
      
      if (isFirst && task.status == TaskStatus.todo) {
        return true;
      } else if (isLast && task.status == TaskStatus.done) {
        return true;
      } else if (!isFirst && !isLast && task.status == TaskStatus.inProgress) {
        return true;
      }
      
      return false;
    }).toList();
  }

  TaskStatus _mapCustomStatusToEnum(String statusName, List<CustomStatus> customStatuses) {
    if (customStatuses.isEmpty) return TaskStatus.todo;
    
    final index = customStatuses.indexWhere((s) => s.name == statusName);
    if (index == -1) return TaskStatus.todo;
    
    if (index == 0) return TaskStatus.todo;
    if (index == customStatuses.length - 1) return TaskStatus.done;
    return TaskStatus.inProgress;
  }

  void _onTaskTap(TaskEntity task) async {
    if (_selectedProject == null) return;

    // Convert TaskEntity to TaskItem for navigation
    final taskItem = task_types.TaskItem(
      id: task.id,
      title: task.title,
      description: task.description,
      assigneeId: task.assigneeId,
      assigneeName: task.assigneeName,
      priority: task.priority == TaskPriority.high
          ? task_types.TaskPriority.high
          : task.priority == TaskPriority.medium
              ? task_types.TaskPriority.medium
              : task_types.TaskPriority.low,
      subTasks: task.subTasks,
      dueDate: task.dueDate,
      status: task.status == TaskStatus.todo
          ? task_types.TaskStatus.todo
          : task.status == TaskStatus.inProgress
              ? task_types.TaskStatus.inProgress
              : task_types.TaskStatus.done,
      statusName: task.statusName,
    );

    // Navigate to detail page and wait for return
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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _tasksBoardBloc),
        BlocProvider.value(value: _projectBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _selectedProject != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedProject = null;
                      _tasksStream = null;
                      _isMobileTimelineView = false;
                    });
                  },
                )
              : null,
          title: PrimaryText(
            text: _selectedProject != null ? _selectedProject!.name : 'Tasks Board',
            size: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFE5E7EB)
                : AppPallete.secondary,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: _selectedProject != null
              ? [
                  _buildMobileViewToggle(),
                  const SizedBox(width: 8),
                ]
              : null,
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            // Reload projects when username is updated
            if (authState is UsernameUpdated || authState is AuthAuthenticated) {
              _loadProjects();
            }
          },
          child: _selectedProject == null
              ? _buildProjectSelectionView()
              : _isMobileTimelineView
                  ? _buildMobileTimelineView()
                  : _buildTaskBoard(),
        ),
      ),
    );
  }
  
  Widget _buildMobileViewToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMobileToggleButton(
            icon: Icons.view_column,
            isSelected: !_isMobileTimelineView,
            onTap: () => setState(() => _isMobileTimelineView = false),
            isDark: isDark,
          ),
          _buildMobileToggleButton(
            icon: Icons.timeline,
            isSelected: _isMobileTimelineView,
            onTap: () => setState(() => _isMobileTimelineView = true),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppPallete.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? AppPallete.white
              : isDark
                  ? const Color(0xFF9CA3AF)
                  : AppPallete.textGray,
        ),
      ),
    );
  }

  Widget _buildProjectSelectionView() {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (state is ProjectLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProjectError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                PrimaryText(
                  text: state.message,
                  size: 16,
                  color: AppPallete.textGray,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProjects,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.primary,
                    foregroundColor: AppPallete.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ProjectLoaded) {
          if (state.projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 80,
                    color: AppPallete.textGray.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  PrimaryText(
                    text: 'No projects yet',
                    size: 18,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.textGray,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: state.projects.length,
            itemBuilder: (context, index) {
              final project = state.projects[index];
              return _buildProjectCard(project);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProjectCard(ProjectEntity project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => _selectProject(project),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppPallete.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPallete.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: AppPallete.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              project.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                project.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppPallete.textGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBoard() {
    if (_selectedProject == null || _tasksStream == null) {
      return const Center(child: Text('No project selected'));
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

    return StreamBuilder<List<TaskEntity>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allTasks = snapshot.data ?? [];
        
        // Filter tasks assigned to current user
        final userTasks = _currentUserId != null
            ? allTasks.where((t) => t.assigneeId == _currentUserId).toList()
            : allTasks;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              if (_selectedProject?.id != null) {
                final streamTasks = sl<StreamTasks>();
                _tasksStream = streamTasks(_selectedProject!.id!);
              }
            });
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                ...statuses.map((status) {
                  final filteredTasks = _filterTasksByStatus(userTasks, status, statuses);
                  final hexColor = status.colorHex.replaceAll('#', '');
                  final color = Color(int.parse('FF$hexColor', radix: 16));
                  
                  return VerticalTaskSectionWidget(
                    title: status.name,
                    tasks: filteredTasks,
                    columnStatus: _mapCustomStatusToEnum(status.name, statuses),
                    headerColor: color,
                    onTaskTap: _onTaskTap,
                    onTaskDrop: (task) {
                      final newStatusEnum = _mapCustomStatusToEnum(status.name, statuses);
                      _updateTaskStatus(task, status.name, newStatusEnum);
                    },
                    onDragStart: _onDragStart,
                    onDragEnd: _onDragEnd,
                    onDragUpdate: _updateDragPosition,
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMobileTimelineView() {
    if (_selectedProject == null) {
      return const Center(child: Text('No project selected'));
    }

    return MobileSprintGanttTimeline(
      project: _selectedProject!,
      onSprintTap: (sprint) => _showMobileSprintDetails(sprint),
    );
  }
  
  void _showMobileSprintDetails(SprintEntity sprint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MobileSprintDetailsSheet(
        project: _selectedProject!,
        sprint: sprint,
      ),
    );
  }



}

/// Mobile Sprint Details Bottom Sheet with Tasks
class _MobileSprintDetailsSheet extends StatefulWidget {
  const _MobileSprintDetailsSheet({
    required this.project,
    required this.sprint,
  });

  final ProjectEntity project;
  final SprintEntity sprint;

  @override
  State<_MobileSprintDetailsSheet> createState() => _MobileSprintDetailsSheetState();
}

class _MobileSprintDetailsSheetState extends State<_MobileSprintDetailsSheet> {
  List<TaskEntity> _sprintTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSprintTasks();
  }

  Future<void> _loadSprintTasks() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('tasks')
          .where('sprintId', isEqualTo: widget.sprint.id)
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskEntity(
                id: doc.id,
                projectId: widget.project.id ?? '',
                title: doc.data()['title'] ?? '',
                description: doc.data()['description'] ?? '',
                assigneeId: doc.data()['assigneeId'] ?? '',
                assigneeName: doc.data()['assigneeName'] ?? '',
                priority: _parsePriority(doc.data()['priority']),
                subTasks: List<String>.from(doc.data()['subTasks'] ?? []),
                dueDate: doc.data()['dueDate'] != null
                    ? (doc.data()['dueDate'] as Timestamp).toDate()
                    : null,
                status: _parseStatus(doc.data()['status']),
                statusName: doc.data()['statusName'],
                createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                sprintId: doc.data()['sprintId'],
                storyPoints: doc.data()['storyPoints'],
                estimatedHours: doc.data()['estimatedHours']?.toDouble(),
                sprintStatus: doc.data()['sprintStatus'] ?? 'backlog',
              ))
          .toList();

      if (mounted) {
        setState(() {
          _sprintTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  TaskPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  TaskStatus _parseStatus(String? status) {
    switch (status) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  void _onTaskTap(TaskEntity task) async {
    // Convert TaskEntity to TaskItem for navigation
    final taskItem = task_types.TaskItem(
      id: task.id,
      title: task.title,
      description: task.description,
      assigneeId: task.assigneeId,
      assigneeName: task.assigneeName,
      priority: task.priority == TaskPriority.high
          ? task_types.TaskPriority.high
          : task.priority == TaskPriority.medium
              ? task_types.TaskPriority.medium
              : task_types.TaskPriority.low,
      subTasks: task.subTasks,
      dueDate: task.dueDate,
      status: task.status == TaskStatus.todo
          ? task_types.TaskStatus.todo
          : task.status == TaskStatus.inProgress
              ? task_types.TaskStatus.inProgress
              : task_types.TaskStatus.done,
      statusName: task.statusName,
      timeSpentMinutes: 0,
      startedAt: null,
      sprintId: task.sprintId,
    );

    // Navigate to detail page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(
          task: taskItem,
          projectId: task.projectId,
          project: widget.project,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getSprintColorForStatus(widget.sprint.status);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppPallete.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4B5563) : AppPallete.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with sprint info
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.sprint.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getSprintStatusText(widget.sprint.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.sprint.startDate.day}/${widget.sprint.startDate.month} - ${widget.sprint.endDate.day}/${widget.sprint.endDate.month}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.sprint.totalStoryPoints > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppPallete.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.assessment,
                                size: 12,
                                color: AppPallete.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.sprint.completedStoryPoints}/${widget.sprint.totalStoryPoints} SP',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppPallete.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (widget.sprint.goal != null && widget.sprint.goal!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.sprint.goal!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Divider
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
            ),
            // Tasks section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sprintTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: isDark ? const Color(0xFF4B5563) : AppPallete.textGray.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks in this sprint',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Assign tasks to this sprint to see them here',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF6B7280) : AppPallete.textGray.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task count header
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                '${_sprintTasks.length} Task${_sprintTasks.length == 1 ? '' : 's'} in Sprint',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                                ),
                              ),
                            ),
                            // Tasks list
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemCount: _sprintTasks.length,
                                itemBuilder: (context, index) {
                                  final task = _sprintTasks[index];
                                  return _buildMobileTaskItem(task, isDark);
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTaskItem(TaskEntity task, bool isDark) {
    final statusColor = _getTaskStatusColor(task.status);
    final priorityColor = _getTaskPriorityColor(task.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onTaskTap(task),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F0F) : AppPallete.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                        decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDark ? const Color(0xFF6B7280) : AppPallete.textGray.withOpacity(0.5),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Tags row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      task.statusName ?? _getTaskStatusName(task.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  // Priority
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _getTaskPriorityName(task.priority),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  // Story points
                  if (task.storyPoints != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppPallete.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.assessment,
                            size: 10,
                            color: AppPallete.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.storyPoints} SP',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppPallete.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Assignee
                  if (task.assigneeName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 10,
                            color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.assigneeName,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Due date
                  if (task.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isOverdue(task.dueDate!)
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : (isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: _isOverdue(task.dueDate!)
                                ? const Color(0xFFEF4444)
                                : (isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.dueDate!.day}/${task.dueDate!.month}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: _isOverdue(task.dueDate!) ? FontWeight.w600 : FontWeight.normal,
                              color: _isOverdue(task.dueDate!)
                                  ? const Color(0xFFEF4444)
                                  : (isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now()) && dueDate.day != DateTime.now().day;
  }

  Color _getSprintColorForStatus(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return const Color(0xFF3B82F6);
      case SprintStatus.active:
        return const Color(0xFFEC4899);
      case SprintStatus.completed:
        return const Color(0xFF10B981);
      case SprintStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  String _getSprintStatusText(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return 'PLANNING';
      case SprintStatus.active:
        return 'ACTIVE';
      case SprintStatus.completed:
        return 'COMPLETED';
      case SprintStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return const Color(0xFFF59E0B);
      case TaskStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case TaskStatus.done:
        return const Color(0xFF10B981);
    }
  }

  String _getTaskStatusName(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Color _getTaskPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  String _getTaskPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
}


