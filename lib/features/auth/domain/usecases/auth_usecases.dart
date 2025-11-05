import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/auth/domain/entities/user_entity.dart';
import 'package:project_pipeline/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser implements UseCase<UserEntity, NoParams> {
  final AuthRepository _authRepository;

  GetCurrentUser({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await _authRepository.getCurrentUser();
  }
}

class SignOut implements UseCase<void, NoParams> {
  final AuthRepository _authRepository;

  SignOut({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _authRepository.signOut();
  }
}
