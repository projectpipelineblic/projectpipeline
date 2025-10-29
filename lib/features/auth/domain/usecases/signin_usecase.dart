import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/auth/domain/entities/user_entity.dart';
import 'package:task_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailAndPassword implements UseCase<UserEntity, SignInParams> {
  final AuthRepository _authRepository;

  SignInWithEmailAndPassword({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    return await _authRepository.signInWithEmailAndPassword(
      params.email,
      params.password,
    );
  }
}

class SignInParams {
  final String email;
  final String password;

  SignInParams({
    required this.email,
    required this.password,
  });
}
