import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../model/card_model.dart';
import '../../../repository/card_repository.dart';
import '../../../repository/learning_progress_repository.dart';
import '../../../repository/study_session_repository.dart';

part 'study_view_model.g.dart';

/// 評価の種類
enum EvaluationType {
  correct, // ○（正解）
  partial, // △（やや正解）
  incorrect, // ×（不正解）
}

/// 学習セッションの統計
class StudyStats {
  final int totalCards;
  final int currentIndex;
  final int correctCount;
  final int partialCount;
  final int incorrectCount;
  final DateTime startedAt;

  const StudyStats({
    required this.totalCards,
    required this.currentIndex,
    required this.correctCount,
    required this.partialCount,
    required this.incorrectCount,
    required this.startedAt,
  });

  StudyStats copyWith({
    int? totalCards,
    int? currentIndex,
    int? correctCount,
    int? partialCount,
    int? incorrectCount,
    DateTime? startedAt,
  }) {
    return StudyStats(
      totalCards: totalCards ?? this.totalCards,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      partialCount: partialCount ?? this.partialCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  int get cardsStudied => correctCount + partialCount + incorrectCount;

  double get progressRate {
    if (totalCards == 0) return 0.0;
    return currentIndex / totalCards;
  }

  double get accuracyRate {
    if (cardsStudied == 0) return 0.0;
    return (correctCount / cardsStudied * 100);
  }
}

/// 学習セッションの初期化データ
class StudySessionData {
  final List<CardModel> cards;
  final String sessionId;

  const StudySessionData({
    required this.cards,
    required this.sessionId,
  });
}

/// 学習画面のViewModel（ビジネスロジックのみ）
@riverpod
class StudyViewModel extends _$StudyViewModel {
  @override
  Future<StudySessionData> build(String cardSetId) async {
    // カードを取得
    final cardRepository = ref.read(cardRepositoryProvider(cardSetId));
    final cards = await cardRepository.getCards(cardSetId);

    // セッションを作成
    final sessionRepository = ref.read(studySessionRepositoryProvider);
    final session = await sessionRepository.createSession(
      cardSetId: cardSetId,
    );

    return StudySessionData(
      cards: cards,
      sessionId: session.id,
    );
  }

  /// 学習進捗を更新
  Future<void> updateProgress({
    required String cardId,
    required String cardSetId,
    required EvaluationType evaluation,
  }) async {
    final progressRepository = ref.read(learningProgressRepositoryProvider);
    await progressRepository.updateProgressAfterReview(
      cardId: cardId,
      cardSetId: cardSetId,
      isCorrect: evaluation == EvaluationType.correct,
      isPartial: evaluation == EvaluationType.partial,
    );
  }

  /// セッションを完了
  Future<void> completeSession({
    required String sessionId,
    required StudyStats stats,
  }) async {
    try {
      final sessionRepository = ref.read(studySessionRepositoryProvider);
      await sessionRepository.endSession(
        sessionId: sessionId,
        cardsStudied: stats.cardsStudied,
        correctCount: stats.correctCount,
        incorrectCount: stats.incorrectCount,
        partialCount: stats.partialCount,
      );
    } catch (e) {
      // エラーをログに記録するが、学習完了は妨げない
      // ignore: avoid_print
      print('セッション完了時のエラー: $e');
    }
  }
}
