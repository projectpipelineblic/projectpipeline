import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/features/projects/data/datasources/sprint_remote_datasource.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/sprint_repository.dart';

class SprintRepositoryImpl implements SprintRepository {
  final SprintRemoteDataSource remoteDataSource;

  SprintRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SprintEntity>>> getSprints(String projectId) async {
    try {
      final sprints = await remoteDataSource.getSprints(projectId);
      return Right(sprints);
    } catch (e) {
      return Left(Failure(message: 'Failed to fetch sprints: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<SprintEntity>>> streamSprints(String projectId) {
    try {
      return remoteDataSource.streamSprints(projectId).map((sprints) => Right(sprints));
    } catch (e) {
      return Stream.value(Left(Failure(message: 'Failed to stream sprints: ${e.toString()}')));
    }
  }

  @override
  Future<Either<Failure, SprintEntity>> getSprint(String projectId, String sprintId) async {
    try {
      final sprint = await remoteDataSource.getSprint(projectId, sprintId);
      return Right(sprint);
    } catch (e) {
      return Left(Failure(message: 'Failed to fetch sprint: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> createSprint(SprintEntity sprint) async {
    try {
      final sprintId = await remoteDataSource.createSprint(sprint);
      return Right(sprintId);
    } catch (e) {
      return Left(Failure(message: 'Failed to create sprint: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateSprint(SprintEntity sprint) async {
    try {
      await remoteDataSource.updateSprint(sprint);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: 'Failed to update sprint: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSprint(String projectId, String sprintId) async {
    try {
      await remoteDataSource.deleteSprint(projectId, sprintId);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: 'Failed to delete sprint: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> startSprint(String projectId, String sprintId) async {
    try {
      await remoteDataSource.startSprint(projectId, sprintId);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: 'Failed to start sprint: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeSprint(String projectId, String sprintId) async {
    try {
      await remoteDataSource.completeSprint(projectId, sprintId);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: 'Failed to complete sprint: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SprintEntity?>> getActiveSprint(String projectId) async {
    try {
      final sprint = await remoteDataSource.getActiveSprint(projectId);
      return Right(sprint);
    } catch (e) {
      return Left(Failure(message: 'Failed to fetch active sprint: ${e.toString()}'));
    }
  }
}

