import 'package:equatable/equatable.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';

abstract class TasksBoardEvent extends Equatable {
  const TasksBoardEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasksBoardRequested extends TasksBoardEvent {
  const LoadTasksBoardRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class TaskStatusUpdatedRequested extends TasksBoardEvent {
  const TaskStatusUpdatedRequested({
    required this.taskId,
    required this.projectId,
    required this.newStatus,
  });

  final String taskId;
  final String projectId;
  final TaskStatus newStatus;

  @override
  List<Object?> get props => [taskId, projectId, newStatus];
}

