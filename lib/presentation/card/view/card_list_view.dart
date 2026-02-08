import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/card_model.dart';
import '../../card_set/component/card_set_dialog.dart';
import '../../card_set/view_model/card_set_detail_view_model.dart';
import '../component/card_dialog.dart';
import '../view_model/card_list_view_model.dart';

/// カード一覧画面
class CardListView extends HookConsumerWidget {
  final String cardSetId;
  final String cardSetTitle;

  const CardListView({
    super.key,
    required this.cardSetId,
    required this.cardSetTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final cardsAsync = ref.watch(
      cardListViewModelProvider(
        cardSetId: cardSetId,
        searchQuery: searchQuery.value,
      ),
    );

    // カードセット情報を監視（タイトルのリアルタイム更新用）
    final cardSetAsync = ref.watch(cardSetDetailViewModelProvider(cardSetId));

    return Scaffold(
      appBar: AppBar(
        title: Text(cardSetAsync.valueOrNull?.title ?? cardSetTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showCardSetEditDialog(context, ref),
            tooltip: '編集',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'カードを検索...',
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
          Expanded(
            child: cardsAsync.when(
              data: (cards) {
                if (cards.isEmpty) {
                  return _buildEmptyState(context, searchQuery.value.isNotEmpty);
                }
                return _buildCardList(context, ref, cards, searchQuery.value);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, ref, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('カード追加'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.note_add,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? '検索結果がありません'
                : 'カードがありません\n右下のボタンからカードを追加してください',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('エラーが発生しました: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(
              cardListViewModelProvider(cardSetId: cardSetId),
            ),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(
    BuildContext context,
    WidgetRef ref,
    List<CardModel> cards,
    String searchQuery,
  ) {
    final isSearching = searchQuery.isNotEmpty;

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cards.length,
      onReorder: (oldIndex, newIndex) {
        if (isSearching) return; // 検索中は並び替え無効
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final reorderedCards = List<CardModel>.from(cards);
        final item = reorderedCards.removeAt(oldIndex);
        reorderedCards.insert(newIndex, item);

        final viewModel = ref.read(
          cardListViewModelProvider(cardSetId: cardSetId).notifier,
        );
        viewModel.reorderCards(reorderedCards);
      },
      itemBuilder: (context, index) {
        final card = cards[index];
        return _CardTile(
          key: ValueKey(card.id),
          card: card,
          index: index + 1,
          onEdit: () => _showEditDialog(context, ref, card),
          onDelete: () => _showDeleteDialog(context, ref, card),
        );
      },
    );
  }

  void _showCardSetEditDialog(BuildContext context, WidgetRef ref) {
    final cardSetAsync = ref.read(cardSetDetailViewModelProvider(cardSetId));
    cardSetAsync.whenData((cardSet) {
      if (cardSet == null) return;
      showDialog(
        context: context,
        builder: (context) => CardSetDialog(
          cardSet: cardSet,
          onSave: (title, description) async {
            final viewModel = ref.read(
              cardSetDetailViewModelProvider(cardSetId).notifier,
            );
            await viewModel.updateCardSet(
              id: cardSet.id,
              title: title,
              description: description,
            );
          },
        ),
      );
    });
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      cardListViewModelProvider(cardSetId: cardSetId).notifier,
    );
    showDialog(
      context: context,
      builder: (context) => CardDialog(
        onSave: (front, back) async {
          await viewModel.createCard(front: front, back: back);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, CardModel card) {
    final viewModel = ref.read(
      cardListViewModelProvider(cardSetId: cardSetId).notifier,
    );
    showDialog(
      context: context,
      builder: (context) => CardDialog(
        card: card,
        onSave: (front, back) async {
          await viewModel.updateCard(
            cardId: card.id,
            front: front,
            back: back,
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, CardModel card) {
    final viewModel = ref.read(
      cardListViewModelProvider(cardSetId: cardSetId).notifier,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('カードを削除'),
        content: Text(
          '「${card.front}」を削除しますか？\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await viewModel.deleteCard(card);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('カードを削除しました')),
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

/// カードのリストタイル
class _CardTile extends StatelessWidget {
  final CardModel card;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardTile({
    super.key,
    required this.card,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.front,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.back,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
        ),
      ),
    );
  }
}
