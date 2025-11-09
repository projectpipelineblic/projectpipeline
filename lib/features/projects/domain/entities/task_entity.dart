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
  final int timeSpentMinutes; // Total time spent on task in minutes
  final DateTime? startedAt; // When the task was moved to in-progress
  
  // Sprint/Scrum fields
  final String? sprintId; // ID of the sprint this task belongs to
  final int? storyPoints; // Story points estimation (Fibonacci: 1, 2, 3, 5, 8, 13)
  final double? estimatedHours; // Time estimation in hours
  final String? sprintStatus; // Status within sprint: 'backlog', 'committed', 'completed'

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
    this.timeSpentMinutes = 0,
    this.startedAt,
    this.sprintId,
    this.storyPoints,
    this.estimatedHours,
    this.sprintStatus = 'backlog',
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
        timeSpentMinutes,
        startedAt,
        sprintId,
        storyPoints,
        estimatedHours,
        sprintStatus,
      ];
}


