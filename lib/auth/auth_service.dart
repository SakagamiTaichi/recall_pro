import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

/// Firebase Authentication サービスクラス
/// 匿名認証の処理を担当
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  /// 現在のユーザー
  User? get currentUser => _auth.currentUser;

  /// 認証状態の変更を監視するStream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 匿名ログイン
  /// 既にログイン済みの場合は何もしない
  Future<User?> signInAnonymously() async {
    try {
      // 既にログイン済みの場合は現在のユーザーを返す
      if (currentUser != null) {
        return currentUser;
      }

      // 匿名ログイン
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException._fromFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('匿名ログインに失敗しました', e.toString());
    }
  }

  /// ログアウト（通常は使用しない）
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException._fromFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('ログアウトに失敗しました', e.toString());
    }
  }
}

/// 認証例外クラス
class AuthException implements Exception {
  final String message;
  final String? details;

  AuthException(this.message, [this.details]);

  factory AuthException._fromFirebaseAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'operation-not-allowed':
        message = '匿名認証が有効になっていません';
        break;
      case 'network-request-failed':
        message = 'ネットワーク接続を確認してください';
        break;
      default:
        message = '認証エラーが発生しました';
    }
    return AuthException(message, e.message);
  }

  @override
  String toString() {
    if (details != null) {
      return '$message: $details';
    }
    return message;
  }
}

/// FirebaseAuth インスタンスのプロバイダー
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

/// AuthService のプロバイダー
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
}

/// 認証状態の変更を監視するプロバイダー
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}

/// 現在のユーザーを取得するプロバイダー
@riverpod
User? currentUser(Ref ref) {
  // authStateChangesを監視して、認証状態が変更されたら再計算される
  return ref.watch(authStateChangesProvider).value;
}
