import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/features/home/presentation/bloc/dashboard_event.dart';
import 'package:task_app/features/home/presentation/bloc/dashboard_state.dart';
import 'package:task_app/features/projects/domain/usecases/get_user_tasks_usecase.dart';
import 'package:task_app/features/projects/domain/usecases/get_open_projects_usecase.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetUserTasks _getUserTasks;
  final GetOpenProjects _getOpenProjects;

  DashboardBloc({
    required GetUserTasks getUserTasks,
    required GetOpenProjects getOpenProjects,
  })  : _getUserTasks = getUserTasks,
        _getOpenProjects = getOpenProjects,
        super(DashboardInitial()) {
    on<LoadDashboardDataRequested>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    final tasksResult = await _getUserTasks(GetUserTasksParams(userId: event.userId));
    final projectsResult = await _getOpenProjects(GetOpenProjectsParams(userId: event.userId));

    tasksResult.fold(
      (failure) => emit(DashboardError(message: failure.message)),
      (tasks) {
        projectsResult.fold(
          (failure) => emit(DashboardError(message: failure.message)),
          (projects) {
            // Filter open tasks (tasks that are not fully completed and have subtasks to work on)
            final openTasks = tasks.where((task) {
              // Exclude completed tasks
              if (task.status == TaskStatus.done) return false;
              
              // Include tasks that are in progress or have subtasks
              // This shows tasks with work remaining (either not started or in progress)
              return task.status == TaskStatus.todo || 
                     task.status == TaskStatus.inProgress ||
                     task.subTasks.isNotEmpty;
            }).toList();

            emit(DashboardLoaded(
              openTasks: openTasks,
              openProjects: projects,
            ));
          },
        );
      },
    );
  }
}

