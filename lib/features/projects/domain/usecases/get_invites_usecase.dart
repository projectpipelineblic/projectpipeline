import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

class GetInvites implements UseCase<List<ProjectInvite>, GetInvitesParams> {
  final ProjectRepository repository;

  GetInvites(this.repository);

  @override
  Future<Either<Failure, List<ProjectInvite>>> call(GetInvitesParams params) async {
    return await repository.getInvites(params.userId);
  }
}

class GetInvitesParams {
  final String userId;

  GetInvitesParams({required this.userId});
}

