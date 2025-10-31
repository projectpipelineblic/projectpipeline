import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

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

