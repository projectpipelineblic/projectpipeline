
import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/task_repository.dart';

class UpdateTaskStatusParams {
  UpdateTaskStatusParams({required this.projectId, required this.taskId, required this.status});
  final String projectId;
  final String taskId;
  final TaskStatus status;
}

class UpdateTaskStatus extends UseCase<void, UpdateTaskStatusParams> {
  UpdateTaskStatus(this.repository);

  final TaskRepository repository;

  @override
  Future<Either<Failure, void>> call(UpdateTaskStatusParams params) {
    return repository.updateTaskStatus(
      projectId: params.projectId,
      taskId: params.taskId,
      status: params.status,
    );
  }
}


