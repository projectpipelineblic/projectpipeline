import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/repositories/sprint_repository.dart';

class StartSprint implements UseCase<Unit, StartSprintParams> {
  final SprintRepository repository;

  StartSprint(this.repository);

  @override
  Future<Either<Failure, Unit>> call(StartSprintParams params) async {
    return await repository.startSprint(params.projectId, params.sprintId);
  }
}

class StartSprintParams {
  final String projectId;
  final String sprintId;

  StartSprintParams({
    required this.projectId,
    required this.sprintId,
  });
}

