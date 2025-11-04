
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/features/auth/data/model/user_model.dart';
import 'package:task_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRemoteDatasource {
  Future<UserEntity> signUpWithEmailAndPassword(UserEntity user);
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> getCurrentUser();
  Future<void> signOut();
  Future<UserEntity> updateUsername(String uid, String newUsername);
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

  @override
  Future<UserEntity> updateUsername(String uid, String newUsername) async {
    try {
      // Use a batch to update all documents atomically
      final WriteBatch batch = _firestore.batch();

      // 1. Update username in Users collection
      final userRef = _firestore.collection('Users').doc(uid);
      batch.update(userRef, {'userName': newUsername});

      // 2. Update username in all Projects where user is creator
      final creatorProjects = await _firestore
          .collection('Projects')
          .where('creatorUid', isEqualTo: uid)
          .get();
      
      for (var doc in creatorProjects.docs) {
        batch.update(doc.reference, {'creatorName': newUsername});
      }

      // 3. Update username in all Projects where user is a member
      // Query all projects and filter by member uid
      final allProjects = await _firestore.collection('Projects').get();
      
      for (var projectDoc in allProjects.docs) {
        final projectData = projectDoc.data();
        final members = List<Map<String, dynamic>>.from(projectData['members'] ?? []);
        
        // Check if user is a member of this project
        final isMember = members.any((member) => member['uid'] == uid);
        
        if (isMember) {
          // Update the member's name in the members array
          final updatedMembers = members.map((member) {
            if (member['uid'] == uid) {
              return {...member, 'name': newUsername};
            }
            return member;
          }).toList();
          
          batch.update(projectDoc.reference, {'members': updatedMembers});
        }
      }

      // 4. Update assigneeName in all Tasks where user is assignee
      // Since we already have all projects, iterate through each project's tasks
      for (var projectDoc in allProjects.docs) {
        final tasksSnapshot = await _firestore
            .collection('Projects')
            .doc(projectDoc.id)
            .collection('tasks')
            .where('assigneeId', isEqualTo: uid)
            .get();
        
        for (var taskDoc in tasksSnapshot.docs) {
          batch.update(taskDoc.reference, {'assigneeName': newUsername});
        }
      }

      // 5. Update creatorName in all pending Invites where user is creator
      final creatorInvites = await _firestore
          .collection('Invites')
          .where('creatorUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      
      for (var inviteDoc in creatorInvites.docs) {
        batch.update(inviteDoc.reference, {'creatorName': newUsername});
      }

      // Commit all updates at once
      await batch.commit();

      // Get updated user data
      final DocumentSnapshot userDoc = await _firestore.collection('Users').doc(uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      } else {
        throw Exception('User data not found');
      }
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('Unexpected Error: $e');
    }
  }
}