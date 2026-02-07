import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境設定
class EnvConfig {
  EnvConfig._();

  /// 固定ユーザーID（個人学習用）
  static String get fixedUserId =>
      dotenv.env['FIXED_USER_ID'] ?? 'personal-learning-user';
}
