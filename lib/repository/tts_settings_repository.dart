import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/tts_settings_model.dart';

part 'tts_settings_repository.g.dart';

/// TTS設定のリポジトリ
/// SharedPreferencesを使用したローカル保存
class TtsSettingsRepository {
  static const String _settingsKey = 'tts_settings';
  final SharedPreferences _prefs;

  TtsSettingsRepository(this._prefs);

  /// 設定を読み込み
  Future<TtsSettingsModel> loadSettings() async {
    try {
      final jsonString = _prefs.getString(_settingsKey);
      if (jsonString == null) {
        return TtsSettingsModel.defaultSettings();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TtsSettingsModel.fromJson(json);
    } catch (e) {
      // エラー時はデフォルト設定を返す
      return TtsSettingsModel.defaultSettings();
    }
  }

  /// 設定を保存
  Future<void> saveSettings(TtsSettingsModel settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, jsonString);
  }

  /// 設定を削除（デフォルトに戻す）
  Future<void> clearSettings() async {
    await _prefs.remove(_settingsKey);
  }
}

/// SharedPreferencesインスタンスのプロバイダー
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// TtsSettingsRepositoryのプロバイダー
@Riverpod(keepAlive: true)
Future<TtsSettingsRepository> ttsSettingsRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return TtsSettingsRepository(prefs);
}

/// 設定を読み込むプロバイダー
@riverpod
Future<TtsSettingsModel> ttsSettings(Ref ref) async {
  final repository = await ref.watch(ttsSettingsRepositoryProvider.future);
  return await repository.loadSettings();
}
