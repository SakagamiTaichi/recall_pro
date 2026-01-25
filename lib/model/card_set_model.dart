import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_set_model.freezed.dart';

/// カードセットのデータモデル
@freezed
class CardSetModel with _$CardSetModel {
  const CardSetModel._();

  const factory CardSetModel({
    required String id,
    required String title,
    required String description,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int cardCount,
    required String userId,
  }) = _CardSetModel;

  /// 新規作成用のファクトリコンストラクタ
  factory CardSetModel.create({
    required String id,
    required String title,
    required String userId,
    String description = '',
  }) {
    final now = DateTime.now();
    return CardSetModel(
      id: id,
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
      cardCount: 0,
      userId: userId,
    );
  }

  /// Firestoreドキュメントからの変換
  factory CardSetModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CardSetModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cardCount: data['cardCount'] as int? ?? 0,
      userId: data['userId'] as String? ?? '',
    );
  }

  /// Firestoreへの保存用Map変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cardCount': cardCount,
      'userId': userId,
    };
  }
}
