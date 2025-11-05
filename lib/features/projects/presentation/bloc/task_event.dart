import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';

abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscribeTasksRequested extends TaskEvent {
  SubscribeTasksRequested({required this.projectId});
  final String projectId;

  @override
  List<Object?> get props => [projectId];
}

class CreateTaskRequested extends TaskEvent {
  CreateTaskRequested({required this.task});
  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

class UpdateTaskStatusRequested extends TaskEvent {
  UpdateTaskStatusRequested({required this.projectId, required this.taskId, required this.status});
  final String projectId;
  final String taskId;
  final TaskStatus status;

  @override
  List<Object?> get props => [projectId, taskId, status];
}

class ApplyTaskFiltersRequested extends TaskEvent {
  ApplyTaskFiltersRequested({this.assigneeId, this.priority, this.dueBefore});
  final String? assigneeId;
  final TaskPriority? priority;
  final DateTime? dueBefore;

  @override
  List<Object?> get props => [assigneeId, priority, dueBefore];
}


