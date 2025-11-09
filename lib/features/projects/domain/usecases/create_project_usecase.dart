import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';

class CreateProject implements UseCase<ProjectEntity, CreateProjectParams> {
  final ProjectRepository repository;

  CreateProject(this.repository);

  @override
  Future<Either<Failure, ProjectEntity>> call(CreateProjectParams params) async {
    print('🔵 [CreateProjectUsecase] Creating project: ${params.name}');
    print('🔍 [CreateProjectUsecase] Custom statuses: ${params.customStatuses}');
    print('🔍 [CreateProjectUsecase] Project type: ${params.projectType}');
    print('🔍 [CreateProjectUsecase] Workflow type: ${params.workflowType}');
    print('🔍 [CreateProjectUsecase] Project key: ${params.projectKey}');
    
    return await repository.createProject(
      name: params.name,
      description: params.description,
      creatorUid: params.creatorUid,
      creatorName: params.creatorName,
      teamMembers: params.teamMembers,
      customStatuses: params.customStatuses,
      projectType: params.projectType,
      workflowType: params.workflowType,
      projectKey: params.projectKey,
      additionalFeatures: params.additionalFeatures,
    );
  }
}

class CreateProjectParams {
  final String name;
  final String description;
  final String creatorUid;
  final String creatorName;
  final List<Map<String, dynamic>> teamMembers;
  final List<Map<String, String>>? customStatuses;
  final String? projectType;
  final String? workflowType;
  final String? projectKey;
  final Map<String, bool>? additionalFeatures;

  CreateProjectParams({
    required this.name,
    required this.description,
    required this.creatorUid,
    required this.creatorName,
    required this.teamMembers,
    this.customStatuses,
    this.projectType,
    this.workflowType,
    this.projectKey,
    this.additionalFeatures,
  });
}

