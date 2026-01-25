import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_service.dart';
import '../model/card_set_model.dart';

part 'card_set_repository.g.dart';

/// カードセットのリポジトリ
/// Firestoreとの通信を担当
class CardSetRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  CardSetRepository(this._firestore, this._userId);

  /// カードセットコレクションの参照
  CollectionReference<Map<String, dynamic>> get _cardSetsCollection =>
      _firestore.collection('users').doc(_userId).collection('cardSets');

  /// 全カードセットを取得（リアルタイム）
  Stream<List<CardSetModel>> watchCardSets() {
    return _cardSetsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CardSetModel.fromFirestore(doc))
              .toList();
        });
  }

  /// 全カードセットを取得（1回のみ）
  Future<List<CardSetModel>> getCardSets() async {
    final snapshot = await _cardSetsCollection
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => CardSetModel.fromFirestore(doc)).toList();
  }

  /// IDでカードセットを取得
  Future<CardSetModel?> getCardSetById(String id) async {
    final doc = await _cardSetsCollection.doc(id).get();
    if (!doc.exists) return null;
    return CardSetModel.fromFirestore(doc);
  }

  /// カードセットを作成
  Future<CardSetModel> createCardSet({
    required String title,
    String description = '',
  }) async {
    final docRef = _cardSetsCollection.doc();
    final cardSet = CardSetModel.create(
      id: docRef.id,
      title: title,
      description: description,
      userId: _userId,
    );
    await docRef.set(cardSet.toFirestore());
    return cardSet;
  }

  /// カードセットを更新
  Future<void> updateCardSet(CardSetModel cardSet) async {
    final updatedCardSet = cardSet.copyWith(updatedAt: DateTime.now());
    await _cardSetsCollection
        .doc(cardSet.id)
        .update(updatedCardSet.toFirestore());
  }

  /// カードセットのタイトルと説明を更新
  Future<void> updateCardSetInfo({
    required String id,
    required String title,
    required String description,
  }) async {
    await _cardSetsCollection.doc(id).update({
      'title': title,
      'description': description,
      'updatedAt': Timestamp.now(),
    });
  }

  /// カードセットを削除
  Future<void> deleteCardSet(String id) async {
    // カードセット内のカードも削除（サブコレクション）
    final cardsSnapshot = await _cardSetsCollection
        .doc(id)
        .collection('cards')
        .get();
    final batch = _firestore.batch();
    for (final doc in cardsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_cardSetsCollection.doc(id));
    await batch.commit();
  }

  /// カードセットのカード数を更新
  Future<void> updateCardCount(String id, int count) async {
    await _cardSetsCollection.doc(id).update({
      'cardCount': count,
      'updatedAt': Timestamp.now(),
    });
  }
}

/// Firestoreインスタンスのプロバイダー
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// CardSetRepositoryのプロバイダー
@riverpod
CardSetRepository? cardSetRepository(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final firestore = ref.watch(firestoreProvider);
  return CardSetRepository(firestore, user.uid);
}

/// カードセット一覧のStreamプロバイダー
@riverpod
Stream<List<CardSetModel>> cardSetsStream(Ref ref) {
  final repository = ref.watch(cardSetRepositoryProvider);
  if (repository == null) {
    return Stream.value([]);
  }
  return repository.watchCardSets();
}
