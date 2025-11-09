import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';

abstract class SprintEvent extends Equatable {
  const SprintEvent();

  @override
  List<Object?> get props => [];
}

class LoadSprintsRequested extends SprintEvent {
  final String projectId;

  const LoadSprintsRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class CreateSprintRequested extends SprintEvent {
  final String projectId;
  final String name;
  final String? goal;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;

  const CreateSprintRequested({
    required this.projectId,
    required this.name,
    this.goal,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [projectId, name, goal, startDate, endDate, createdBy];
}

class StartSprintRequested extends SprintEvent {
  final String projectId;
  final String sprintId;

  const StartSprintRequested({
    required this.projectId,
    required this.sprintId,
  });

  @override
  List<Object?> get props => [projectId, sprintId];
}

class CompleteSprintRequested extends SprintEvent {
  final String projectId;
  final String sprintId;

  const CompleteSprintRequested({
    required this.projectId,
    required this.sprintId,
  });

  @override
  List<Object?> get props => [projectId, sprintId];
}

class LoadActiveSprintRequested extends SprintEvent {
  final String projectId;

  const LoadActiveSprintRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class UpdateSprintStoryPointsRequested extends SprintEvent {
  final String projectId;
  final String sprintId;
  final int totalStoryPoints;
  final int completedStoryPoints;

  const UpdateSprintStoryPointsRequested({
    required this.projectId,
    required this.sprintId,
    required this.totalStoryPoints,
    required this.completedStoryPoints,
  });

  @override
  List<Object?> get props => [projectId, sprintId, totalStoryPoints, completedStoryPoints];
}

