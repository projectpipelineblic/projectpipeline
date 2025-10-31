import 'package:equatable/equatable.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';

class TaskState extends Equatable {
  const TaskState({
    this.loading = false,
    this.errorMessage,
    this.tasks = const <TaskEntity>[],
    this.assigneeId,
    this.priority,
    this.dueBefore,
  });

  final bool loading;
  final String? errorMessage;
  final List<TaskEntity> tasks;
  final String? assigneeId;
  final TaskPriority? priority;
  final DateTime? dueBefore;

  TaskState copyWith({
    bool? loading,
    String? errorMessage,
    List<TaskEntity>? tasks,
    String? assigneeId,
    TaskPriority? priority,
    DateTime? dueBefore,
  }) {
    return TaskState(
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
      tasks: tasks ?? this.tasks,
      assigneeId: assigneeId ?? this.assigneeId,
      priority: priority ?? this.priority,
      dueBefore: dueBefore ?? this.dueBefore,
    );
  }

  @override
  List<Object?> get props => [loading, errorMessage, tasks, assigneeId, priority, dueBefore];
}


