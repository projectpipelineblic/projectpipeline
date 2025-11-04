import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/auth/domain/entities/user_entity.dart';
import 'package:task_app/features/auth/domain/repositories/auth_repository.dart';

class UpdateUsernameUsecase implements UseCase<UserEntity, UpdateUsernameParams> {
  final AuthRepository _authRepository;

  UpdateUsernameUsecase(this._authRepository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateUsernameParams params) async {
    return await _authRepository.updateUsername(params.uid, params.newUsername);
  }
}

class UpdateUsernameParams {
  final String uid;
  final String newUsername;

  UpdateUsernameParams({
    required this.uid,
    required this.newUsername,
  });
}

