import 'package:freezed_annotation/freezed_annotation.dart';

part 'tts_settings_model.freezed.dart';

/// TTS設定のデータモデル
@freezed
class TtsSettingsModel with _$TtsSettingsModel {
  const TtsSettingsModel._();

  const factory TtsSettingsModel({
    required String language,      // 言語コード（例: "en-US"）
    required double speechRate,    // 速度 (0.0-1.0)
    required double pitch,         // ピッチ (0.5-2.0)
    required double volume,        // 音量 (0.0-1.0)
    required bool autoPlay,        // 自動再生ON/OFF
    String? voiceName,             // ボイス名（例: "en-us-x-sfg-local"）
    String? voiceLocale,           // ボイスロケール（例: "en-US"）
  }) = _TtsSettingsModel;

  /// デフォルト設定
  factory TtsSettingsModel.defaultSettings() {
    return const TtsSettingsModel(
      language: 'en-US',
      speechRate: 0.5,  // 通常速度
      pitch: 1.0,       // 標準ピッチ
      volume: 1.0,      // 最大音量
      autoPlay: false,  // デフォルトは手動再生
      voiceName: null,  // デフォルトボイス
      voiceLocale: null,
    );
  }

  /// SharedPreferences用のMap変換
  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'speechRate': speechRate,
      'pitch': pitch,
      'volume': volume,
      'autoPlay': autoPlay,
      'voiceName': voiceName,
      'voiceLocale': voiceLocale,
    };
  }

  /// SharedPreferencesからの復元
  factory TtsSettingsModel.fromJson(Map<String, dynamic> json) {
    return TtsSettingsModel(
      language: json['language'] as String? ?? 'en-US',
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      autoPlay: json['autoPlay'] as bool? ?? false,
      voiceName: json['voiceName'] as String?,
      voiceLocale: json['voiceLocale'] as String?,
    );
  }
}
