import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/auth/domain/entities/user_entity.dart';
import 'package:task_app/features/auth/domain/repositories/auth_repository.dart';

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
