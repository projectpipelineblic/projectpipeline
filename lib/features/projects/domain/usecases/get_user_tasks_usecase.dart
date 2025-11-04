import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';
import 'package:task_app/features/projects/domain/repositories/task_repository.dart';

class GetUserTasks implements UseCase<List<TaskEntity>, GetUserTasksParams> {
  final TaskRepository repository;

  GetUserTasks(this.repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call(GetUserTasksParams params) async {
    return await repository.getUserTasks(userId: params.userId);
  }
}

class GetUserTasksParams {
  final String userId;

  GetUserTasksParams({required this.userId});
}

