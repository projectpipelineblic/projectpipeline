import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { todo, inProgress, done }

class TaskEntity extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final TaskPriority priority;
  final List<String> subTasks;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? statusName; // Custom status name (e.g., "Review", "Pre-review")
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.priority,
    required this.subTasks,
    required this.dueDate,
    required this.status,
    this.statusName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        assigneeId,
        assigneeName,
        priority,
        subTasks,
        dueDate,
        status,
        statusName,
        createdAt,
        updatedAt,
      ];
}


