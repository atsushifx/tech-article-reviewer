# CLAUDE.md

> このファイルは Claude Code への指示であり、開発者向けのプロジェクトガイドです。

## プロジェクト概要

日本語技術ブログのレビュー・校正フレームワーク。4段階モード (コマンド/入力/待機/処理) で動作する構造化プロンプトシステムを提供します。

**対象プラットフォーム**: Windows 10, win32

## コア原則

- プロンプトファイルは、基本的に変更しない: `tech-articles-prompt/*.prompt` は本プロジェクトのコア資産
- 設定は `configs/` に集約: ルート直下ではなく `configs/` ディレクトリ内に配置
- LF 改行必須: Windows 環境でも LF 改行 (dprint/EditorConfig で強制)
- シークレット検出は 2層: gitleaks + secretlint の両方でチェック

## リポジトリ構造

```bash
tech-article-reviewer/
├── configs/                  # 設定ファイル集約
├── docs/dev-guides/          # 詳細ドキュメント
│   ├── prompt-system.md      # プロンプトシステム詳細
│   ├── coding-conventions.md # コーディング規約
│   └── ci-cd.md              # CI/CD詳細
├── tech-articles-prompt/     # プロンプトファイル (コア資産)
│   ├── macro-syntax.md       # マクロ構文仕様 (BNF、共通マクロ含む)
│   ├── article-review.prompt # レビュー用
│   ├── article-proofreading.prompt # 校正用
│   └── article-writer.prompt # 執筆支援用
├── scripts/                  # bashスクリプト
├── temp/                     # 一時ファイル (gitignore対象)
└── dprint.jsonc              # フォーマッタ設定
```

## セットアップ

```bash
# 依存関係のインストール
pnpm install

# Git hooksのセットアップ
pnpm run prepare

# Git設定 (Windows環境)
git config core.autocrlf true
git config --global core.longpaths true
```

## 技術スタック

| カテゴリ            | ツール       | 説明                                   |
| ------------------- | ------------ | -------------------------------------- |
| **Package Manager** | pnpm         | 高速・効率的なパッケージ管理           |
| **Formatter**       | dprint       | 120文字幅、2スペース、シングルクォート |
| **Linters**         | textlint     | 日本語技術文書スタイル検証             |
|                     | markdownlint | Markdown構文検証                       |
| **Security**        | gitleaks     | Gitリポジトリシークレットスキャン      |
|                     | secretlint   | テキストファイルシークレット検出       |
| **Git Hooks**       | lefthook     | 自動コミットメッセージ生成含む         |

## プロンプトシステム

本プロジェクトのコアは `tech-articles-prompt/` ディレクトリ内のプロンプトファイルです。

### 4段階モード構造

```bash
コマンド → (/begin) → 入力 → (/end) → 待機 → (/review|/write) → 処理 → (/exit) → コマンド
```

### 主要コマンド

- `/begin`: 入力モード開始 (`:buffer` クリア)
- `/end`: 待機モード移行 (入力完了)
- `/review`: レビュー/校閲開始 (待機モードから)
- `/write`: 記事生成開始 (待機モードから)
- `/exit`: モード終了、メモリリセット

**詳細**: [`docs/dev-guides/prompt-system.md`](docs/dev-guides/prompt-system.md)

## 開発ワークフロー

### 基本フロー

```bash
# 1. フォーマット
dprint fmt

# 2. 品質チェック (コミット前必須)
pnpm run check:spells         # スペルチェック
pnpm run lint:text            # 日本語リント
pnpm run lint:markdown        # Markdownリント
pnpm run lint:secrets         # シークレット検出

# 3. Git操作
git add .
git commit    # フック自動実行、メッセージ自動生成
git push
```

### Git Hooks自動実行

1. **pre-commit**: シークレットスキャン
2. **prepare-commit-msg**: Conventional Commits 形式メッセージ自動生成
3. **commit-msg**: コミットメッセージ形式検証

**詳細**: [`docs/dev-guides/ci-cd.md`](docs/dev-guides/ci-cd.md)

## AI作業時の注意

### 禁止事項

- `tech-articles-prompt/` 内のプロンプトファイルの安易な変更
- 設定ファイルのルート直下配置 (`configs/` に集約)
- CRLF 改行の使用
- Conventional Commits 形式外のコミットメッセージ

### Windows固有の注意

- Git Bash 必須: `scripts/` 内の bash スクリプト実行時
- LF 改行: Windows 環境でも LF (CR+LF に自動変換しない)
- パス長制限: `core.longpaths true` を設定済み

### 推奨作業手順

1. タスク理解とプランニング
2. 関連ファイルの確認
3. 変更実施
4. フォーマット・リント実行
5. コミット (フック自動実行を確認)

## 詳細ドキュメント

- [プロンプトシステムアーキテクチャ](docs/dev-guides/prompt-system.md)
- [コーディング規約](docs/dev-guides/coding-conventions.md)
- [CI/CD](docs/dev-guides/ci-cd.md)
