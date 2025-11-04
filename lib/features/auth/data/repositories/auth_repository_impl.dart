import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:task_app/features/auth/data/model/user_model.dart';
import 'package:task_app/features/auth/domain/entities/user_entity.dart';
import 'package:task_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl({required AuthRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword(UserEntity user) async {
    try {
      final UserEntity userEntity = await _remoteDatasource.signUpWithEmailAndPassword(user);
      return Right(userEntity);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserEntity userEntity = await _remoteDatasource.signInWithEmailAndPassword(email, password);
      return Right(userEntity);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final UserEntity userEntity = await _remoteDatasource.getCurrentUser();
      return Right(userEntity);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDatasource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUsername(String uid, String newUsername) async {
    try {
      final UserEntity userEntity = await _remoteDatasource.updateUsername(uid, newUsername);
      return Right(userEntity);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
