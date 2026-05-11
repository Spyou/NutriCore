import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/exceptions.dart';

class FirebaseDataSource {
  final FirebaseFirestore _firestore;
  FirebaseDataSource(this._firestore);

  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      throw ServerException('Failed to get document: $e');
    }
  }

  Stream<DocumentSnapshot> watchDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Future<QuerySnapshot> queryDocuments(
    String collection, {
    String? field,
    dynamic isEqualTo,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThanOrEqualTo,
    String? rangeField,
    dynamic rangeStart,
    dynamic rangeEnd,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      if (field != null && isEqualTo != null) {
        query = query.where(field, isEqualTo: isEqualTo);
      }
      if (field != null && isGreaterThanOrEqualTo != null) {
        query = query.where(
          field,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        );
      }
      if (field != null && isLessThanOrEqualTo != null) {
        query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
      }
      if (rangeField != null && rangeStart != null) {
        query = query.where(rangeField, isGreaterThanOrEqualTo: rangeStart);
      }
      if (rangeField != null && rangeEnd != null) {
        query = query.where(rangeField, isLessThan: rangeEnd);
      }
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      return await query.get();
    } catch (e) {
      throw ServerException('Failed to query documents: $e');
    }
  }

  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw ServerException('Failed to save document: $e');
    }
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw ServerException('Failed to update document: $e');
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw ServerException('Failed to delete document: $e');
    }
  }

  Future<void> batchDelete(String collection, List<String> docIds) async {
    try {
      const int batchSize = 500;
      for (var i = 0; i < docIds.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = docIds.sublist(
          i,
          i + batchSize > docIds.length ? docIds.length : i + batchSize,
        );
        for (final id in chunk) {
          batch.delete(_firestore.collection(collection).doc(id));
        }
        await batch.commit();
      }
    } catch (e) {
      throw ServerException('Failed to batch delete documents: $e');
    }
  }

  Future<void> batchDeleteMultiple(
    List<(String collection, String docId)> items,
  ) async {
    const int batchSize = 500;
    for (var i = 0; i < items.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = items.sublist(
        i,
        i + batchSize > items.length ? items.length : i + batchSize,
      );
      for (final (collection, docId) in chunk) {
        batch.delete(_firestore.collection(collection).doc(docId));
      }
      await batch.commit();
    }
  }

  String generateDocId(String collection) {
    return _firestore.collection(collection).doc().id;
  }
}
