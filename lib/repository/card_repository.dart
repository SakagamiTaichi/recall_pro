import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env_config.dart';
import '../model/card_model.dart';
import 'card_set_repository.dart';

part 'card_repository.g.dart';

/// カードのリポジトリ
/// Firestoreとの通信を担当
class CardRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  CardRepository(this._firestore, this._userId);

  /// カードコレクションの参照
  CollectionReference<Map<String, dynamic>> _cardsCollection(String cardSetId) =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('cardSets')
          .doc(cardSetId)
          .collection('cards');

  /// カードセット内の全カードを取得（リアルタイム）
  Stream<List<CardModel>> watchCards(String cardSetId) {
    return _cardsCollection(cardSetId)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CardModel.fromFirestore(doc))
              .toList();
        });
  }

  /// カードセット内の全カードを取得（1回のみ）
  Future<List<CardModel>> getCards(String cardSetId) async {
    final snapshot = await _cardsCollection(cardSetId)
        .orderBy('order', descending: false)
        .get();
    return snapshot.docs.map((doc) => CardModel.fromFirestore(doc)).toList();
  }

  /// IDでカードを取得
  Future<CardModel?> getCardById(String cardSetId, String cardId) async {
    final doc = await _cardsCollection(cardSetId).doc(cardId).get();
    if (!doc.exists) return null;
    return CardModel.fromFirestore(doc);
  }

  /// カードを作成
  Future<CardModel> createCard({
    required String cardSetId,
    required String front,
    required String back,
    required int order,
  }) async {
    final docRef = _cardsCollection(cardSetId).doc();
    final card = CardModel.create(
      id: docRef.id,
      cardSetId: cardSetId,
      front: front,
      back: back,
      order: order,
    );
    await docRef.set(card.toFirestore());
    return card;
  }

  /// カードを更新（表面・裏面）
  Future<void> updateCard({
    required String cardSetId,
    required String cardId,
    required String front,
    required String back,
  }) async {
    await _cardsCollection(cardSetId).doc(cardId).update({
      'front': front,
      'back': back,
      'updatedAt': Timestamp.now(),
    });
  }

  /// カードを削除
  Future<void> deleteCard(String cardSetId, String cardId) async {
    await _cardsCollection(cardSetId).doc(cardId).delete();
  }

  /// カードの順序を一括更新（並び替え用）
  Future<void> updateCardsOrder(
    String cardSetId,
    List<CardModel> cards,
  ) async {
    final batch = _firestore.batch();
    for (var i = 0; i < cards.length; i++) {
      batch.update(
        _cardsCollection(cardSetId).doc(cards[i].id),
        {'order': i, 'updatedAt': Timestamp.now()},
      );
    }
    await batch.commit();
  }

  /// カードセット内のカード数を取得
  Future<int> getCardCount(String cardSetId) async {
    final snapshot = await _cardsCollection(cardSetId).count().get();
    return snapshot.count ?? 0;
  }
}

/// CardRepositoryのプロバイダー
@riverpod
CardRepository cardRepository(Ref ref, String cardSetId) {
  final firestore = ref.watch(firestoreProvider);
  return CardRepository(firestore, EnvConfig.fixedUserId);
}

/// カード一覧のStreamプロバイダー
@riverpod
Stream<List<CardModel>> cardsStream(Ref ref, String cardSetId) {
  final firestore = ref.watch(firestoreProvider);
  final repository = CardRepository(firestore, EnvConfig.fixedUserId);
  return repository.watchCards(cardSetId);
}
