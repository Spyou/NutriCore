import '../entities/user_profile.dart';
import '../../core/utils/result.dart';

abstract class UserRepository {
  Future<Result<UserProfile>> getUserProfile(String uid);
  Future<Result<void>> createUserProfile(UserProfile profile);
  Future<Result<void>> updateUserProfile(UserProfile profile);
  Future<Result<void>> deleteUserProfile(String uid);
  Future<Result<void>> updateProfileImage(String uid, String localPath);
}
