import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/card_set_model.dart';
import '../../../theme/theme_provider.dart';
import '../../../utils/date_formatter.dart';
import '../../card/view/card_list_view.dart';
import '../../settings/view/tts_settings_view.dart';
import '../../study/view/study_view.dart';
import '../component/card_set_dialog.dart';
import '../view_model/card_set_list_view_model.dart';

/// カードセット一覧画面
class CardSetListView extends HookConsumerWidget {
  const CardSetListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final currentTheme = ref.watch(themeNotifierProvider);

    // ViewModelからカードセットを取得
    final cardSetsAsync = ref.watch(
      cardSetListViewModelProvider(searchQuery: searchQuery.value),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('RecallPro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_voice),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TtsSettingsView(),
                ),
              );
            },
            tooltip: '音声設定',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => _showThemeDialog(context, ref),
            tooltip: 'テーマ切り替え',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                currentTheme.displayName,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'カードセットを検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),
          // カードセット一覧
          Expanded(
            child: cardSetsAsync.when(
              data: (cardSets) {
                if (cardSets.isEmpty) {
                  return _buildEmptyState(
                    context,
                    searchQuery.value.isNotEmpty,
                  );
                }
                return _buildCardSetList(context, ref, cardSets);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('エラーが発生しました: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(cardSetListViewModelProvider),
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新規作成'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.folder_open,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? '検索結果がありません' : 'カードセットがありません\n右下のボタンから作成してください',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSetList(
    BuildContext context,
    WidgetRef ref,
    List<CardSetModel> cardSets,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cardSets.length,
      itemBuilder: (context, index) {
        final cardSet = cardSets[index];
        return _CardSetTile(
          cardSet: cardSet,
          onTap: () => _navigateToDetail(context, cardSet),
          onStudy: () => _navigateToStudy(context, cardSet),
          onEdit: () => _showEditDialog(context, ref, cardSet),
          onDelete: () => _showDeleteDialog(context, ref, cardSet),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマを選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(mode.displayName),
              value: mode,
              groupValue: ref.read(themeNotifierProvider),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeNotifierProvider.notifier).setTheme(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(cardSetListViewModelProvider().notifier);
    showDialog(
      context: context,
      builder: (context) => CardSetDialog(
        onSave: (title, description) async {
          await viewModel.createCardSet(title: title, description: description);
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CardSetModel cardSet,
  ) {
    final viewModel = ref.read(cardSetListViewModelProvider().notifier);
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

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    CardSetModel cardSet,
  ) {
    final viewModel = ref.read(cardSetListViewModelProvider().notifier);
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

  void _navigateToDetail(BuildContext context, CardSetModel cardSet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardListView(
          cardSetId: cardSet.id,
          cardSetTitle: cardSet.title,
        ),
      ),
    );
  }

  void _navigateToStudy(BuildContext context, CardSetModel cardSet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudyView(
          cardSetId: cardSet.id,
          cardSetTitle: cardSet.title,
        ),
      ),
    );
  }
}

/// カードセットのリストタイル
class _CardSetTile extends StatelessWidget {
  final CardSetModel cardSet;
  final VoidCallback onTap;
  final VoidCallback onStudy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardSetTile({
    required this.cardSet,
    required this.onTap,
    required this.onStudy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cardSet.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('編集'),
                          ],
                        ),
                      ),
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
              if (cardSet.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  cardSet.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(icon: Icons.style, label: '${cardSet.cardCount}枚'),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.update,
                    label: DateFormatter.formatRelative(cardSet.updatedAt),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: cardSet.cardCount > 0 ? onStudy : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('学習を開始'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 情報チップ
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
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
