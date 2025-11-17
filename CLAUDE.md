# CLAUDE.md

> このファイルは Claude Code (claude.ai/code) への指示であり、同時に開発者向けのプロジェクトガイドです。

## 目次

- [プロジェクト概要](#プロジェクト概要)
- [リポジトリ構造](#リポジトリ構造)
- [セットアップ手順](#セットアップ手順)
- [技術スタック](#技術スタック)
- [プロンプトシステムアーキテクチャ](#プロンプトシステムアーキテクチャ)
- [開発ワークフロー](#開発ワークフロー)
- [コーディング規約](#コーディング規約)
- [CI/CD](#cicd)
- [AI作業時の注意](#ai作業時の注意)

## プロジェクト概要

日本語技術ブログのレビュー・校正フレームワーク。3 モード（コマンド/入力/レビュー）で動作する構造化プロンプトシステムを提供します。

**対象プラットフォーム**: Windows 10, win32

### コア原則

- プロンプトファイルを変更しない: `tech-articles-prompt/*.prompt` は本プロジェクトのコア資産、変更時は慎重に
- 設定は `configs/` に集約: ルート直下ではなく `configs/` ディレクトリ内に配置
- 日本語文書ルール厳守: textlint で定義された日本語技術文書スタイルに従う
- LF 改行必須: Windows 環境でも LF 改行（dprint/EditorConfig で強制）
- シークレット検出は 2層: gitleaks + secretlint の両方でチェック

## リポジトリ構造

```bash
tech-article-reviewer/
├── .claude/                      # Claude Code設定
│   └── agents/                   # カスタムエージェント定義
│       └── commit-message-generator.md
├── .github/                      # GitHub設定
│   ├── dependabot.yml            # 依存関係自動更新設定
│   └── workflows/                # GitHub Actions
│       ├── ci-scan-all.yml       # セキュリティスキャン統合
│       └── codeql-with-actions.yml  # CodeQL静的解析
├── .vscode/                      # VSCode設定
│   ├── cspell.json               # スペルチェック設定
│   └── cspell/dicts/             # プロジェクト固有辞書
│       └── project.dic
├── configs/                      # 各種ツール設定（集約）
│   ├── .markdownlint.yaml        # Markdownリント設定
│   ├── .textlint/                # textlint設定
│   │   ├── allowlist.yml         # 許可リスト
│   │   └── dict/                 # 辞書ファイル
│   │       ├── prh-atsushifx.yml # atsushifx固有辞書
│   │       ├── prh.yml           # 一般辞書
│   │       └── smarthr/          # SmartHR辞書
│   ├── commitlint.config.js      # コミットメッセージ検証
│   ├── gitleaks.toml             # gitleaks設定
│   ├── secretlint.config.yaml    # secretlint設定
│   └── textlintrc.yaml           # textlintメイン設定
├── scripts/                      # スクリプト（bash）
│   └── prepare-commit-msg.sh     # コミットメッセージ生成フック
├── tech-articles-prompt/         # プロンプトファイル（コア資産）
│   ├── article-proofreading.prompt  # 校正用プロンプト
│   ├── article-review.prompt        # レビュー用プロンプト
│   └── article-writer.prompt        # 執筆支援プロンプト
├── temp/                         # 一時ファイル（gitignore対象）
│   └── idd/                      # Issue-Driven Development作業用
│       ├── issues/               # Issue下書き
│       └── pr/                   # PR下書き
├── .editorconfig                 # エディタ設定
├── .gitignore                    # Git除外設定
├── CLAUDE.md                     # 本ファイル（AI・開発者向けガイド）
├── dprint.jsonc                  # dprintフォーマッタ設定
├── lefthook.yml                  # Git hooks設定
├── LICENSE                       # MITライセンス（英語）
├── LICENSE.ja                    # MITライセンス（日本語）
├── package.json                  # npm/pnpm設定
├── pnpm-lock.yaml                # pnpm依存関係ロック
└── README.md                     # プロジェクト概要
```

### ディレクトリの役割

| ディレクトリ            | 説明                                                     |
| ----------------------- | -------------------------------------------------------- |
| `.claude/`              | Claude Code固有設定（エージェント定義など）              |
| `.github/`              | GitHub Actions、Dependabot設定                           |
| `configs/`              | **すべての設定ファイルを集約**（ルート直下に配置しない） |
| `scripts/`              | bashスクリプト（Git Bash必須）                           |
| `tech-articles-prompt/` | **コア資産**：プロンプトファイル（変更は慎重に）         |
| `temp/`                 | 一時作業ファイル（gitignore対象）                        |

## セットアップ手順

### 初回セットアップ

```bash
# 依存関係のインストール
pnpm install

# Git hooksのセットアップ
pnpm run prepare
```

### Git設定（Windows環境）

```bash
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
|                     | ls-lint      | ファイル名規約検証                     |
| **Security**        | gitleaks     | Gitリポジトリシークレットスキャン      |
|                     | secretlint   | テキストファイルシークレット検出       |
| **Git Hooks**       | lefthook     | 自動コミットメッセージ生成含む         |

## プロンプトシステムアーキテクチャ

`tech-articles-prompt/` ディレクトリ内のプロンプトファイルが本フレームワークのコアです。

### 変数システム

- `:buffer` - 記事内容を保持
- `:review` - レビュー結果を保持

### コマンド構文

| コマンド                      | 説明                                 |
| ----------------------------- | ------------------------------------ |
| `/begin`                      | 入力モード開始（`:buffer` クリア）   |
| `/end`                        | レビューモード開始（記事をレビュー） |
| `/review [指示] [セクション]` | 特定セクションのレビュー表示         |
| `/exit`                       | モード終了、メモリリセット           |

### パース構文

- `#` - セクション開始
- `:variable` - 変数定義
- `""""` - 入力区切り
- `;` - コメント（処理前に削除）

## 開発ワークフロー

### 1. 変更実施

コードやドキュメントを変更します。

### 2. フォーマット

```bash
dprint fmt
```

### 3. 品質チェック（コミット前必須）

```bash
pnpm run check:spells         # スペルチェック
pnpm run lint:text            # 日本語リント
pnpm run lint:markdown        # Markdownリント
pnpm run lint:filename        # ファイル名検証
pnpm run lint:secrets         # シークレット検出
```

### 4. Git操作

```bash
git add .
git commit    # フック自動実行、メッセージ自動生成
git push
```

### Git Hooksの自動実行内容

1. **pre-commit**: シークレットスキャン（gitleaks + secretlint）
2. **prepare-commit-msg**: Conventional Commits 形式のメッセージ自動生成（Codex CLI 経由）
3. **commit-msg**: コミットメッセージ形式検証（commitlint）

## コーディング規約

### Conventional Commits

**標準タイプ**:

- `feat` - 新機能
- `fix` - バグ修正
- `docs` - ドキュメント変更
- `test` - テスト追加・修正
- `refactor` - リファクタリング
- `perf` - パフォーマンス改善
- `ci` - CI 設定変更
- `chore` - その他の変更

**独自タイプ**:

- `config` - 設定ファイル変更
- `release` - リリース
- `merge` - マージコミット
- `build` - ビルドシステム変更
- `style` - コードスタイル変更
- `deps` - 依存関係更新

**制約**:

- ヘッダー最大 72 文字
- スコープは任意

### 日本語文書ルール

textlint による技術文書スタイル:

- 最大文長: 100 文字
- 最大連続漢字: 8 文字
- 見出し: である調
- 本文: ですます調
- 半角全角間にスペース必須
- 独自辞書: `https://atsushifx.github.io/proof-dictionary/`

### コードフォーマット

- 最大行幅: 120 文字
- インデント: 2 スペース
- 文字列: シングルクォート
- 改行: LF（CRLF 禁止）

### ファイル名規約

ls-lint で定義された命名規則に従います。詳細は `configs/.ls-lint.yml` を参照してください。

## CI/CD

### ワークフロー

- **ci-scan-all.yml** - セキュリティスキャン統合（gitleaks, secretlint）
- **codeql-with-actions.yml** - CodeQL 静的解析
- **Dependabot** - 依存関係自動更新

## AI作業時の注意

### 禁止事項

- `tech-articles-prompt/` 内のプロンプトファイルの安易な変更
- 設定ファイルのルート直下配置（`configs/` に集約）
- CRLF 改行の使用
- テストなしのコミット（該当する場合）
- Conventional Commits 形式外のコミットメッセージ

### Windows固有の注意

- Git Bash 必須: `scripts/` 内の bash スクリプト実行時
- LF 改行: Windows 環境でも LF（CR+LF に自動変換しない）
- パス長制限: `core.longpaths true` を設定済み

### 推奨される作業手順

1. タスク理解とプランニング
2. 関連ファイルの確認
3. 変更実施
4. フォーマット・リント実行
5. テスト実行（該当する場合）
6. コミット（フック自動実行を確認）
