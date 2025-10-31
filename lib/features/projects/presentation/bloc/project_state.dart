import 'package:equatable/equatable.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<ProjectEntity> projects;

  const ProjectLoaded({required this.projects});

  @override
  List<Object?> get props => [projects];
}

class ProjectCreated extends ProjectState {
  final ProjectEntity project;

  const ProjectCreated({required this.project});

  @override
  List<Object?> get props => [project];
}

class UserFound extends ProjectState {
  final UserInfo userInfo;

  const UserFound({required this.userInfo});

  @override
  List<Object?> get props => [userInfo];
}

class InvitesLoaded extends ProjectState {
  final List<ProjectInvite> invites;

  const InvitesLoaded({required this.invites});

  @override
  List<Object?> get props => [invites];
}

class InviteAccepted extends ProjectState {}

class InviteRejected extends ProjectState {}

class ProjectError extends ProjectState {
  final String message;

  const ProjectError({required this.message});

  @override
  List<Object?> get props => [message];
}

