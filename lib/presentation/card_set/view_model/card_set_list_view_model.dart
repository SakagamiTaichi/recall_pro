import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../model/card_set_model.dart';
import '../../../repository/card_set_repository.dart';

part 'card_set_list_view_model.g.dart';

/// カードセット一覧画面のViewModel
@riverpod
class CardSetListViewModel extends _$CardSetListViewModel {
  @override
  Stream<List<CardSetModel>> build({String searchQuery = ''}) async* {
    final repository = ref.watch(cardSetRepositoryProvider);

    if (repository == null) {
      yield [];
      return;
    }

    yield* repository.watchCardSets().map((cardSets) {
      if (searchQuery.isEmpty) return cardSets;
      final lowerQuery = searchQuery.toLowerCase();
      return cardSets
          .where(
            (c) =>
                c.title.toLowerCase().contains(lowerQuery) ||
                c.description.toLowerCase().contains(lowerQuery),
          )
          .toList();
    });
  }

  /// カードセットを作成
  Future<void> createCardSet({
    required String title,
    required String description,
  }) async {
    final repository = ref.read(cardSetRepositoryProvider);
    if (repository == null) return;

    await repository.createCardSet(title: title, description: description);
  }

  /// カードセットを更新
  Future<void> updateCardSet({
    required String id,
    required String title,
    required String description,
  }) async {
    final repository = ref.read(cardSetRepositoryProvider);
    if (repository == null) return;

    await repository.updateCardSetInfo(
      id: id,
      title: title,
      description: description,
    );
  }

  /// カードセットを削除
  Future<void> deleteCardSet(CardSetModel cardSet) async {
    final repository = ref.read(cardSetRepositoryProvider);
    if (repository == null) return;

    await repository.deleteCardSet(cardSet.id);
  }
}
