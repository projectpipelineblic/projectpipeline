import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';

class AcceptInvite implements UseCase<void, AcceptInviteParams> {
  final ProjectRepository repository;

  AcceptInvite(this.repository);

  @override
  Future<Either<Failure, void>> call(AcceptInviteParams params) async {
    return await repository.acceptInvite(params.inviteId);
  }
}

class AcceptInviteParams {
  final String inviteId;

  AcceptInviteParams({required this.inviteId});
}

