import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';

abstract class SprintRepository {
  Future<Either<Failure, List<SprintEntity>>> getSprints(String projectId);
  Stream<Either<Failure, List<SprintEntity>>> streamSprints(String projectId);
  Future<Either<Failure, SprintEntity>> getSprint(String projectId, String sprintId);
  Future<Either<Failure, String>> createSprint(SprintEntity sprint);
  Future<Either<Failure, Unit>> updateSprint(SprintEntity sprint);
  Future<Either<Failure, Unit>> deleteSprint(String projectId, String sprintId);
  Future<Either<Failure, Unit>> startSprint(String projectId, String sprintId);
  Future<Either<Failure, Unit>> completeSprint(String projectId, String sprintId);
  Future<Either<Failure, SprintEntity?>> getActiveSprint(String projectId);
}

