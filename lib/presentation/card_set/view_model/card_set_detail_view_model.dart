import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../model/card_set_model.dart';
import '../../../repository/card_set_repository.dart';

part 'card_set_detail_view_model.g.dart';

/// カードセット詳細画面のViewModel
/// cardSetIdをパラメータとして受け取るファミリープロバイダー
@riverpod
class CardSetDetailViewModel extends _$CardSetDetailViewModel {
  @override
  Stream<CardSetModel?> build(String cardSetId) async* {
    final repository = ref.watch(cardSetRepositoryProvider);

    if (repository == null) {
      yield null;
      return;
    }

    yield* repository.watchCardSets().map((cardSets) {
      try {
        return cardSets.firstWhere((cs) => cs.id == cardSetId);
      } catch (_) {
        return null;
      }
    });
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
