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
}
