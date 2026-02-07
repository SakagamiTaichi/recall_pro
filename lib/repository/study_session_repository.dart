import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env_config.dart';
import '../model/study_session_model.dart';
import 'card_set_repository.dart';

part 'study_session_repository.g.dart';

/// 学習セッションのリポジトリ
/// Firestoreとの通信を担当
class StudySessionRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  StudySessionRepository(this._firestore, this._userId);

  /// 学習セッションコレクションの参照
  CollectionReference<Map<String, dynamic>> get _sessionCollection =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('studySessions');

  /// セッションを作成
  Future<StudySessionModel> createSession({
    required String cardSetId,
  }) async {
    final docRef = _sessionCollection.doc();
    final session = StudySessionModel.create(
      id: docRef.id,
      userId: _userId,
      cardSetId: cardSetId,
    );
    await docRef.set(session.toFirestore());
    return session;
  }

  /// セッションを取得
  Future<StudySessionModel?> getSession(String sessionId) async {
    final doc = await _sessionCollection.doc(sessionId).get();
    if (!doc.exists) return null;
    return StudySessionModel.fromFirestore(doc);
  }

  /// セッションを更新
  Future<void> updateSession(StudySessionModel session) async {
    await _sessionCollection.doc(session.id).update(session.toFirestore());
  }

  /// セッションを終了
  Future<void> endSession({
    required String sessionId,
    required int cardsStudied,
    required int correctCount,
    required int incorrectCount,
    required int partialCount,
  }) async {
    await _sessionCollection.doc(sessionId).update({
      'endedAt': Timestamp.now(),
      'cardsStudied': cardsStudied,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'partialCount': partialCount,
    });
  }

  /// カードセット別のセッション履歴を取得
  Future<List<StudySessionModel>> getSessionsByCardSet(
    String cardSetId, {
    int limit = 10,
  }) async {
    final snapshot = await _sessionCollection
        .where('cardSetId', isEqualTo: cardSetId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => StudySessionModel.fromFirestore(doc))
        .toList();
  }

  /// 全セッション履歴を取得
  Future<List<StudySessionModel>> getAllSessions({
    int limit = 20,
  }) async {
    final snapshot = await _sessionCollection
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => StudySessionModel.fromFirestore(doc))
        .toList();
  }

  /// セッションを削除
  Future<void> deleteSession(String sessionId) async {
    await _sessionCollection.doc(sessionId).delete();
  }

  /// カードセット別のセッションを全削除
  Future<void> deleteSessionsByCardSet(String cardSetId) async {
    final snapshot = await _sessionCollection
        .where('cardSetId', isEqualTo: cardSetId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// StudySessionRepositoryのプロバイダー
@riverpod
StudySessionRepository studySessionRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return StudySessionRepository(firestore, EnvConfig.fixedUserId);
}
