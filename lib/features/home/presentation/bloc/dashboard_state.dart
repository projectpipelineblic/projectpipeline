import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<TaskEntity> openTasks;
  final List<ProjectEntity> openProjects;

  DashboardLoaded({
    required this.openTasks,
    required this.openProjects,
  });

  @override
  List<Object?> get props => [openTasks, openProjects];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

