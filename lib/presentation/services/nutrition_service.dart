import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/nutrition_entry_model.dart';

class NutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get nutritionCollection => 'nutrition_entries';

  Future<void> saveNutritionEntry(NutritionEntryModel entry) async {
    try {
      await _firestore
          .collection(nutritionCollection)
          .doc(entry.id)
          .set(entry.toMap());
    } catch (e) {
      throw Exception('Error saving nutrition entry: $e');
    }
  }

  Future<NutritionEntryModel?> getNutritionEntry(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = _formatDate(date);
      final query = await _firestore
          .collection(nutritionCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return NutritionEntryModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting nutrition entry: $e');
    }
  }

  Future<List<NutritionEntryModel>> getNutritionHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final query = await _firestore
          .collection(nutritionCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => NutritionEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting nutrition history: $e');
    }
  }

  Future<void> updateNutritionEntry(NutritionEntryModel entry) async {
    try {
      await _firestore
          .collection(nutritionCollection)
          .doc(entry.id)
          .update(entry.toMap());
    } catch (e) {
      throw Exception('Error updating nutrition entry: $e');
    }
  }

  Future<void> deleteNutritionEntry(String entryId) async {
    try {
      await _firestore.collection(nutritionCollection).doc(entryId).delete();
    } catch (e) {
      throw Exception('Error deleting nutrition entry: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String generateEntryId(String userId, DateTime date) {
    return '${userId}_${_formatDate(date)}';
  }
}
