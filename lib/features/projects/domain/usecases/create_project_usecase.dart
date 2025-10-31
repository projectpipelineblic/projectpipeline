import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

class CreateProject implements UseCase<ProjectEntity, CreateProjectParams> {
  final ProjectRepository repository;

  CreateProject(this.repository);

  @override
  Future<Either<Failure, ProjectEntity>> call(CreateProjectParams params) async {
    return await repository.createProject(
      name: params.name,
      description: params.description,
      creatorUid: params.creatorUid,
      creatorName: params.creatorName,
      teamMembers: params.teamMembers,
    );
  }
}

class CreateProjectParams {
  final String name;
  final String description;
  final String creatorUid;
  final String creatorName;
  final List<Map<String, dynamic>> teamMembers;

  CreateProjectParams({
    required this.name,
    required this.description,
    required this.creatorUid,
    required this.creatorName,
    required this.teamMembers,
  });
}

