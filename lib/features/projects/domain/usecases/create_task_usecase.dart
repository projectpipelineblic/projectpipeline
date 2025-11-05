import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/task_repository.dart';

class CreateTask extends UseCase<void, TaskEntity> {
  CreateTask(this.repository);

  final TaskRepository repository;

  @override
  Future<Either<Failure, void>> call(TaskEntity params) {
    return repository.createTask(task: params);
  }
}


