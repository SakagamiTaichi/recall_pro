import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env_config.dart';
import '../model/learning_progress_model.dart';
import 'card_set_repository.dart';

part 'learning_progress_repository.g.dart';

/// 学習進捗のリポジトリ
/// Firestoreとの通信を担当
class LearningProgressRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  LearningProgressRepository(this._firestore, this._userId);

  /// 学習進捗コレクションの参照
  CollectionReference<Map<String, dynamic>> get _progressCollection =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('learningProgress');

  /// カードIDから学習進捗を取得（リアルタイム）
  Stream<LearningProgressModel?> watchProgress(String cardId) {
    return _progressCollection.doc(cardId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LearningProgressModel.fromFirestore(doc);
    });
  }

  /// カードIDから学習進捗を取得（1回のみ）
  Future<LearningProgressModel?> getProgress(String cardId) async {
    final doc = await _progressCollection.doc(cardId).get();
    if (!doc.exists) return null;
    return LearningProgressModel.fromFirestore(doc);
  }

  /// カードセット内の全学習進捗を取得
  Future<List<LearningProgressModel>> getProgressByCardSet(
    String cardSetId,
  ) async {
    final snapshot = await _progressCollection
        .where('cardSetId', isEqualTo: cardSetId)
        .get();
    return snapshot.docs
        .map((doc) => LearningProgressModel.fromFirestore(doc))
        .toList();
  }

  /// 復習が必要なカード（nextReviewDateが現在より前）を取得
  Future<List<LearningProgressModel>> getReviewDueCards(
    String cardSetId,
  ) async {
    final now = DateTime.now();
    final snapshot = await _progressCollection
        .where('cardSetId', isEqualTo: cardSetId)
        .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('nextReviewDate', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => LearningProgressModel.fromFirestore(doc))
        .toList();
  }

  /// 学習進捗を作成または更新
  Future<void> upsertProgress(LearningProgressModel progress) async {
    await _progressCollection.doc(progress.cardId).set(progress.toFirestore());
  }

  /// 学習進捗を削除
  Future<void> deleteProgress(String cardId) async {
    await _progressCollection.doc(cardId).delete();
  }

  /// カードセット内の全学習進捗を削除
  Future<void> deleteProgressByCardSet(String cardSetId) async {
    final snapshot = await _progressCollection
        .where('cardSetId', isEqualTo: cardSetId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// LearningProgressRepositoryのプロバイダー
@riverpod
LearningProgressRepository learningProgressRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return LearningProgressRepository(firestore, EnvConfig.fixedUserId);
}

/// 学習進捗のStreamプロバイダー
@riverpod
Stream<LearningProgressModel?> learningProgressStream(Ref ref, String cardId) {
  final repository = ref.watch(learningProgressRepositoryProvider);
  return repository.watchProgress(cardId);
}
