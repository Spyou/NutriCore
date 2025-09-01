import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get usersCollection => 'users';

  Future<void> createUserData(UserModel user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Error creating user data: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user data: $e');
    }
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Error updating user data: $e');
    }
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Error deleting user data: $e');
    }
  }
}
