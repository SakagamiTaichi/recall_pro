import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/card_model.dart';

/// カード作成・編集ダイアログ
class CardDialog extends HookConsumerWidget {
  final CardModel? card;
  final Future<void> Function(String front, String back) onSave;
  final bool enableContinuousCreation;

  const CardDialog({
    super.key,
    this.card,
    required this.onSave,
    this.enableContinuousCreation = false,
  });

  bool get isEditing => card != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frontController = useTextEditingController(
      text: card?.front ?? '',
    );
    final backController = useTextEditingController(
      text: card?.back ?? '',
    );
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final continuousMode = useState(enableContinuousCreation);

    Future<void> handleSave() async {
      if (formKey.currentState?.validate() ?? false) {
        isLoading.value = true;
        try {
          await onSave(
            frontController.text.trim(),
            backController.text.trim(),
          );
          if (context.mounted) {
            if (continuousMode.value && !isEditing) {
              frontController.clear();
              backController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('カードを作成しました'),
                  duration: Duration(seconds: 1),
                ),
              );
            } else {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing ? 'カードを更新しました' : 'カードを作成しました',
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('エラーが発生しました: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          isLoading.value = false;
        }
      }
    }

    return AlertDialog(
      title: Text(isEditing ? 'カードを編集' : '新しいカード'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: frontController,
                decoration: const InputDecoration(
                  labelText: '表面（日本語）',
                  hintText: '例: こんにちは',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '表面を入力してください';
                  }
                  return null;
                },
                autofocus: true,
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: backController,
                decoration: const InputDecoration(
                  labelText: '裏面（英語）',
                  hintText: '例: Hello',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '裏面を入力してください';
                  }
                  return null;
                },
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => handleSave(),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('連続作成モード'),
                  subtitle: const Text('保存後も続けてカードを追加'),
                  value: continuousMode.value,
                  onChanged: (value) {
                    continuousMode.value = value ?? false;
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : handleSave,
          child: isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? '更新' : '作成'),
        ),
      ],
    );
  }
}
