import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String? id;
  final String name;
  final String description;
  final String creatorUid;
  final String creatorName;
  final DateTime createdAt;
  final List<ProjectMember> members;
  final List<ProjectInvite> pendingInvites;

  const ProjectEntity({
    this.id,
    required this.name,
    required this.description,
    required this.creatorUid,
    required this.creatorName,
    required this.createdAt,
    required this.members,
    required this.pendingInvites,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        creatorUid,
        creatorName,
        createdAt,
        members,
        pendingInvites,
      ];
}

class ProjectMember extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'member'
  final bool hasAccess;

  const ProjectMember({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.hasAccess,
  });

  @override
  List<Object?> get props => [uid, email, name, role, hasAccess];
}

class ProjectInvite extends Equatable {
  final String inviteId;
  final String projectId;
  final String projectName;
  final String invitedUserUid;
  final String invitedUserEmail;
  final String creatorUid;
  final String creatorName;
  final DateTime createdAt;
  final String role;
  final bool hasAccess;
  final String status; // 'pending' or 'accepted'

  const ProjectInvite({
    required this.inviteId,
    required this.projectId,
    required this.projectName,
    required this.invitedUserUid,
    required this.invitedUserEmail,
    required this.creatorUid,
    required this.creatorName,
    required this.createdAt,
    required this.role,
    required this.hasAccess,
    required this.status,
  });

  @override
  List<Object?> get props => [
        inviteId,
        projectId,
        projectName,
        invitedUserUid,
        invitedUserEmail,
        creatorUid,
        creatorName,
        createdAt,
        role,
        hasAccess,
        status,
      ];
}

