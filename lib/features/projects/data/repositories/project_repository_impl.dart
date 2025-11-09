import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/features/projects/data/datasources/project_remote_datasource.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDatasource _remoteDatasource;

  ProjectRepositoryImpl({required ProjectRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
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
  }) async {
    try {
      print('🔵 [ProjectRepository] Creating project: $name');
      print('🔍 [ProjectRepository] Custom statuses: $customStatuses');
      print('🔍 [ProjectRepository] Project type: $projectType');
      print('🔍 [ProjectRepository] Workflow type: $workflowType');
      print('🔍 [ProjectRepository] Project key: $projectKey');
      
      final project = await _remoteDatasource.createProject(
        name: name,
        description: description,
        creatorUid: creatorUid,
        creatorName: creatorName,
        teamMembers: teamMembers,
        customStatuses: customStatuses,
        projectType: projectType,
        workflowType: workflowType,
        projectKey: projectKey,
        additionalFeatures: additionalFeatures,
      );
      
      print('✅ [ProjectRepository] Project created: ${project.id}');
      print('🔍 [ProjectRepository] Project has ${project.customStatuses?.length ?? 0} custom statuses');
      
      return Right(project);
    } catch (e) {
      print('❌ [ProjectRepository] Error: $e');
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProjectEntity>>> getProjects(String userId) async {
    try {
      final projects = await _remoteDatasource.getProjects(userId);
      return Right(projects);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProjectEntity>>> getOpenProjects(String userId) async {
    try {
      final projects = await _remoteDatasource.getOpenProjects(userId);
      return Right(projects);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProjectEntity>> updateProject({
    required String projectId,
    String? name,
    String? description,
    List<Map<String, String>>? customStatuses,
  }) async {
    try {
      print('🔵 [ProjectRepository] Updating project: $projectId');
      print('🔍 [ProjectRepository] Custom statuses: $customStatuses');
      
      final project = await _remoteDatasource.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        customStatuses: customStatuses,
      );
      
      print('✅ [ProjectRepository] Project updated: ${project.id}');
      print('🔍 [ProjectRepository] Project has ${project.customStatuses?.length ?? 0} custom statuses');
      
      return Right(project);
    } catch (e) {
      print('❌ [ProjectRepository] Error: $e');
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserInfo>> findUserByEmail(String email) async {
    try {
      final user = await _remoteDatasource.findUserByEmail(email);
      return Right(user);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendTeamInvite({
    required String projectId,
    required String invitedUserUid,
    required String invitedUserEmail,
    required String creatorUid,
    required String creatorName,
    required String projectName,
    required String role,
    required bool hasAccess,
  }) async {
    try {
      await _remoteDatasource.sendTeamInvite(
        projectId: projectId,
        invitedUserUid: invitedUserUid,
        invitedUserEmail: invitedUserEmail,
        creatorUid: creatorUid,
        creatorName: creatorName,
        projectName: projectName,
        role: role,
        hasAccess: hasAccess,
      );
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProjectInvite>>> getInvites(String userId) async {
    try {
      final invites = await _remoteDatasource.getInvites(userId);
      return Right(invites);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptInvite(String inviteId) async {
    try {
      await _remoteDatasource.acceptInvite(inviteId);
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectInvite(String inviteId) async {
    try {
      await _remoteDatasource.rejectInvite(inviteId);
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProject(String projectId) async {
    try {
      print('🔵 [ProjectRepository] Deleting project: $projectId');
      await _remoteDatasource.deleteProject(projectId);
      print('✅ [ProjectRepository] Project deleted successfully');
      return const Right(null);
    } catch (e) {
      print('❌ [ProjectRepository] Error: $e');
      return Left(Failure(message: e.toString()));
    }
  }
}

