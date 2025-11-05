import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';

class GetProjects implements UseCase<List<ProjectEntity>, GetProjectsParams> {
  final ProjectRepository repository;

  GetProjects(this.repository);

  @override
  Future<Either<Failure, List<ProjectEntity>>> call(GetProjectsParams params) async {
    return await repository.getProjects(params.userId);
  }
}

class GetProjectsParams {
  final String userId;

  GetProjectsParams({required this.userId});
}

