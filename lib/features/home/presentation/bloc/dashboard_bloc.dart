import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_user_tasks_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_open_projects_usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

// ==================== EVENTS ====================
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  final String userId;
  DashboardLoadRequested(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class DashboardRefreshRequested extends DashboardEvent {
  final String userId;
  DashboardRefreshRequested(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

// ==================== STATES ====================
abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardSuccess extends DashboardState {
  final List<ProjectEntity> projects;
  final List<TaskEntity> tasks;
  
  DashboardSuccess({
    required this.projects,
    required this.tasks,
  });
  
  // Computed properties for stats
  int get totalProjects => projects.length;
  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.status == TaskStatus.done).length;
  int get pendingTasks => tasks.where((t) => t.status != TaskStatus.done).length;
  
  @override
  List<Object?> get props => [projects, tasks];
}

class DashboardFailure extends DashboardState {
  final String error;
  DashboardFailure(this.error);
  
  @override
  List<Object?> get props => [error];
}

// ==================== BLOC ====================
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetUserTasks getUserTasks;
  final GetOpenProjects getOpenProjects;

  DashboardBloc({
    required this.getUserTasks,
    required this.getOpenProjects,
  }) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _loadData(event.userId, emit);
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Don't emit loading state on refresh to avoid UI flash
    await _loadData(event.userId, emit);
  }

  Future<void> _loadData(
    String userId,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Fetch data in parallel for faster loading
      final results = await Future.wait([
        getUserTasks(GetUserTasksParams(userId: userId)),
        getOpenProjects(GetOpenProjectsParams(userId: userId)),
      ]);

      final tasksResult = results[0];
      final projectsResult = results[1];

      // Check for failures
      if (tasksResult.isLeft()) {
        tasksResult.fold(
          (failure) => emit(DashboardFailure(failure.message)),
          (_) => null,
        );
        return;
      }

      if (projectsResult.isLeft()) {
        projectsResult.fold(
          (failure) => emit(DashboardFailure(failure.message)),
          (_) => null,
        );
        return;
      }

      // Extract successful data
      List<TaskEntity> tasks = [];
      List<ProjectEntity> projects = [];

      tasksResult.fold(
        (_) => null,
        (data) => tasks = List<TaskEntity>.from(data),
      );

      projectsResult.fold(
        (_) => null,
        (data) => projects = List<ProjectEntity>.from(data),
      );

      emit(DashboardSuccess(
        projects: projects,
        tasks: tasks,
      ));
    } catch (e) {
      emit(DashboardFailure('Failed to load dashboard: $e'));
    }
  }
}
