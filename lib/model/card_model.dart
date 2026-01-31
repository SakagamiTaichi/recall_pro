import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_model.freezed.dart';

/// カードのデータモデル
@freezed
class CardModel with _$CardModel {
  const CardModel._();

  const factory CardModel({
    required String id,
    required String cardSetId,
    required String front, // 日本語（問題）
    required String back, // 英語（解答）
    required DateTime createdAt,
    required DateTime updatedAt,
    required int order, // カードセット内の表示順序
  }) = _CardModel;

  /// 新規作成用のファクトリコンストラクタ
  factory CardModel.create({
    required String id,
    required String cardSetId,
    required String front,
    required String back,
    required int order,
  }) {
    final now = DateTime.now();
    return CardModel(
      id: id,
      cardSetId: cardSetId,
      front: front,
      back: back,
      createdAt: now,
      updatedAt: now,
      order: order,
    );
  }

  /// Firestoreドキュメントからの変換
  factory CardModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CardModel(
      id: doc.id,
      cardSetId: data['cardSetId'] as String? ?? '',
      front: data['front'] as String? ?? '',
      back: data['back'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: data['order'] as int? ?? 0,
    );
  }

  /// Firestoreへの保存用Map変換
  Map<String, dynamic> toFirestore() {
    return {
      'cardSetId': cardSetId,
      'front': front,
      'back': back,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'order': order,
    };
  }
}
