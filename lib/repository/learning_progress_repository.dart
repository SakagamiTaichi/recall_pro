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

  /// 学習進捗を更新（評価に基づいて次回復習日を計算）
  Future<void> updateProgressAfterReview({
    required String cardId,
    required String cardSetId,
    required bool isCorrect,
    required bool isPartial,
  }) async {
    final progress = await getProgress(cardId);
    final now = DateTime.now();

    if (progress == null) {
      // 新規学習進捗を作成
      final newProgress = LearningProgressModel.create(
        id: cardId,
        userId: _userId,
        cardId: cardId,
        cardSetId: cardSetId,
      );

      final updatedProgress = _calculateNextReview(
        progress: newProgress,
        isCorrect: isCorrect,
        isPartial: isPartial,
        reviewedAt: now,
      );

      await upsertProgress(updatedProgress);
    } else {
      // 既存の学習進捗を更新
      final updatedProgress = _calculateNextReview(
        progress: progress,
        isCorrect: isCorrect,
        isPartial: isPartial,
        reviewedAt: now,
      );

      await upsertProgress(updatedProgress);
    }
  }

  /// 次回復習日を計算
  LearningProgressModel _calculateNextReview({
    required LearningProgressModel progress,
    required bool isCorrect,
    required bool isPartial,
    required DateTime reviewedAt,
  }) {
    int newLevel = progress.level;
    Duration interval;

    if (isCorrect && !isPartial) {
      // ○（正解）
      newLevel = progress.level + 1;
      interval = _getIntervalForLevel(newLevel);
    } else if (isPartial) {
      // △（やや正解）: 現在の間隔の50%で再出題、レベルは維持
      final currentInterval = _getIntervalForLevel(progress.level);
      interval = Duration(
        milliseconds: (currentInterval.inMilliseconds * 0.5).round(),
      );
    } else {
      // ×（不正解）: レベル0に戻る
      newLevel = 0;
      interval = _getIntervalForLevel(0);
    }

    return progress.copyWith(
      level: newLevel,
      nextReviewDate: reviewedAt.add(interval),
      lastReviewedAt: reviewedAt,
      reviewCount: progress.reviewCount + 1,
      correctCount: isCorrect && !isPartial
          ? progress.correctCount + 1
          : progress.correctCount,
      incorrectCount:
          !isCorrect ? progress.incorrectCount + 1 : progress.incorrectCount,
      partialCount:
          isPartial ? progress.partialCount + 1 : progress.partialCount,
    );
  }

  /// レベルに応じた復習間隔を取得
  Duration _getIntervalForLevel(int level) {
    switch (level) {
      case 0:
        return const Duration(minutes: 1); // 1分後
      case 1:
        return const Duration(minutes: 10); // 10分後
      case 2:
        return const Duration(hours: 1); // 1時間後
      case 3:
        return const Duration(hours: 12); // 12時間後
      case 4:
        return const Duration(days: 1); // 1日後
      case 5:
        return const Duration(days: 3); // 3日後
      case 6:
        return const Duration(days: 7); // 7日後
      case 7:
        return const Duration(days: 14); // 14日後
      case 8:
        return const Duration(days: 30); // 30日後
      default:
        return const Duration(days: 60); // 60日後
    }
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
Stream<LearningProgressModel?> learningProgressStream(
  Ref ref,
  String cardId,
) {
  final repository = ref.watch(learningProgressRepositoryProvider);
  return repository.watchProgress(cardId);
}
