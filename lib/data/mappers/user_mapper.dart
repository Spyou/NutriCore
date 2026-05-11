import '../models/user_model.dart';
import '../../domain/entities/user_profile.dart';

class UserMapper {
  static UserProfile toDomain(UserModel model) => model.toDomain();

  static UserModel toModel(UserProfile profile) =>
      UserModel.fromDomain(profile);
}
