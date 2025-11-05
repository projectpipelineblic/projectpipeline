import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

class DashboardData extends Equatable {
  final List<TaskEntity> todaysTasks;
  final List<ProjectEntity> openProjects;

  const DashboardData({
    required this.todaysTasks,
    required this.openProjects,
  });

  @override
  List<Object?> get props => [todaysTasks, openProjects];
}

