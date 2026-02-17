import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/tts_settings_model.dart';

part 'tts_service.g.dart';

/// TTS（Text-to-Speech）サービスクラス
/// flutter_ttsのラッパー
class TtsService {
  final FlutterTts _flutterTts;
  TtsSettingsModel? _currentSettings;
  bool _isInitialized = false;

  TtsService(this._flutterTts);

  /// 初期化（設定適用）
  Future<void> initialize(TtsSettingsModel settings) async {
    try {
      _currentSettings = settings;

      await _flutterTts.setLanguage(settings.language);
      await _flutterTts.setSpeechRate(settings.speechRate);
      await _flutterTts.setPitch(settings.pitch);
      await _flutterTts.setVolume(settings.volume);

      // ボイスが設定されている場合は適用
      if (settings.voiceName != null && settings.voiceLocale != null) {
        await _flutterTts.setVoice({
          "name": settings.voiceName!,
          "locale": settings.voiceLocale!,
        });
      }

      // プラットフォーム固有の設定（iOS）
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      _isInitialized = true;
    } catch (e) {
      throw TtsException('TTS初期化に失敗しました', e.toString());
    }
  }

  /// テキストを読み上げ
  Future<void> speak(String text) async {
    // 未初期化の場合はデフォルト設定で初期化
    if (!_isInitialized) {
      await initialize(TtsSettingsModel.defaultSettings());
    }

    if (text.isEmpty) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      throw TtsException('音声再生に失敗しました', e.toString());
    }
  }

  /// 再生停止
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // 停止時のエラーは無視（既に停止している場合など）
    }
  }

  /// 設定を更新
  Future<void> updateSettings(TtsSettingsModel settings) async {
    await initialize(settings);
  }

  /// 利用可能なボイスを取得
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        return voices
            .map((voice) {
              if (voice is Map) {
                return {
                  'name': voice['name']?.toString() ?? '',
                  'locale': voice['locale']?.toString() ?? '',
                };
              }
              return <String, String>{};
            })
            .where((voice) => voice['name']!.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      throw TtsException('ボイスの取得に失敗しました', e.toString());
    }
  }

  /// ボイスを設定
  Future<void> setVoice(String voiceName, String voiceLocale) async {
    try {
      await _flutterTts.setVoice({"name": voiceName, "locale": voiceLocale});
    } catch (e) {
      throw TtsException('ボイスの設定に失敗しました', e.toString());
    }
  }

  /// ハンドラーの設定
  void setStartHandler(void Function() handler) {
    _flutterTts.setStartHandler(handler);
  }

  void setCompletionHandler(void Function() handler) {
    _flutterTts.setCompletionHandler(handler);
  }

  void setErrorHandler(void Function(dynamic) handler) {
    _flutterTts.setErrorHandler(handler);
  }

  /// 現在の設定を取得
  TtsSettingsModel? get currentSettings => _currentSettings;

  /// 初期化状態を確認
  bool get isInitialized => _isInitialized;

  /// リソース解放
  Future<void> dispose() async {
    await stop();
  }
}

/// TTS例外クラス
class TtsException implements Exception {
  final String message;
  final String? details;

  TtsException(this.message, this.details);

  @override
  String toString() {
    if (details != null) {
      return '$message: $details';
    }
    return message;
  }
}

/// FlutterTtsインスタンスのプロバイダー
@Riverpod(keepAlive: true)
FlutterTts flutterTts(Ref ref) {
  final tts = FlutterTts();
  ref.onDispose(() {
    tts.stop();
  });
  return tts;
}

/// TtsServiceのプロバイダー
@Riverpod(keepAlive: true)
TtsService ttsService(Ref ref) {
  final flutterTts = ref.watch(flutterTtsProvider);
  final service = TtsService(flutterTts);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
