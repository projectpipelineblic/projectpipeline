import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

class FindUserByEmail implements UseCase<UserInfo, FindUserByEmailParams> {
  final ProjectRepository repository;

  FindUserByEmail(this.repository);

  @override
  Future<Either<Failure, UserInfo>> call(FindUserByEmailParams params) async {
    return await repository.findUserByEmail(params.email);
  }
}

class FindUserByEmailParams {
  final String email;

  FindUserByEmailParams({required this.email});
}

