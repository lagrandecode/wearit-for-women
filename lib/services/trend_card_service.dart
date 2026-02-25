import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trend_card.dart';

class TrendCardService {
  static const String _collection = 'trend_cards';

  /// Get all trend cards ordered by order field
  Stream<List<TrendCard>> getTrendCards() {
    return FirebaseFirestore.instance
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrendCard.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Add a new trend card
  Future<String> addTrendCard({
    required String mediaUrl,
    required String mediaType,
    required String prompt,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    
    // Get the highest order number
    final existingCards = await firestore
        .collection(_collection)
        .orderBy('order', descending: true)
        .limit(1)
        .get();
    
    final nextOrder = existingCards.docs.isEmpty
        ? 0
        : (existingCards.docs.first.data()['order'] as int) + 1;

    final docRef = await firestore.collection(_collection).add({
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'prompt': prompt,
      'order': nextOrder,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return docRef.id;
  }

  /// Update a trend card
  Future<void> updateTrendCard(TrendCard card) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection(_collection).doc(card.id).update({
      'mediaUrl': card.mediaUrl,
      'mediaType': card.mediaType,
      'prompt': card.prompt,
      'order': card.order,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a trend card
  Future<void> deleteTrendCard(String cardId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection(_collection).doc(cardId).delete();
  }
}
