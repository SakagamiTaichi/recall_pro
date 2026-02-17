import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/env_config.dart';
import '../../../model/ai_judgment_model.dart';
import '../../../model/card_model.dart';
import '../../../model/learning_progress_model.dart';
import '../../../repository/ai_judgment_repository.dart';
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
    final cardRepository = ref.read(cardRepositoryProvider(cardSetId));
    final progressRepository = ref.read(learningProgressRepositoryProvider);

    // すべてのカードを取得
    final allCards = await cardRepository.getCards(cardSetId);

    // カードセットの学習進捗を取得
    final progressList =
        await progressRepository.getProgressByCardSet(cardSetId);

    // 進捗をMapに変換（cardId -> progress）
    final progressMap = {
      for (var progress in progressList) progress.cardId: progress
    };

    // 復習が必要なカードをフィルタリング
    final now = DateTime.now();
    final cardsToStudy = allCards.where((card) {
      final progress = progressMap[card.id];

      // 進捗がない（新規カード）→ 学習対象
      if (progress == null) return true;

      // 復習期日が来ている → 学習対象
      return progress.nextReviewDate.isBefore(now) ||
          progress.nextReviewDate.isAtSameMomentAs(now);
    }).toList()
      ..shuffle();

    // セッションを作成
    final sessionRepository = ref.read(studySessionRepositoryProvider);
    final session = await sessionRepository.createSession(
      cardSetId: cardSetId,
    );

    return StudySessionData(
      cards: cardsToStudy,
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
    final progress = await progressRepository.getProgress(cardId);
    final now = DateTime.now();

    // 既存の進捗を取得、または新規作成
    final currentProgress = progress ??
        LearningProgressModel.create(
          id: cardId,
          userId: EnvConfig.fixedUserId,
          cardId: cardId,
          cardSetId: cardSetId,
        );

    // ドメインモデルのメソッドで次回復習日を計算
    final updatedProgress = currentProgress.calculateNextReview(
      isCorrect: evaluation == EvaluationType.correct,
      isPartial: evaluation == EvaluationType.partial,
      reviewedAt: now,
    );

    // Repositoryで永続化
    await progressRepository.upsertProgress(updatedProgress);
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

  /// AI判定を実行
  Future<AiJudgmentModel> requestAiJudgment({
    required String question,
    required String modelAnswer,
    required String userAnswer,
  }) async {
    final repository = ref.read(aiJudgmentRepositoryProvider);

    return await repository.judgeAnswer(
      question: question,
      modelAnswer: modelAnswer,
      userAnswer: userAnswer,
    );
  }
}
