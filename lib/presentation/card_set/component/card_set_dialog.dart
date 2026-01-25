import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/card_set_model.dart';

/// カードセット作成・編集ダイアログ
class CardSetDialog extends HookConsumerWidget {
  final CardSetModel? cardSet;
  final Future<void> Function(String title, String description) onSave;

  const CardSetDialog({super.key, this.cardSet, required this.onSave});

  bool get isEditing => cardSet != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(
      text: cardSet?.title ?? '',
    );
    final descriptionController = useTextEditingController(
      text: cardSet?.description ?? '',
    );
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);

    return AlertDialog(
      title: Text(isEditing ? 'カードセットを編集' : '新しいカードセット'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  hintText: '例: 英単語帳',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明（任意）',
                  hintText: 'このカードセットの説明...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: isLoading.value
              ? null
              : () async {
                  if (formKey.currentState?.validate() ?? false) {
                    isLoading.value = true;
                    try {
                      await onSave(
                        titleController.text.trim(),
                        descriptionController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing ? 'カードセットを更新しました' : 'カードセットを作成しました',
                            ),
                          ),
                        );
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
                },
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
