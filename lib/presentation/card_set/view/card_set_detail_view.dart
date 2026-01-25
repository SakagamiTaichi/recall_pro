import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/card_set_model.dart';
import '../../../utils/date_formatter.dart';
import '../view_model/card_set_detail_view_model.dart';
import '../component/card_set_dialog.dart';

/// カードセット詳細画面
class CardSetDetailView extends ConsumerWidget {
  final String cardSetId;

  const CardSetDetailView({super.key, required this.cardSetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardSetAsync = ref.watch(cardSetDetailViewModelProvider(cardSetId));

    return cardSetAsync.when(
      data: (cardSet) {
        if (cardSet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('カードセット')),
            body: const Center(child: Text('カードセットが見つかりません')),
          );
        }
        return _CardSetDetailContent(cardSet: cardSet, cardSetId: cardSetId);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('読み込み中...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// カードセット詳細のコンテンツ
class _CardSetDetailContent extends ConsumerWidget {
  final CardSetModel cardSet;
  final String cardSetId;

  const _CardSetDetailContent({required this.cardSet, required this.cardSetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cardSet.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, ref),
            tooltip: '編集',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カードセット情報カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardSet.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (cardSet.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        cardSet.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.style,
                          label: 'カード数',
                          value: '${cardSet.cardCount}',
                        ),
                        _StatItem(
                          icon: Icons.calendar_today,
                          label: '作成日',
                          value: DateFormatter.formatSimple(cardSet.createdAt),
                        ),
                        _StatItem(
                          icon: Icons.update,
                          label: '更新日',
                          value: DateFormatter.formatSimple(cardSet.updatedAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 学習ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: cardSet.cardCount > 0
                    ? () {
                        // TODO: 学習画面への遷移（将来実装）
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('学習機能は今後実装予定です')),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('学習を開始'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // カード一覧セクション
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'カード一覧',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: カード追加機能（将来実装）
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('カード追加機能は今後実装予定です')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('追加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // カード一覧（プレースホルダー）
            if (cardSet.cardCount == 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.note_add, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'カードがありません\n「追加」ボタンからカードを追加してください',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'カード一覧機能は今後実装予定です\n(${cardSet.cardCount}枚のカード)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      cardSetDetailViewModelProvider(cardSetId).notifier,
    );
    showDialog(
      context: context,
      builder: (context) => CardSetDialog(
        cardSet: cardSet,
        onSave: (title, description) async {
          await viewModel.updateCardSet(
            id: cardSet.id,
            title: title,
            description: description,
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      cardSetDetailViewModelProvider(cardSetId).notifier,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('カードセットを削除'),
        content: Text('「${cardSet.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await viewModel.deleteCardSet(cardSet);
              if (context.mounted) {
                Navigator.of(context).pop(); // 詳細画面を閉じる
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${cardSet.title}」を削除しました')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

/// 統計情報アイテム
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
