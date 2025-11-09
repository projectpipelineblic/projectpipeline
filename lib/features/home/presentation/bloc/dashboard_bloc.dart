import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_user_tasks_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_open_projects_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/stream_user_tasks_usecase.dart';
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
  final StreamUserTasks streamUserTasks;
  
  List<ProjectEntity> _cachedProjects = [];

  DashboardBloc({
    required this.getUserTasks,
    required this.getOpenProjects,
    required this.streamUserTasks,
  }) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    
    // Load initial data first
    await _loadProjects(event.userId);
    
    // Load initial tasks
    final initialTasksResult = await getUserTasks(GetUserTasksParams(userId: event.userId));
    List<TaskEntity> initialTasks = [];
    initialTasksResult.fold(
      (failure) => emit(DashboardFailure(failure.message)),
      (tasks) => initialTasks = List<TaskEntity>.from(tasks),
    );
    
    // If we got initial data, emit success state
    if (initialTasksResult.isRight()) {
      emit(DashboardSuccess(
        projects: _cachedProjects,
        tasks: initialTasks,
      ));
    }
    
    // Then subscribe to real-time updates using emit.forEach
    // This keeps the event handler alive and allows emitting from stream
    await emit.forEach(
      streamUserTasks(event.userId),
      onData: (tasks) {
        // Update state with new tasks from stream
        return DashboardSuccess(
          projects: _cachedProjects,
          tasks: tasks,
        );
      },
      onError: (error, stackTrace) {
        return DashboardFailure('Failed to load tasks: $error');
      },
    );
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Reload projects and tasks, then resubscribe
    await _loadProjects(event.userId);
    
    final tasksResult = await getUserTasks(GetUserTasksParams(userId: event.userId));
        tasksResult.fold(
          (failure) => emit(DashboardFailure(failure.message)),
      (tasks) => emit(DashboardSuccess(
        projects: _cachedProjects,
        tasks: List<TaskEntity>.from(tasks),
      )),
    );
    
    // Subscribe to real-time updates using emit.forEach
    await emit.forEach(
      streamUserTasks(event.userId),
      onData: (tasks) {
        return DashboardSuccess(
          projects: _cachedProjects,
          tasks: tasks,
        );
      },
      onError: (error, stackTrace) {
        return DashboardFailure('Failed to load tasks: $error');
      },
    );
  }

  Future<void> _loadProjects(String userId) async {
    try {
      final projectsResult = await getOpenProjects(GetOpenProjectsParams(userId: userId));
      projectsResult.fold(
        (_) => null,
        (projects) => _cachedProjects = List<ProjectEntity>.from(projects),
      );
    } catch (e) {
      // Handle error silently, will be shown when emitting state
    }
  }
}
