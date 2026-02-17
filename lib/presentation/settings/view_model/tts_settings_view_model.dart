import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../model/tts_settings_model.dart';
import '../../../repository/tts_settings_repository.dart';
import '../../../service/tts_service.dart';

part 'tts_settings_view_model.g.dart';

/// TTS設定画面のViewModel
@riverpod
class TtsSettingsViewModel extends _$TtsSettingsViewModel {
  @override
  Future<TtsSettingsModel> build() async {
    // リポジトリから直接読み込み（ttsSettingsProviderを監視しない）
    final repository = await ref.read(ttsSettingsRepositoryProvider.future);
    final settings = await repository.loadSettings();

    // TtsServiceを初期化
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.initialize(settings);

    return settings;
  }

  /// 言語を更新
  Future<void> updateLanguage(String language) async {
    final currentSettings = await future;
    final updatedSettings = currentSettings.copyWith(language: language);
    await _saveSettings(updatedSettings);
  }

  /// 速度を更新
  Future<void> updateSpeechRate(double rate) async {
    final currentSettings = await future;
    final updatedSettings = currentSettings.copyWith(speechRate: rate);
    await _saveSettings(updatedSettings);
  }

  /// ピッチを更新
  Future<void> updatePitch(double pitch) async {
    final currentSettings = await future;
    final updatedSettings = currentSettings.copyWith(pitch: pitch);
    await _saveSettings(updatedSettings);
  }

  /// 音量を更新
  Future<void> updateVolume(double volume) async {
    final currentSettings = await future;
    final updatedSettings = currentSettings.copyWith(volume: volume);
    await _saveSettings(updatedSettings);
  }

  /// 自動再生を更新
  Future<void> updateAutoPlay(bool autoPlay) async {
    final currentSettings = await future;
    final updatedSettings = currentSettings.copyWith(autoPlay: autoPlay);
    await _saveSettings(updatedSettings);
  }

  /// ボイスを更新
  Future<void> updateVoice(String? voiceName, String? voiceLocale) async {
    final currentSettings = await future;
    final updatedSettings = currentSettings.copyWith(
      voiceName: voiceName,
      voiceLocale: voiceLocale,
    );
    await _saveSettings(updatedSettings);
  }

  /// 利用可能なボイスを取得
  Future<List<Map<String, String>>> getAvailableVoices() async {
    final ttsService = ref.read(ttsServiceProvider);
    return await ttsService.getAvailableVoices();
  }

  /// 設定をデフォルトに戻す
  Future<void> resetToDefault() async {
    final repository = await ref.read(ttsSettingsRepositoryProvider.future);
    await repository.clearSettings();

    // ttsSettingsProviderのキャッシュを無効化
    ref.invalidate(ttsSettingsProvider);

    // プロバイダーを再読み込み
    ref.invalidateSelf();
  }

  /// テスト再生
  Future<void> testSpeak(String text) async {
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.speak(text);
  }

  /// 停止
  Future<void> stopSpeaking() async {
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.stop();
  }

  /// 内部メソッド: 設定を保存してTTSサービスを更新
  Future<void> _saveSettings(TtsSettingsModel settings) async {
    final repository = await ref.read(ttsSettingsRepositoryProvider.future);
    await repository.saveSettings(settings);

    // TtsServiceの設定を更新
    final ttsService = ref.read(ttsServiceProvider);
    await ttsService.updateSettings(settings);

    // ttsSettingsProviderのキャッシュを無効化
    ref.invalidate(ttsSettingsProvider);

    // 状態を更新
    state = AsyncValue.data(settings);
  }
}
