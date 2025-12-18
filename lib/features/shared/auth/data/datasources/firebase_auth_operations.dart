import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import 'package:sisantri/core/error/auth_error_mapper.dart';

class FirebaseAuthOperations {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthOperations({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception(AuthErrorMapper.mapFirebaseAuthError('null-user'));
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      await userDoc.reference.update({
        'deviceTokens': FieldValue.arrayUnion([
          await FirebaseMessaging.instance.getToken(),
        ]),
      });

      if (!userDoc.exists) {
        throw Exception(
          AuthErrorMapper.mapFirebaseAuthError('user-data-not-found'),
        );
      }

      return UserModel.fromJson({
        'id': credential.user!.uid,
        ...userDoc.data()!,
      });
    } on firebase_auth.FirebaseAuthException catch (e) {
      final errorMessage = AuthErrorMapper.mapFirebaseAuthError(e.code);
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = AuthErrorMapper.getErrorMessage(e);
      throw Exception(errorMessage);
    }
  }

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String nama,
    required String role,
  }) async {
    try {
      final emailError = AuthErrorMapper.validateEmailFormat(email);
      if (emailError != null) {
        throw Exception(emailError);
      }

      final passwordError = AuthErrorMapper.validatePasswordFormat(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      final namaError = AuthErrorMapper.validateNamaLengkap(nama);
      if (namaError != null) {
        throw Exception(namaError);
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception(AuthErrorMapper.mapFirebaseAuthError('null-user'));
      }

      final user = UserModel(
        id: credential.user!.uid,
        nama: nama,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      final errorMessage = AuthErrorMapper.mapFirebaseAuthError(e.code);
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = AuthErrorMapper.getErrorMessage(e);
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid != null) {
        final userDoc = _firestore.collection('users').doc(uid);
        await userDoc.update({
          'deviceTokens': FieldValue.arrayRemove([
            await FirebaseMessaging.instance.getToken(),
          ]),
        });
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      final errorMessage = AuthErrorMapper.mapFirebaseAuthError(e.code);
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = AuthErrorMapper.getErrorMessage(e);
      throw Exception(errorMessage);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception(
          AuthErrorMapper.mapFirebaseAuthError('user-data-not-found'),
        );
      }

      return UserModel.fromJson({'id': firebaseUser.uid, ...userDoc.data()!});
    } catch (e) {
      final errorMessage = AuthErrorMapper.getErrorMessage(e);
      throw Exception(errorMessage);
    }
  }
}
