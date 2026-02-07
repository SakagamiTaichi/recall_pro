import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/env_config.dart';
import '../../../model/card_model.dart';
import '../../../repository/card_repository.dart';
import '../../../repository/card_set_repository.dart';

part 'card_list_view_model.g.dart';

/// カード一覧画面のViewModel
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  Stream<List<CardModel>> build({
    required String cardSetId,
    String searchQuery = '',
  }) async* {
    final firestore = ref.watch(firestoreProvider);
    final repository = CardRepository(firestore, EnvConfig.fixedUserId);

    yield* repository.watchCards(cardSetId).map((cards) {
      if (searchQuery.isEmpty) return cards;
      final lowerQuery = searchQuery.toLowerCase();
      return cards
          .where(
            (c) =>
                c.front.toLowerCase().contains(lowerQuery) ||
                c.back.toLowerCase().contains(lowerQuery),
          )
          .toList();
    });
  }

  /// カードを作成
  Future<void> createCard({
    required String front,
    required String back,
  }) async {
    final firestore = ref.read(firestoreProvider);
    final repository = CardRepository(firestore, EnvConfig.fixedUserId);

    // 現在のカード数を取得してorderを設定
    final currentCount = await repository.getCardCount(cardSetId);

    await repository.createCard(
      cardSetId: cardSetId,
      front: front,
      back: back,
      order: currentCount,
    );

    // カードセットのcardCountを更新
    final cardSetRepo = ref.read(cardSetRepositoryProvider);
    await cardSetRepo.updateCardCount(cardSetId, currentCount + 1);
  }

  /// カードを更新
  Future<void> updateCard({
    required String cardId,
    required String front,
    required String back,
  }) async {
    final firestore = ref.read(firestoreProvider);
    final repository = CardRepository(firestore, EnvConfig.fixedUserId);

    await repository.updateCard(
      cardSetId: cardSetId,
      cardId: cardId,
      front: front,
      back: back,
    );
  }

  /// カードを削除
  Future<void> deleteCard(CardModel card) async {
    final firestore = ref.read(firestoreProvider);
    final repository = CardRepository(firestore, EnvConfig.fixedUserId);

    await repository.deleteCard(cardSetId, card.id);

    // カードセットのcardCountを更新
    final cardSetRepo = ref.read(cardSetRepositoryProvider);
    final currentCount = await repository.getCardCount(cardSetId);
    await cardSetRepo.updateCardCount(cardSetId, currentCount);
  }

  /// カードの並び替え
  Future<void> reorderCards(List<CardModel> reorderedCards) async {
    final firestore = ref.read(firestoreProvider);
    final repository = CardRepository(firestore, EnvConfig.fixedUserId);

    await repository.updateCardsOrder(cardSetId, reorderedCards);
  }
}
