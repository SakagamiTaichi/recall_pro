# RecallPro - 開発ガイドライン

## プロジェクト概要

フラッシュカード学習アプリケーション（Flutter + Firebase）

## フォルダ構成

```
lib/
├── auth/                          # 認証機能
│   ├── auth_service.dart          # 認証サービスクラス
│   ├── auth_service.g.dart        # 生成ファイル
│   └── auth_wrapper.dart          # 認証状態に応じた画面切り替え
│
├── model/                         # データモデル
│   ├── [model_name]_model.dart          # Freezedモデル定義
│   └── [model_name]_model.freezed.dart  # 生成ファイル
│
├── presentation/                  # UI層（フィーチャーベース）
│   └── [feature_name]/
│       ├── component/             # 再利用可能なコンポーネント
│       │   └── [feature]_dialog.dart
│       ├── view/                  # 画面Widget
│       │   └── [feature]_view.dart
│       └── view_model/            # ViewModel
│           ├── [feature]_view_model.dart
│           └── [feature]_view_model.g.dart
│
├── repository/                    # データ層
│   ├── [model]_repository.dart    # Firestoreとの通信
│   └── [model]_repository.g.dart  # 生成ファイル
│
├── theme/                         # テーマ管理
│   ├── app_colors.dart            # 色定義
│   ├── app_theme.dart             # ThemeData定義
│   └── theme_provider.dart        # テーマ状態管理
│
├── utils/                         # ユーティリティ
│   └── [utility_name].dart
│
└── main.dart                      # エントリーポイント
```

## アーキテクチャ

### MVVM + Repository パターン

```
Model（データモデル）
    ↓
Repository（データアクセス抽象化）
    ↓
ViewModel（画面ロジック）
    ↓
View（UI表現）
```

### データフロー

```
Firestore → Repository(Stream) → ViewModel(フィルタリング) → View(AsyncValue.when) → UI
```

## 状態管理

### Riverpod + Flutter Hooks

- **全体状態**: `hooks_riverpod` + `riverpod_annotation`
- **ローカル状態**: `flutter_hooks`
