import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';

class GetOpenProjects implements UseCase<List<ProjectEntity>, GetOpenProjectsParams> {
  final ProjectRepository repository;

  GetOpenProjects(this.repository);

  @override
  Future<Either<Failure, List<ProjectEntity>>> call(GetOpenProjectsParams params) async {
    return await repository.getOpenProjects(params.userId);
  }
}

class GetOpenProjectsParams {
  final String userId;

  GetOpenProjectsParams({required this.userId});
}

