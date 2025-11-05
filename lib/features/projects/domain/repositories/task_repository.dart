
import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';

abstract class TaskRepository {
  Stream<List<TaskEntity>> streamTasks({required String projectId});
  Future<Either<Failure, List<TaskEntity>>> getUserTasks({required String userId});
  Future<Either<Failure, void>> createTask({required TaskEntity task});
  Future<Either<Failure, void>> updateTaskStatus({
    required String projectId,
    required String taskId,
    required TaskStatus status,
  });
}


