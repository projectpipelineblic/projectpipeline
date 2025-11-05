import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/task_repository.dart';

class GetAllUserTasks implements UseCase<List<TaskEntity>, GetAllUserTasksParams> {
  final TaskRepository repository;

  GetAllUserTasks(this.repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call(GetAllUserTasksParams params) async {
    return await repository.getUserTasks(userId: params.userId);
  }
}

class GetAllUserTasksParams {
  final String userId;

  GetAllUserTasksParams({required this.userId});
}

