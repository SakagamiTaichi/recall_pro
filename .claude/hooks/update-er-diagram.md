---
name: update-er-diagram-hook
on:
  - PostToolUse
match:
  tool: [Edit, Write]
  file_pattern: "lib/model/*_model.dart"
---

モデルファイルが変更されました: **{{tool_input.file_path}}**

ER図ドキュメント（docs/er-diagram.md）の該当エンティティのみを更新する必要があります。

**効率化**: 変更されたファイルに対応するエンティティのみを更新してください。全モデルを再解析する必要はありません。

update-er-diagram エージェントを Task として起動し、差分更新を実行してください。

**重要**:
- メインコンテキストを節約するため、必ず Task ツールを使用
- 変更されたファイル名を prompt に含める
- Subagent は該当エンティティのみを更新

実行コマンド:
```
Task tool を使用:
- subagent_type: "update-er-diagram"
- description: "Update ER diagram"
- prompt: "変更されたファイル: {{tool_input.file_path}} - このファイルのモデル定義のみを読み込み、docs/er-diagram.md の該当エンティティ部分のみを更新してください。他のエンティティは変更しないでください。"
- model: "haiku"
```

実行後、「ER図を更新しました（{{tool_input.file_path}}）」と簡潔に報告してください。
