import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';
import 'package:task_app/features/projects/domain/usecases/update_task_status_usecase.dart';
import 'package:task_app/features/tasks_board/domain/usecases/get_all_user_tasks_usecase.dart';
import 'package:task_app/features/tasks_board/presentation/bloc/tasks_board_event.dart';
import 'package:task_app/features/tasks_board/presentation/bloc/tasks_board_state.dart';

class TasksBoardBloc extends Bloc<TasksBoardEvent, TasksBoardState> {
  TasksBoardBloc({
    required GetAllUserTasks getAllUserTasks,
    required UpdateTaskStatus updateTaskStatus,
  })  : _getAllUserTasks = getAllUserTasks,
        _updateTaskStatus = updateTaskStatus,
        super(TasksBoardInitial()) {
    on<LoadTasksBoardRequested>(_onLoadTasksBoard);
    on<TaskStatusUpdatedRequested>(_onTaskStatusUpdated);
  }

  final GetAllUserTasks _getAllUserTasks;
  final UpdateTaskStatus _updateTaskStatus;
  String? _lastUserId;

  Future<void> _onLoadTasksBoard(
    LoadTasksBoardRequested event,
    Emitter<TasksBoardState> emit,
  ) async {
    _lastUserId = event.userId;
    
    // Only show loading if we don't have data yet
    if (state is! TasksBoardLoaded) {
      emit(TasksBoardLoading());
    }

    final result = await _getAllUserTasks(GetAllUserTasksParams(userId: event.userId));

    result.fold(
      (failure) => emit(TasksBoardError(message: failure.message)),
      (tasks) {
        final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).toList();
        final inProgressTasks =
            tasks.where((t) => t.status == TaskStatus.inProgress).toList();
        final completedTasks = tasks.where((t) => t.status == TaskStatus.done).toList();

        emit(TasksBoardLoaded(
          todoTasks: todoTasks,
          inProgressTasks: inProgressTasks,
          completedTasks: completedTasks,
        ));
      },
    );
  }

  Future<void> _onTaskStatusUpdated(
    TaskStatusUpdatedRequested event,
    Emitter<TasksBoardState> emit,
  ) async {
    final currentState = state;
    
    // Optimistic update - update UI immediately
    if (currentState is TasksBoardLoaded) {
      // Find the task to update
      final allTasks = [
        ...currentState.todoTasks,
        ...currentState.inProgressTasks,
        ...currentState.completedTasks,
      ];
      
      final taskToUpdateIndex = allTasks.indexWhere((t) => t.id == event.taskId);
      if (taskToUpdateIndex == -1) return;
      
      final taskToUpdate = allTasks[taskToUpdateIndex];
      
      // Create updated task with new status
      final updatedTask = TaskEntity(
        id: taskToUpdate.id,
        projectId: taskToUpdate.projectId,
        title: taskToUpdate.title,
        description: taskToUpdate.description,
        assigneeId: taskToUpdate.assigneeId,
        assigneeName: taskToUpdate.assigneeName,
        priority: taskToUpdate.priority,
        subTasks: taskToUpdate.subTasks,
        dueDate: taskToUpdate.dueDate,
        status: event.newStatus,
        createdAt: taskToUpdate.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // Remove from old list
      var updatedTodoTasks = List<TaskEntity>.from(currentState.todoTasks);
      var updatedInProgressTasks = List<TaskEntity>.from(currentState.inProgressTasks);
      var updatedCompletedTasks = List<TaskEntity>.from(currentState.completedTasks);
      
      updatedTodoTasks.removeWhere((t) => t.id == event.taskId);
      updatedInProgressTasks.removeWhere((t) => t.id == event.taskId);
      updatedCompletedTasks.removeWhere((t) => t.id == event.taskId);
      
      // Add to the new list based on new status
      if (event.newStatus == TaskStatus.todo) {
        updatedTodoTasks.add(updatedTask);
      } else if (event.newStatus == TaskStatus.inProgress) {
        updatedInProgressTasks.add(updatedTask);
      } else if (event.newStatus == TaskStatus.done) {
        updatedCompletedTasks.add(updatedTask);
      }
      
      // Immediately emit the optimistic state
      emit(TasksBoardLoaded(
        todoTasks: updatedTodoTasks,
        inProgressTasks: updatedInProgressTasks,
        completedTasks: updatedCompletedTasks,
      ));
    }

    // Update in the backend in the background (don't await)
    _updateTaskStatus(UpdateTaskStatusParams(
      projectId: event.projectId,
      taskId: event.taskId,
      status: event.newStatus,
    )).then((result) {
      result.fold(
        (failure) {
          // If backend fails, reload to show correct state
          if (_lastUserId != null) {
            add(LoadTasksBoardRequested(userId: _lastUserId!));
          }
        },
        (_) {
          // Success - optimistic update is already applied
        },
      );
    });
  }
}

