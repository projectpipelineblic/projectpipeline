import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/usecases/create_task_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/stream_tasks_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/update_task_status_usecase.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/task_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({
    required StreamTasks streamTasks,
    required CreateTask createTask,
    required UpdateTaskStatus updateTaskStatus,
  })  : _streamTasks = streamTasks,
        _createTask = createTask,
        _updateTaskStatus = updateTaskStatus,
        super(const TaskState()) {
    on<SubscribeTasksRequested>(_onSubscribe);
    on<CreateTaskRequested>(_onCreate);
    on<UpdateTaskStatusRequested>(_onUpdateStatus);
    on<ApplyTaskFiltersRequested>(_onApplyFilters);
  }

  final StreamTasks _streamTasks;
  final CreateTask _createTask;
  final UpdateTaskStatus _updateTaskStatus;
  StreamSubscription<List<TaskEntity>>? _sub;

  Future<void> _onSubscribe(SubscribeTasksRequested event, Emitter<TaskState> emit) async {
    await _sub?.cancel();
    emit(state.copyWith(loading: true));
    _sub = _streamTasks(event.projectId).listen((tasks) {
      emit(state.copyWith(loading: false, tasks: tasks, errorMessage: null));
    }, onError: (e) {
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    });
  }

  Future<void> _onCreate(CreateTaskRequested event, Emitter<TaskState> emit) async {
    await _createTask(event.task);
  }

  Future<void> _onUpdateStatus(UpdateTaskStatusRequested event, Emitter<TaskState> emit) async {
    await _updateTaskStatus(UpdateTaskStatusParams(
      projectId: event.projectId,
      taskId: event.taskId,
      status: event.status,
    ));
  }

  void _onApplyFilters(ApplyTaskFiltersRequested event, Emitter<TaskState> emit) {
    emit(state.copyWith(
      assigneeId: event.assigneeId,
      priority: event.priority,
      dueBefore: event.dueBefore,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}


