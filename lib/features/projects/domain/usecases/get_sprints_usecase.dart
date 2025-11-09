import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/sprint_repository.dart';

class GetSprints implements UseCase<List<SprintEntity>, GetSprintsParams> {
  final SprintRepository repository;

  GetSprints(this.repository);

  @override
  Future<Either<Failure, List<SprintEntity>>> call(GetSprintsParams params) async {
    return await repository.getSprints(params.projectId);
  }
}

class GetSprintsParams {
  final String projectId;

  GetSprintsParams({required this.projectId});
}

