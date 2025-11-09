import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/features/projects/domain/usecases/complete_sprint_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/create_sprint_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_active_sprint_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_sprints_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/start_sprint_usecase.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/sprint_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/sprint_state.dart';

class SprintBloc extends Bloc<SprintEvent, SprintState> {
  final GetSprints getSprints;
  final CreateSprint createSprint;
  final StartSprint startSprint;
  final CompleteSprint completeSprint;
  final GetActiveSprint getActiveSprint;

  SprintBloc({
    required this.getSprints,
    required this.createSprint,
    required this.startSprint,
    required this.completeSprint,
    required this.getActiveSprint,
  }) : super(SprintInitial()) {
    on<LoadSprintsRequested>(_onLoadSprintsRequested);
    on<CreateSprintRequested>(_onCreateSprintRequested);
    on<StartSprintRequested>(_onStartSprintRequested);
    on<CompleteSprintRequested>(_onCompleteSprintRequested);
    on<LoadActiveSprintRequested>(_onLoadActiveSprintRequested);
  }

  Future<void> _onLoadSprintsRequested(
    LoadSprintsRequested event,
    Emitter<SprintState> emit,
  ) async {
    emit(SprintLoading());

    final result = await getSprints(GetSprintsParams(projectId: event.projectId));

    result.fold(
      (failure) => emit(SprintError(failure.message)),
      (sprints) async {
        // Also load active sprint
        final activeSprintResult = await getActiveSprint(
          GetActiveSprintParams(projectId: event.projectId),
        );

        activeSprintResult.fold(
          (failure) => emit(SprintsLoaded(sprints: sprints)),
          (activeSprint) => emit(SprintsLoaded(
            sprints: sprints,
            activeSprint: activeSprint,
          )),
        );
      },
    );
  }

  Future<void> _onCreateSprintRequested(
    CreateSprintRequested event,
    Emitter<SprintState> emit,
  ) async {
    emit(SprintLoading());

    final result = await createSprint(CreateSprintParams(
      projectId: event.projectId,
      name: event.name,
      goal: event.goal,
      startDate: event.startDate,
      endDate: event.endDate,
      createdBy: event.createdBy,
    ));

    result.fold(
      (failure) => emit(SprintError(failure.message)),
      (sprintId) {
        emit(SprintCreated(sprintId));
        // Reload sprints
        add(LoadSprintsRequested(event.projectId));
      },
    );
  }

  Future<void> _onStartSprintRequested(
    StartSprintRequested event,
    Emitter<SprintState> emit,
  ) async {
    emit(SprintLoading());

    final result = await startSprint(StartSprintParams(
      projectId: event.projectId,
      sprintId: event.sprintId,
    ));

    result.fold(
      (failure) => emit(SprintError(failure.message)),
      (_) {
        emit(SprintStarted(event.sprintId));
        // Reload sprints
        add(LoadSprintsRequested(event.projectId));
      },
    );
  }

  Future<void> _onCompleteSprintRequested(
    CompleteSprintRequested event,
    Emitter<SprintState> emit,
  ) async {
    emit(SprintLoading());

    final result = await completeSprint(CompleteSprintParams(
      projectId: event.projectId,
      sprintId: event.sprintId,
    ));

    result.fold(
      (failure) => emit(SprintError(failure.message)),
      (_) {
        emit(SprintCompleted(event.sprintId));
        // Reload sprints
        add(LoadSprintsRequested(event.projectId));
      },
    );
  }

  Future<void> _onLoadActiveSprintRequested(
    LoadActiveSprintRequested event,
    Emitter<SprintState> emit,
  ) async {
    final result = await getActiveSprint(
      GetActiveSprintParams(projectId: event.projectId),
    );

    result.fold(
      (failure) => emit(SprintError(failure.message)),
      (activeSprint) => emit(ActiveSprintLoaded(activeSprint)),
    );
  }
}

