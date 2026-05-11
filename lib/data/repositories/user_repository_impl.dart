import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firebase_datasource.dart';
import '../mappers/user_mapper.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseDataSource _firebaseDataSource;

  UserRepositoryImpl({required FirebaseDataSource firebaseDataSource})
    : _firebaseDataSource = firebaseDataSource;

  @override
  Future<Result<UserProfile>> getUserProfile(String uid) async {
    try {
      final doc = await _firebaseDataSource.getDocument(
        AppConfig.usersCollection,
        uid,
      );
      if (!doc.exists) {
        return Result.failure(NotFoundFailure(message: 'User not found: $uid'));
      }
      final model = UserModel.fromFirestore(doc);
      return Result.success(UserMapper.toDomain(model));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> createUserProfile(UserProfile profile) async {
    try {
      final model = UserMapper.toModel(profile);
      await _firebaseDataSource.setDocument(
        AppConfig.usersCollection,
        profile.id,
        model.toMap(),
      );
      return const Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateUserProfile(UserProfile profile) async {
    try {
      final model = UserMapper.toModel(profile);
      await _firebaseDataSource.setDocument(
        AppConfig.usersCollection,
        profile.id,
        model.toMap(),
      );
      return const Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteUserProfile(String uid) async {
    try {
      await _firebaseDataSource.deleteDocument(AppConfig.usersCollection, uid);
      return const Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateProfileImage(String uid, String localPath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final file = File(localPath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      await _firebaseDataSource.setDocument(AppConfig.usersCollection, uid, {
        'photoURL': downloadUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return const Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
