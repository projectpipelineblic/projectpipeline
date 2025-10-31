import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

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

