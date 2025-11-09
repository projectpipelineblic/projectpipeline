import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

abstract class ProjectRepository {
  Future<Either<Failure, ProjectEntity>> createProject({
    required String name,
    required String description,
    required String creatorUid,
    required String creatorName,
    required List<Map<String, dynamic>> teamMembers,
    List<Map<String, String>>? customStatuses,
    String? projectType,
    String? workflowType,
    String? projectKey,
    Map<String, bool>? additionalFeatures,
  });

  Future<Either<Failure, List<ProjectEntity>>> getProjects(String userId);

  Future<Either<Failure, List<ProjectEntity>>> getOpenProjects(String userId);

  Future<Either<Failure, ProjectEntity>> updateProject({
    required String projectId,
    String? name,
    String? description,
    List<Map<String, String>>? customStatuses,
  });

  Future<Either<Failure, UserInfo>> findUserByEmail(String email);

  Future<Either<Failure, void>> sendTeamInvite({
    required String projectId,
    required String invitedUserUid,
    required String invitedUserEmail,
    required String creatorUid,
    required String creatorName,
    required String projectName,
    required String role,
    required bool hasAccess,
  });

  Future<Either<Failure, List<ProjectInvite>>> getInvites(String userId);

  Future<Either<Failure, void>> acceptInvite(String inviteId);

  Future<Either<Failure, void>> rejectInvite(String inviteId);

  Future<Either<Failure, void>> deleteProject(String projectId);
}

class UserInfo {
  final String uid;
  final String email;
  final String name;

  UserInfo({
    required this.uid,
    required this.email,
    required this.name,
  });
}

