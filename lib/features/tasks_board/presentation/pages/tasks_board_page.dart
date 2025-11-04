import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/core/di/service_locator.dart';
import 'package:task_app/core/services/local_storage_service.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';
import 'package:task_app/features/projects/presentation/pages/task_detail_page.dart';
import 'package:task_app/features/projects/presentation/shared/task_types.dart' as task_types;
import 'package:task_app/features/tasks_board/presentation/bloc/tasks_board_bloc.dart';
import 'package:task_app/features/tasks_board/presentation/bloc/tasks_board_event.dart';
import 'package:task_app/features/tasks_board/presentation/bloc/tasks_board_state.dart';
import 'package:task_app/features/tasks_board/presentation/widgets/vertical_task_section_widget.dart';

class TasksBoardPage extends StatefulWidget {
  const TasksBoardPage({super.key});

  @override
  State<TasksBoardPage> createState() => _TasksBoardPageState();
}

class _TasksBoardPageState extends State<TasksBoardPage> {
  late final TasksBoardBloc _tasksBoardBloc;
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  double _dragPosition = 0;

  @override
  void initState() {
    super.initState();
    _tasksBoardBloc = sl<TasksBoardBloc>();
    _loadTasks();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tasksBoardBloc.close();
    super.dispose();
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

  Future<void> _loadTasks() async {
    final user = await sl<LocalStorageService>().getCachedUser();
    if (user != null && user.uid != null) {
      _tasksBoardBloc.add(LoadTasksBoardRequested(userId: user.uid!));
    }
  }

  void _onTaskDrop(TaskEntity task, TaskStatus newStatus) {
    if (task.status != newStatus) {
      _tasksBoardBloc.add(
        TaskStatusUpdatedRequested(
          taskId: task.id,
          projectId: task.projectId,
          newStatus: newStatus,
        ),
      );
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
    );

    // Navigate to detail page and wait for return
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(
          task: taskItem,
          projectId: task.projectId,
        ),
      ),
    );
    
    // Reload tasks when returning from detail page
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tasksBoardBloc,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: PrimaryText(
            text: 'Tasks Board',
            size: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFE5E7EB)
                : AppPallete.secondary,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            // Reload tasks when username is updated
            if (authState is UsernameUpdated || authState is AuthAuthenticated) {
              _loadTasks();
            }
          },
          child: BlocConsumer<TasksBoardBloc, TasksBoardState>(
            listener: (context, state) {
            if (state is TasksBoardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is TasksBoardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppPallete.primary),
                ),
              );
            } else if (state is TasksBoardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    PrimaryText(
                      text: state.message,
                      size: 16,
                      color: AppPallete.textGray,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadTasks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.primary,
                        foregroundColor: AppPallete.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const PrimaryText(
                        text: 'Retry',
                        size: 16,
                        color: AppPallete.white,
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is TasksBoardLoaded) {
              return RefreshIndicator(
                onRefresh: _loadTasks,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      VerticalTaskSectionWidget(
                        title: 'Todo',
                        tasks: state.todoTasks,
                        columnStatus: TaskStatus.todo,
                        headerColor: Colors.blue,
                        onTaskTap: _onTaskTap,
                        onTaskDrop: (task) => _onTaskDrop(task, TaskStatus.todo),
                        onDragStart: _onDragStart,
                        onDragEnd: _onDragEnd,
                        onDragUpdate: _updateDragPosition,
                      ),
                      VerticalTaskSectionWidget(
                        title: 'In Progress',
                        tasks: state.inProgressTasks,
                        columnStatus: TaskStatus.inProgress,
                        headerColor: Colors.orange,
                        onTaskTap: _onTaskTap,
                        onTaskDrop: (task) =>
                            _onTaskDrop(task, TaskStatus.inProgress),
                        onDragStart: _onDragStart,
                        onDragEnd: _onDragEnd,
                        onDragUpdate: _updateDragPosition,
                      ),
                      VerticalTaskSectionWidget(
                        title: 'Completed',
                        tasks: state.completedTasks,
                        columnStatus: TaskStatus.done,
                        headerColor: Colors.green,
                        onTaskTap: _onTaskTap,
                        onTaskDrop: (task) => _onTaskDrop(task, TaskStatus.done),
                        onDragStart: _onDragStart,
                        onDragEnd: _onDragEnd,
                        onDragUpdate: _updateDragPosition,
                      ),
                      const SizedBox(height: 16),
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
    );
  }
}

