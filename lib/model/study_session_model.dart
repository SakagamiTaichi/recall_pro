import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_session_model.freezed.dart';

/// 学習セッションのデータモデル
@freezed
class StudySessionModel with _$StudySessionModel {
  const StudySessionModel._();

  const factory StudySessionModel({
    required String id,
    required String userId,
    required String cardSetId,
    required DateTime startedAt,
    DateTime? endedAt,
    required int cardsStudied,
    required int correctCount,
    required int incorrectCount,
    required int partialCount,
  }) = _StudySessionModel;

  /// 新規作成用のファクトリコンストラクタ
  factory StudySessionModel.create({
    required String id,
    required String userId,
    required String cardSetId,
  }) {
    final now = DateTime.now();
    return StudySessionModel(
      id: id,
      userId: userId,
      cardSetId: cardSetId,
      startedAt: now,
      endedAt: null,
      cardsStudied: 0,
      correctCount: 0,
      incorrectCount: 0,
      partialCount: 0,
    );
  }

  /// Firestoreドキュメントからの変換
  factory StudySessionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return StudySessionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      cardSetId: data['cardSetId'] as String? ?? '',
      startedAt:
          (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      cardsStudied: data['cardsStudied'] as int? ?? 0,
      correctCount: data['correctCount'] as int? ?? 0,
      incorrectCount: data['incorrectCount'] as int? ?? 0,
      partialCount: data['partialCount'] as int? ?? 0,
    );
  }

  /// Firestoreへの保存用Map変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'cardSetId': cardSetId,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'cardsStudied': cardsStudied,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'partialCount': partialCount,
    };
  }

  /// 学習時間を計算（分単位）
  int? get durationInMinutes {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt).inMinutes;
  }

  /// 正答率を計算（0〜100）
  double get accuracyRate {
    if (cardsStudied == 0) return 0.0;
    return (correctCount / cardsStudied * 100);
  }
}
