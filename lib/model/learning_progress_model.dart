import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'learning_progress_model.freezed.dart';

/// 学習進捗のデータモデル
@freezed
class LearningProgressModel with _$LearningProgressModel {
  const LearningProgressModel._();

  const factory LearningProgressModel({
    required String id,
    required String userId,
    required String cardId,
    required String cardSetId,
    required int level, // 習熟レベル（0〜10）
    required DateTime nextReviewDate,
    required DateTime lastReviewedAt,
    required int reviewCount,
    required int correctCount,
    required int incorrectCount,
    required int partialCount, // △の回数
    required double easeFactor, // 難易度係数（将来的な拡張用）
  }) = _LearningProgressModel;

  /// 新規作成用のファクトリコンストラクタ
  factory LearningProgressModel.create({
    required String id,
    required String userId,
    required String cardId,
    required String cardSetId,
  }) {
    final now = DateTime.now();
    return LearningProgressModel(
      id: id,
      userId: userId,
      cardId: cardId,
      cardSetId: cardSetId,
      level: 0,
      nextReviewDate: now, // 新規カードは即座に学習可能
      lastReviewedAt: now,
      reviewCount: 0,
      correctCount: 0,
      incorrectCount: 0,
      partialCount: 0,
      easeFactor: 2.5, // デフォルトの難易度係数
    );
  }

  /// Firestoreドキュメントからの変換
  factory LearningProgressModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return LearningProgressModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      cardId: data['cardId'] as String? ?? '',
      cardSetId: data['cardSetId'] as String? ?? '',
      level: data['level'] as int? ?? 0,
      nextReviewDate:
          (data['nextReviewDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReviewedAt:
          (data['lastReviewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewCount: data['reviewCount'] as int? ?? 0,
      correctCount: data['correctCount'] as int? ?? 0,
      incorrectCount: data['incorrectCount'] as int? ?? 0,
      partialCount: data['partialCount'] as int? ?? 0,
      easeFactor: (data['easeFactor'] as num?)?.toDouble() ?? 2.5,
    );
  }

  /// Firestoreへの保存用Map変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'cardId': cardId,
      'cardSetId': cardSetId,
      'level': level,
      'nextReviewDate': Timestamp.fromDate(nextReviewDate),
      'lastReviewedAt': Timestamp.fromDate(lastReviewedAt),
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'partialCount': partialCount,
      'easeFactor': easeFactor,
    };
  }

  /// 評価に基づいて次回復習日を計算し、更新された進捗を返す
  ///
  /// [isCorrect]: 完全正解（○）
  /// [isPartial]: 部分正解（△）
  /// [reviewedAt]: 復習実行日時
  ///
  /// Returns: 更新された学習進捗モデル
  LearningProgressModel calculateNextReview({
    required bool isCorrect,
    required bool isPartial,
    required DateTime reviewedAt,
  }) {
    int newLevel = level;
    Duration interval;

    if (isCorrect && !isPartial) {
      // ○（正解）→ レベルアップ
      newLevel = level + 1;
      interval = LearningProgressModel.getIntervalForLevel(newLevel);
    } else if (isPartial) {
      // △（やや正解）→ レベル維持、現在の間隔の10%で再出題
      final currentInterval = LearningProgressModel.getIntervalForLevel(level);
      interval = Duration(
        milliseconds: (currentInterval.inMilliseconds * 0.1).round(),
      );
    } else {
      // ×（不正解）→ レベル0に戻る
      newLevel = 0;
      interval = LearningProgressModel.getIntervalForLevel(0);
    }

    return copyWith(
      level: newLevel,
      nextReviewDate: reviewedAt.add(interval),
      lastReviewedAt: reviewedAt,
      reviewCount: reviewCount + 1,
      correctCount: isCorrect && !isPartial ? correctCount + 1 : correctCount,
      incorrectCount: !isCorrect ? incorrectCount + 1 : incorrectCount,
      partialCount: isPartial ? partialCount + 1 : partialCount,
    );
  }

  /// レベルに応じた復習間隔を取得（スペーシング学習アルゴリズム）
  ///
  /// [level]: 習熟レベル（0〜10+）
  ///
  /// Returns: 次回復習までの期間
  static Duration getIntervalForLevel(int level) {
    switch (level) {
      case 0:
        return const Duration(minutes: 0); // 0分後
      case 1:
        return const Duration(minutes: 1); // 1分後
      case 2:
        return const Duration(minutes: 5); // 5分後
      case 3:
        return const Duration(minutes: 15); // 15分後
      case 4:
        return const Duration(minutes: 30); // 30分後
      case 5:
        return const Duration(hours: 1); // 1時間後
      case 6:
        return const Duration(hours: 12); // 12時間後
      case 7:
        return const Duration(days: 1); // 1日後
      case 8:
        return const Duration(days: 3); // 3日後
      case 9:
        return const Duration(days: 7); // 7日後
      case 10:
        return const Duration(days: 14); // 14日後
      case 11:
        return const Duration(days: 30); // 30日後
      default:
        return const Duration(days: 60); // 60日後
    }
  }
}
