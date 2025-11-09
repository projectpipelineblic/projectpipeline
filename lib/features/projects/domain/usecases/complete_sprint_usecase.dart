import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/repositories/sprint_repository.dart';

class CompleteSprint implements UseCase<Unit, CompleteSprintParams> {
  final SprintRepository repository;

  CompleteSprint(this.repository);

  @override
  Future<Either<Failure, Unit>> call(CompleteSprintParams params) async {
    return await repository.completeSprint(params.projectId, params.sprintId);
  }
}

class CompleteSprintParams {
  final String projectId;
  final String sprintId;

  CompleteSprintParams({
    required this.projectId,
    required this.sprintId,
  });
}

