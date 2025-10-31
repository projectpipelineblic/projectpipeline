import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/features/projects/data/datasources/task_remote_data_source.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';
import 'package:task_app/features/projects/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({required this.remote});

  final TaskRemoteDataSource remote;

  @override
  Stream<List<TaskEntity>> streamTasks({required String projectId}) {
    return remote.streamTasks(projectId: projectId);
  }

  @override
  Future<Either<Failure, void>> createTask({required TaskEntity task}) async {
    try {
      await remote.createTask(task: task);
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: 'Failed to create task'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTaskStatus({required String projectId, required String taskId, required TaskStatus status}) async {
    try {
      await remote.updateTaskStatus(projectId: projectId, taskId: taskId, status: status);
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: 'Failed to update status'));
    }
  }
}


