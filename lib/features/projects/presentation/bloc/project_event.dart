import 'package:equatable/equatable.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class CreateProjectRequested extends ProjectEvent {
  final String name;
  final String description;
  final String creatorUid;
  final String creatorName;
  final List<Map<String, dynamic>> teamMembers;
  final List<Map<String, String>>? customStatuses;

  const CreateProjectRequested({
    required this.name,
    required this.description,
    required this.creatorUid,
    required this.creatorName,
    required this.teamMembers,
    this.customStatuses,
  });

  @override
  List<Object?> get props => [name, description, creatorUid, creatorName, teamMembers, customStatuses];
}

class GetProjectsRequested extends ProjectEvent {
  final String userId;

  const GetProjectsRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class FindUserByEmailRequested extends ProjectEvent {
  final String email;

  const FindUserByEmailRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class GetInvitesRequested extends ProjectEvent {
  final String userId;

  const GetInvitesRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AcceptInviteRequested extends ProjectEvent {
  final String inviteId;

  const AcceptInviteRequested({required this.inviteId});

  @override
  List<Object?> get props => [inviteId];
}

class RejectInviteRequested extends ProjectEvent {
  final String inviteId;

  const RejectInviteRequested({required this.inviteId});

  @override
  List<Object?> get props => [inviteId];
}

class UpdateProjectRequested extends ProjectEvent {
  final String projectId;
  final String? name;
  final String? description;
  final List<Map<String, String>>? customStatuses;

  const UpdateProjectRequested({
    required this.projectId,
    this.name,
    this.description,
    this.customStatuses,
  });

  @override
  List<Object?> get props => [projectId, name, description, customStatuses];
}

