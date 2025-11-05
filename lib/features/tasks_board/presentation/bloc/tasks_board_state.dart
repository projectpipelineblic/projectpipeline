import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';

abstract class TasksBoardState extends Equatable {
  const TasksBoardState();

  @override
  List<Object?> get props => [];
}

class TasksBoardInitial extends TasksBoardState {}

class TasksBoardLoading extends TasksBoardState {}

class TasksBoardLoaded extends TasksBoardState {
  const TasksBoardLoaded({
    required this.todoTasks,
    required this.inProgressTasks,
    required this.completedTasks,
  });

  final List<TaskEntity> todoTasks;
  final List<TaskEntity> inProgressTasks;
  final List<TaskEntity> completedTasks;

  TasksBoardLoaded copyWith({
    List<TaskEntity>? todoTasks,
    List<TaskEntity>? inProgressTasks,
    List<TaskEntity>? completedTasks,
  }) {
    return TasksBoardLoaded(
      todoTasks: todoTasks ?? this.todoTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  @override
  List<Object?> get props => [todoTasks, inProgressTasks, completedTasks];
}

class TasksBoardError extends TasksBoardState {
  const TasksBoardError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class TaskStatusUpdating extends TasksBoardState {
  const TaskStatusUpdating({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class TaskStatusUpdated extends TasksBoardState {
  const TaskStatusUpdated();
}

