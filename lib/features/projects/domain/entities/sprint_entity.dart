import 'package:equatable/equatable.dart';

enum SprintStatus { planning, active, completed, cancelled }

class SprintEntity extends Equatable {
  final String id;
  final String projectId;
  final String name;
  final String? goal;
  final DateTime startDate;
  final DateTime endDate;
  final SprintStatus status;
  final int totalStoryPoints; // Total story points committed
  final int completedStoryPoints; // Story points completed
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const SprintEntity({
    required this.id,
    required this.projectId,
    required this.name,
    this.goal,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.totalStoryPoints = 0,
    this.completedStoryPoints = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Calculate sprint progress percentage
  double get progressPercentage {
    if (totalStoryPoints == 0) return 0.0;
    return (completedStoryPoints / totalStoryPoints) * 100;
  }

  // Calculate remaining days
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  // Calculate total sprint duration in days
  int get totalDays {
    return endDate.difference(startDate).inDays;
  }

  // Check if sprint is active
  bool get isActive => status == SprintStatus.active;

  // Check if sprint is overdue
  bool get isOverdue {
    return status == SprintStatus.active && DateTime.now().isAfter(endDate);
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        goal,
        startDate,
        endDate,
        status,
        totalStoryPoints,
        completedStoryPoints,
        createdAt,
        updatedAt,
        createdBy,
      ];
}

