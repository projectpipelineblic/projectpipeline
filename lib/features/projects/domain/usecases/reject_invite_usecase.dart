import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';

class RejectInvite implements UseCase<void, RejectInviteParams> {
  final ProjectRepository repository;

  RejectInvite(this.repository);

  @override
  Future<Either<Failure, void>> call(RejectInviteParams params) async {
    return await repository.rejectInvite(params.inviteId);
  }
}

class RejectInviteParams {
  final String inviteId;

  RejectInviteParams({required this.inviteId});
}

