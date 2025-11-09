import 'package:equatable/equatable.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';

abstract class SprintState extends Equatable {
  const SprintState();

  @override
  List<Object?> get props => [];
}

class SprintInitial extends SprintState {}

class SprintLoading extends SprintState {}

class SprintsLoaded extends SprintState {
  final List<SprintEntity> sprints;
  final SprintEntity? activeSprint;

  const SprintsLoaded({
    required this.sprints,
    this.activeSprint,
  });

  @override
  List<Object?> get props => [sprints, activeSprint];
}

class SprintCreated extends SprintState {
  final String sprintId;

  const SprintCreated(this.sprintId);

  @override
  List<Object?> get props => [sprintId];
}

class SprintStarted extends SprintState {
  final String sprintId;

  const SprintStarted(this.sprintId);

  @override
  List<Object?> get props => [sprintId];
}

class SprintCompleted extends SprintState {
  final String sprintId;

  const SprintCompleted(this.sprintId);

  @override
  List<Object?> get props => [sprintId];
}

class SprintError extends SprintState {
  final String message;

  const SprintError(this.message);

  @override
  List<Object?> get props => [message];
}

class ActiveSprintLoaded extends SprintState {
  final SprintEntity? activeSprint;

  const ActiveSprintLoaded(this.activeSprint);

  @override
  List<Object?> get props => [activeSprint];
}

