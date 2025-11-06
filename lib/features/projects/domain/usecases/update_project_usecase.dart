import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';

class UpdateProject implements UseCase<ProjectEntity, UpdateProjectParams> {
  final ProjectRepository repository;

  UpdateProject(this.repository);

  @override
  Future<Either<Failure, ProjectEntity>> call(UpdateProjectParams params) async {
    print('🔵 [UpdateProjectUsecase] Updating project: ${params.projectId}');
    print('🔍 [UpdateProjectUsecase] Custom statuses: ${params.customStatuses}');
    
    return await repository.updateProject(
      projectId: params.projectId,
      name: params.name,
      description: params.description,
      customStatuses: params.customStatuses,
    );
  }
}

class UpdateProjectParams {
  final String projectId;
  final String? name;
  final String? description;
  final List<Map<String, String>>? customStatuses;

  UpdateProjectParams({
    required this.projectId,
    this.name,
    this.description,
    this.customStatuses,
  });
}

