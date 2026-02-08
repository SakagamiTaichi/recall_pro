# Liquid Glass Design Skill

このスキルは、Flutter UIコンポーネントを`liquid_glass_renderer`パッケージを使用してモダンなリキッドグラス（グラスモーフィズム）デザインに変換します。

## 📋 概要

- **スキル名**: `liquid-glass`
- **用途**: ダイアログ、ボタン、カード、テキストフィールドなどのFlutter UIコンポーネントをリキッドグラスデザインに変換
- **パッケージ**: [liquid_glass_renderer](https://pub.dev/packages/liquid_glass_renderer)

## 🚀 使い方

### 基本的な使用方法

```bash
/liquid-glass path/to/your/flutter_file.dart
```

### 例

```bash
# 特定のダイアログファイルを変換
/liquid-glass lib/presentation/card_set/component/card_set_dialog.dart

# ボタンコンポーネントを変換
/liquid-glass lib/presentation/components/custom_button.dart

# カード一覧画面を変換
/liquid-glass lib/presentation/card/view/card_list_view.dart
```

## ✨ 機能

このスキルは以下のコンポーネントをリキッドグラスデザインに変換します：

### 1. **ダイアログ (Dialog/AlertDialog)**
- `AlertDialog` → 透明な `Dialog` に変換
- グラデーション背景を追加
- `LiquidGlassLayer` と `LiquidGlass` でラップ
- 丸みを帯びた角（`LiquidRoundedSuperellipse`）

### 2. **ボタン (Button)**
- プライマリボタンとセカンダリボタンで異なるガラス効果
- タップ時のリップルエフェクト（`InkWell`）
- ローディング状態のサポート

### 3. **テキストフィールド (TextField/TextFormField)**
- ボーダーレスデザイン
- ガラス効果の縁が境界線として機能
- バリデーションエラー表示のサポート

### 4. **カード (Card)**
- 複数カードのブレンド効果（`LiquidGlassBlendGroup`）
- 一貫した角の丸み
- 微細なグラデーション背景

## 📦 前提条件

`pubspec.yaml`に`liquid_glass_renderer`パッケージが必要です：

```yaml
dependencies:
  liquid_glass_renderer: ^0.2.0-dev.4
```

## 🎨 デザイン仕様

### グラデーション配色

- **青紫系**: Blue → Purple
- **紫ピンク系**: Purple → Pink
- **インディゴシアン系**: Indigo → Cyan
- **マルチカラー**: Blue → Purple → Pink

### ガラス色の透明度

- `0x11FFFFFF` - 非常に微細（7%）
- `0x22FFFFFF` - ライト（13%）
- `0x33FFFFFF` - ミディアム（20%）
- `0x44FFFFFF` - ストロング（27%）

### 設定プリセット

**控えめなガラス:**
```dart
thickness: 12, blur: 6, glassColor: 0x11FFFFFF
```

**標準ガラス:**
```dart
thickness: 20, blur: 10, glassColor: 0x22FFFFFF
```

**強いガラス:**
```dart
thickness: 30, blur: 15, glassColor: 0x33FFFFFF
```

## ⚠️ パフォーマンス注意事項

- **最大16個のガラスウィジェット**: 1つの`LiquidGlassBlendGroup`内で
- **Impeller必須**: Web、Windows、Linuxは未対応
- **実機テスト推奨**: 本番デプロイ前に必ず実機でテスト
- **軽量版オプション**: 非重要要素には`FakeGlass`を使用

## 📁 ファイル構成

```
.claude/skills/liquid-glass/
├── SKILL.md          # メインスキル定義
├── examples.md       # 実装例とコードサンプル
└── README.md         # このファイル
```

## 🔍 実装例

詳細な実装例は[examples.md](examples.md)を参照してください：

- Dialog変換の前後比較
- ボタンコンポーネントの実装
- テキストフィールドコンポーネントの実装
- カードリストのブレンド効果
- シンプルなガラスカード

## 📚 参考リソース

- [liquid_glass_renderer - pub.dev](https://pub.dev/packages/liquid_glass_renderer)
- [API Documentation](https://pub.dev/documentation/liquid_glass_renderer/latest/)
- [GitHub Demo App](https://github.com/sbis04/liquid_glass_demo)

## 🛠️ トラブルシューティング

### エラー: パッケージが見つからない

```bash
flutter pub add liquid_glass_renderer
```

### エラー: Impellerが有効になっていない

iOS/Androidでは通常デフォルトで有効です。Web/Desktop は現在未対応です。

### パフォーマンスが悪い

- ガラスウィジェットの数を減らす
- `FakeGlass`を使用（軽量版）
- `thickness`と`blur`の値を下げる

## 📝 変更履歴

### v1.0.0 (2026-02-07)
- 初回リリース
- ダイアログ、ボタン、テキストフィールド、カードのサポート
- カラープリセットと設定プリセットの追加
- 実装例の追加

---

**作成者**: Claude Code
**最終更新**: 2026-02-07
