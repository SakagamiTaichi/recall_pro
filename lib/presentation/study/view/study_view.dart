import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/card_model.dart';
import '../view_model/study_view_model.dart';

/// 学習画面の状態
enum StudyViewState {
  question, // 問題表示中
  answer, // 解答表示中
  completed, // 学習完了
}

/// 学習画面
class StudyView extends HookConsumerWidget {
  final String cardSetId;
  final String cardSetTitle;

  const StudyView({
    super.key,
    required this.cardSetId,
    required this.cardSetTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionDataAsync = ref.watch(studyViewModelProvider(cardSetId));

    return sessionDataAsync.when(
      data: (sessionData) {
        if (sessionData.cards.isEmpty) {
          return _EmptyView(
            cardSetTitle: cardSetTitle,
          );
        }
        return _StudySessionView(
          key: ValueKey(sessionData.sessionId),
          cardSetId: cardSetId,
          cardSetTitle: cardSetTitle,
          sessionData: sessionData,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(cardSetTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(cardSetTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// カードが空の場合の表示
class _EmptyView extends StatelessWidget {
  final String cardSetTitle;

  const _EmptyView({required this.cardSetTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(cardSetTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('学習するカードがありません'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 学習セッション画面
class _StudySessionView extends HookConsumerWidget {
  final String cardSetId;
  final String cardSetTitle;
  final StudySessionData sessionData;

  const _StudySessionView({
    super.key,
    required this.cardSetId,
    required this.cardSetTitle,
    required this.sessionData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = useState(StudyViewState.question);
    final currentIndex = useState(0);
    final correctCount = useState(0);
    final partialCount = useState(0);
    final incorrectCount = useState(0);
    final startedAt = useMemoized(() => DateTime.now());
    final userAnswer = useState('');

    final stats = useMemoized(
      () => StudyStats(
        totalCards: sessionData.cards.length,
        currentIndex: currentIndex.value,
        correctCount: correctCount.value,
        partialCount: partialCount.value,
        incorrectCount: incorrectCount.value,
        startedAt: startedAt,
      ),
      [
        currentIndex.value,
        correctCount.value,
        partialCount.value,
        incorrectCount.value,
      ],
    );

    final currentCard = currentIndex.value < sessionData.cards.length
        ? sessionData.cards[currentIndex.value]
        : null;

    // 評価処理
    Future<void> handleEvaluation(EvaluationType evaluation) async {
      if (currentCard == null) return;

      try {
        // 学習進捗を更新
        final viewModel = ref.read(studyViewModelProvider(cardSetId).notifier);
        await viewModel.updateProgress(
          cardId: currentCard.id,
          cardSetId: currentCard.cardSetId,
          evaluation: evaluation,
        );

        // 統計を更新
        if (evaluation == EvaluationType.correct) {
          correctCount.value++;
        } else if (evaluation == EvaluationType.partial) {
          partialCount.value++;
        } else {
          incorrectCount.value++;
        }

        // 次のカードへ
        currentIndex.value++;
        userAnswer.value = '';

        // セッション完了判定
        if (currentIndex.value >= sessionData.cards.length) {
          await viewModel.completeSession(
            sessionId: sessionData.sessionId,
            stats: stats,
          );
          viewState.value = StudyViewState.completed;
        } else {
          viewState.value = StudyViewState.question;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cardSetTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: stats.progressRate,
            backgroundColor: Colors.grey[300],
          ),
        ),
      ),
      body: viewState.value == StudyViewState.completed
          ? _CompletedView(
              cardSetId: cardSetId,
              cardSetTitle: cardSetTitle,
              stats: stats,
              onRestart: () {
                ref.invalidate(studyViewModelProvider(cardSetId));
              },
            )
          : viewState.value == StudyViewState.question
              ? _QuestionView(
                  currentCard: currentCard,
                  stats: stats,
                  userAnswer: userAnswer,
                  onShowAnswer: () => viewState.value = StudyViewState.answer,
                )
              : _AnswerView(
                  currentCard: currentCard,
                  stats: stats,
                  userAnswer: userAnswer.value,
                  onEvaluate: handleEvaluation,
                ),
    );
  }
}

/// 問題表示画面
class _QuestionView extends HookWidget {
  final CardModel? currentCard;
  final StudyStats stats;
  final ValueNotifier<String> userAnswer;
  final VoidCallback onShowAnswer;

  const _QuestionView({
    required this.currentCard,
    required this.stats,
    required this.userAnswer,
    required this.onShowAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final answerController = useTextEditingController(text: userAnswer.value);

    if (currentCard == null) {
      return const Center(child: Text('カードがありません'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 進捗表示
          Text(
            '${stats.currentIndex + 1} / ${stats.totalCards}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          // 問題（日本語）
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  currentCard!.front,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 回答入力エリア
          TextField(
            controller: answerController,
            decoration: InputDecoration(
              hintText: '英語で答えを入力...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onChanged: (value) => userAnswer.value = value,
          ),

          const SizedBox(height: 24),

          // 解答確認ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onShowAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '解答を確認',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 解答確認画面
class _AnswerView extends StatelessWidget {
  final CardModel? currentCard;
  final StudyStats stats;
  final String userAnswer;
  final Future<void> Function(EvaluationType) onEvaluate;

  const _AnswerView({
    required this.currentCard,
    required this.stats,
    required this.userAnswer,
    required this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    if (currentCard == null) {
      return const Center(child: Text('カードがありません'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 進捗表示
          Text(
            '${stats.currentIndex + 1} / ${stats.totalCards}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 問題
                  _buildSection(
                    context,
                    '問題',
                    currentCard!.front,
                    Colors.grey[700]!,
                  ),

                  const SizedBox(height: 24),

                  // あなたの回答
                  _buildSection(
                    context,
                    'あなたの回答',
                    userAnswer.isEmpty ? '（未入力）' : userAnswer,
                    Colors.blue[700]!,
                  ),

                  const SizedBox(height: 24),

                  // 正解
                  _buildSection(
                    context,
                    '正解',
                    currentCard!.back,
                    Colors.green[700]!,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 自己評価ボタン
          Text(
            '自己評価',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // × 不正解
              Expanded(
                child: _EvaluationButton(
                  label: '×\nもう一度',
                  color: Colors.red,
                  onPressed: () => onEvaluate(EvaluationType.incorrect),
                ),
              ),
              const SizedBox(width: 12),

              // △ やや正解
              Expanded(
                child: _EvaluationButton(
                  label: '△\nだいたい',
                  color: Colors.orange,
                  onPressed: () => onEvaluate(EvaluationType.partial),
                ),
              ),
              const SizedBox(width: 12),

              // ○ 正解
              Expanded(
                child: _EvaluationButton(
                  label: '○\n完璧！',
                  color: Colors.green,
                  onPressed: () => onEvaluate(EvaluationType.correct),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// 評価ボタン
class _EvaluationButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _EvaluationButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 学習完了画面
class _CompletedView extends StatelessWidget {
  final String cardSetId;
  final String cardSetTitle;
  final StudyStats stats;
  final VoidCallback onRestart;

  const _CompletedView({
    required this.cardSetId,
    required this.cardSetTitle,
    required this.stats,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final durationMinutes = DateTime.now().difference(stats.startedAt).inMinutes;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 完了アイコン
          Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green[400],
          ),
          const SizedBox(height: 24),

          // 完了メッセージ
          Text(
            '学習完了！',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'お疲れさまでした',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 48),

          // 統計情報
          _buildStatCard(
            context,
            [
              _StatItem(
                icon: Icons.timer,
                label: '学習時間',
                value: '$durationMinutes分',
              ),
              _StatItem(
                icon: Icons.style,
                label: 'カード数',
                value: '${stats.cardsStudied}枚',
              ),
              _StatItem(
                icon: Icons.check_circle,
                label: '正答率',
                value: '${stats.accuracyRate.toStringAsFixed(0)}%',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 内訳
          _buildResultBreakdown(context, stats),

          const Spacer(),

          // ボタン群
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'もう一度学習',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'セットに戻る',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, List<_StatItem> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items
              .map((item) => _buildStatItem(context, item))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, _StatItem item) {
    return Column(
      children: [
        Icon(item.icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          item.value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildResultBreakdown(BuildContext context, StudyStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResultItem(
            context,
            '○',
            stats.correctCount,
            Colors.green,
          ),
          _buildResultItem(
            context,
            '△',
            stats.partialCount,
            Colors.orange,
          ),
          _buildResultItem(
            context,
            '×',
            stats.incorrectCount,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
