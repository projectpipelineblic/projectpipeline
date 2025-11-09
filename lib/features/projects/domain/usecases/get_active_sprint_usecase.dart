import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/sprint_repository.dart';

class GetActiveSprint implements UseCase<SprintEntity?, GetActiveSprintParams> {
  final SprintRepository repository;

  GetActiveSprint(this.repository);

  @override
  Future<Either<Failure, SprintEntity?>> call(GetActiveSprintParams params) async {
    return await repository.getActiveSprint(params.projectId);
  }
}

class GetActiveSprintParams {
  final String projectId;

  GetActiveSprintParams({required this.projectId});
}

