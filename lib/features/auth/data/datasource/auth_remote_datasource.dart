
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/features/auth/data/model/user_model.dart';
import 'package:task_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRemoteDatasource {
  Future<UserEntity> signUpWithEmailAndPassword(UserEntity user);
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> getCurrentUser();
  Future<void> signOut();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserEntity> signUpWithEmailAndPassword(UserEntity user) async {
    try {
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      final String uid = userCredential.user!.uid;

      // Create user model with uid
      final UserModel userModel = UserModel(
        uid: uid,
        userName: user.userName,
        email: user.email,
        password: user.password,
      );

      // Store user data in Firestore
      await _firestore.collection('Users').doc(uid).set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('Unexpected Error: $e');
    }
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // Get user data from Firestore
      final DocumentSnapshot userDoc = await _firestore.collection('Users').doc(uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      } else {
        throw Exception('User data not found');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('Unexpected Error: $e');
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          return UserModel.fromJson(userData);
        } else {
          throw Exception('User data not found');
        }
      } else {
        throw Exception('No user signed in');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('Unexpected Error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Sign out error: $e');
    }
  }
}