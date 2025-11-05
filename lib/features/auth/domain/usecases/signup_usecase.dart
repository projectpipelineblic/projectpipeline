import 'package:fpdart/fpdart.dart';
import 'package:project_pipeline/core/error/failure.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/features/auth/data/model/user_model.dart';
import 'package:project_pipeline/features/auth/domain/entities/user_entity.dart';
import 'package:project_pipeline/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmailAndPassword implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository _authRepository;

  SignUpWithEmailAndPassword({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    final UserEntity user = UserModel(
      userName: params.userName,
      email: params.email,
      password: params.password,
    );

    return await _authRepository.signUpWithEmailAndPassword(user);
  }
}

class SignUpParams {
  final String userName;
  final String email;
  final String password;

  SignUpParams({
    required this.userName,
    required this.email,
    required this.password,
  });
}
