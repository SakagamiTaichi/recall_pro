import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/tts_settings_model.dart';
import '../view_model/tts_settings_view_model.dart';

/// TTS設定画面
class TtsSettingsView extends HookConsumerWidget {
  const TtsSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(ttsSettingsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声読み上げ設定'),
        actions: [
          TextButton(
            onPressed: () async {
              final viewModel = ref.read(ttsSettingsViewModelProvider.notifier);
              await viewModel.resetToDefault();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('設定をリセットしました')));
              }
            },
            child: const Text('リセット'),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) => _SettingsContent(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 設定内容
class _SettingsContent extends HookConsumerWidget {
  final TtsSettingsModel settings;

  const _SettingsContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(ttsSettingsViewModelProvider.notifier);
    final isSpeaking = useState(false);
    final isMounted = useRef(true);
    final availableVoices = useState<List<Map<String, String>>>([]);
    final isLoadingVoices = useState(false);

    // ボイス一覧を取得
    useEffect(() {
      Future<void> loadVoices() async {
        isLoadingVoices.value = true;
        try {
          final voices = await viewModel.getAvailableVoices();
          if (isMounted.value) {
            availableVoices.value = voices;
          }
        } catch (e) {
          // エラーは無視（ボイス選択が利用できない環境の可能性）
        } finally {
          if (isMounted.value) {
            isLoadingVoices.value = false;
          }
        }
      }

      loadVoices();
      return null;
    }, []);

    // ウィジェット破棄時のクリーンアップ
    useEffect(() {
      return () {
        isMounted.value = false;
      };
    }, []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 自動再生設定
        Card(
          child: SwitchListTile(
            title: const Text('自動再生'),
            subtitle: const Text('解答確認時に自動で音声を再生します'),
            value: settings.autoPlay,
            onChanged: (value) => viewModel.updateAutoPlay(value),
          ),
        ),

        const SizedBox(height: 24),

        // 音声設定
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '音声設定',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // ボイス選択
                if (availableVoices.value.isNotEmpty) ...[
                  Text('ボイス'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: settings.voiceName,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('デフォルトボイス'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('デフォルトボイス'),
                      ),
                      ...availableVoices.value.map((voice) {
                        final name = voice['name'] ?? '';
                        final locale = voice['locale'] ?? '';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text('$name ($locale)'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        viewModel.updateVoice(null, null);
                      } else {
                        final selectedVoice = availableVoices.value.firstWhere(
                          (v) => v['name'] == value,
                        );
                        viewModel.updateVoice(
                          selectedVoice['name'],
                          selectedVoice['locale'],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // 速度
                _SliderSetting(
                  label: '速度',
                  value: settings.speechRate,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => viewModel.updateSpeechRate(value),
                  displayValue: '${(settings.speechRate * 100).toInt()}%',
                ),

                const SizedBox(height: 16),

                // ピッチ
                _SliderSetting(
                  label: 'ピッチ',
                  value: settings.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) => viewModel.updatePitch(value),
                  displayValue: settings.pitch.toStringAsFixed(1),
                ),

                const SizedBox(height: 16),

                // 音量
                _SliderSetting(
                  label: '音量',
                  value: settings.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => viewModel.updateVolume(value),
                  displayValue: '${(settings.volume * 100).toInt()}%',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // テスト再生
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '音声テスト',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'テストフレーズ: "Hello, this is a test message."',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSpeaking.value
                            ? null
                            : () async {
                                isSpeaking.value = true;
                                try {
                                  await viewModel.testSpeak(
                                    'Hello, this is a test message.',
                                  );
                                  // 再生完了後に状態をリセット（遅延）
                                  await Future.delayed(
                                    const Duration(seconds: 3),
                                  );
                                } finally {
                                  // ウィジェットがまだマウントされている場合のみ状態を更新
                                  if (isMounted.value) {
                                    isSpeaking.value = false;
                                  }
                                }
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('再生'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSpeaking.value
                            ? () async {
                                await viewModel.stopSpeaking();
                                // ウィジェットがまだマウントされている場合のみ状態を更新
                                if (isMounted.value) {
                                  isSpeaking.value = false;
                                }
                              }
                            : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('停止'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 説明
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'ヒント',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• ボイス: 使用する音声を選択します\n'
                  '• 速度: 音声の速さを調整します（遅い←→速い）\n'
                  '• ピッチ: 音声の高さを調整します（低い←→高い）\n'
                  '• 音量: 音声の大きさを調整します\n'
                  '• 自動再生をOFFにすると、手動でスピーカーボタンを押した時のみ再生されます',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// スライダー設定Widget
class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String displayValue;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              displayValue,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
