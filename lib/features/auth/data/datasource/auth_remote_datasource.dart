
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project_pipeline/features/auth/data/model/user_model.dart';
import 'package:project_pipeline/features/auth/domain/entities/user_entity.dart';

abstract class AuthRemoteDatasource {
  Future<UserEntity> signUpWithEmailAndPassword(UserEntity user);
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> getCurrentUser();
  Future<void> signOut();
  Future<UserEntity> updateUsername(String uid, String newUsername);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '288891668667-YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // Add your web client ID here
  );

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
  Future<UserEntity> signInWithGoogle() async {
    try {
      print('🔵 [Google Sign-In] Starting Google Sign-In flow...');
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🔵 [Google Sign-In] Sign-In dialog completed');

      if (googleUser == null) {
        // User canceled the sign-in
        print('⚠️ [Google Sign-In] User canceled the sign-in');
        throw Exception('google-signin-canceled: User canceled the Google sign-in');
      }

      print('🔵 [Google Sign-In] Google user obtained: ${googleUser.email}');
      print('🔵 [Google Sign-In] Obtaining authentication details...');

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔵 [Google Sign-In] Authentication details obtained');
      print('🔵 [Google Sign-In] Access Token present: ${googleAuth.accessToken != null}');
      print('🔵 [Google Sign-In] ID Token present: ${googleAuth.idToken != null}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔵 [Google Sign-In] Firebase credential created');

      // Sign in to Firebase with Google credential
      print('🔵 [Google Sign-In] Signing in to Firebase...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('✅ [Google Sign-In] Firebase sign-in successful');

      final String uid = userCredential.user!.uid;
      final String email = userCredential.user!.email!;
      print('🔵 [Google Sign-In] User UID: $uid');
      print('🔵 [Google Sign-In] User Email: $email');

      // Extract username from email (everything before @)
      final String userName = email.split('@')[0];
      print('🔵 [Google Sign-In] Extracted username: $userName');

      // Check if user exists in Firestore
      print('🔵 [Google Sign-In] Checking if user exists in Firestore...');
      final DocumentSnapshot userDoc = await _firestore.collection('Users').doc(uid).get();

      if (userDoc.exists) {
        // User exists, return existing data
        print('✅ [Google Sign-In] User exists in Firestore, returning existing data');
        final userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      } else {
        // New user, create user document
        print('🔵 [Google Sign-In] New user, creating Firestore document...');
        final UserModel newUser = UserModel(
          uid: uid,
          userName: userName,
          email: email,
          password: '', // Google sign-in users don't have a password
        );

        // Store user data in Firestore
        await _firestore.collection('Users').doc(uid).set(newUser.toJson());
        print('✅ [Google Sign-In] User document created successfully');

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ [Google Sign-In] Firebase Auth Error: ${e.code} - ${e.message}');
      print('❌ [Google Sign-In] Full error details: $e');
      throw Exception('firebase-auth-${e.code}: ${e.message}');
    } on FirebaseException catch (e) {
      print('❌ [Google Sign-In] Firestore Error: ${e.code} - ${e.message}');
      print('❌ [Google Sign-In] Full error details: $e');
      throw Exception('firestore-${e.code}: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ [Google Sign-In] Unexpected Error: $e');
      print('❌ [Google Sign-In] Stack trace: $stackTrace');
      throw Exception('google-signin-error: $e');
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      print('🔍 [Datasource] Getting current user...');
      
      // Wait for Firebase Auth to initialize by listening to the first auth state
      // This ensures we get the restored user session after page refresh
      final User? user = await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ [Datasource] Auth state check timed out');
          return null;
        },
      );
      
      print('🔍 [Datasource] Auth state user: ${user?.email ?? "null"}');
      
      if (user != null) {
        print('🔍 [Datasource] Fetching user data from Firestore...');
        final DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          print('✅ [Datasource] User data retrieved: ${userData['email']}');
          return UserModel.fromJson(userData);
        } else {
          print('❌ [Datasource] User document not found in Firestore');
          throw Exception('User data not found');
        }
      } else {
        print('❌ [Datasource] No user signed in (Firebase returned null)');
        throw Exception('No user signed in');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ [Datasource] Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } on FirebaseException catch (e) {
      print('❌ [Datasource] Firestore Error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      print('❌ [Datasource] Unexpected Error: $e');
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