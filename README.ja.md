---
title: .github - Shared Development Infrastructure
description: テックブログ用記事レビュー／校正フレームワーク
---

<!-- textlint-disable ja-technical-writing/ja-no-mixed-period -->

[English](README.md) | 日本語

<!-- textlint-enable -->

## tech-article-reviewer

日本語技術ブログのレビュー・校正フレームワーク。

ChatGPT で使用できる構造化プロンプトシステムを提供します。

## Quick Start

### インストール

1. GitHub 上でこのリポジトリをフォーク (自分用のコピーを作成)

### 使い方

#### 1. リポジトリをローカルにクローン

```bash
git clone https://github.com/<YOUR_USERNAME?/tech-article-reviewer.git
cd tech-article-reviewer
```

フォークすることで、自分専用のプロンプト設定を管理できます。

#### 2. プロンプトの変数を設定

`tech-articles-prompt/` ディレクトリ内の `.prompt` ファイルを開き、変数部分を自分用に編集します。

設定例 (`article-review.prompt`):

```markdown
:theme GHALintを使ったgithub actionsのセキュア化
:target github actionsに関する初心者〜中級者
:goal GHALintを使って、GitHub Actionsの脆弱性スキャンができる
:link \<GHALint公式サイト>
:remark 具体例を多めに
```

設定変数:

| 変数      | 説明                           | 例                                        |
| --------- | ------------------------------ | ----------------------------------------- |
| `:theme`  | ブログのテーマ                 | GHALintを使ったgithub actionsのセキュア化 |
| `:target` | 対象読者層                     | 初心者、中級者、上級者                    |
| `:goal`   | 記事が読者に達成してほしい目標 | 技術記事の品質向上、わかりやすさ重視      |
| `:link`   | 参考リンク                     | スタイルガイドURL、執筆ガイドライン       |
| `:remark` | 特記事項                       | 具体例を多めに、コード例必須              |

注意:
これら以外の変数は変更しないでください。

#### 3. ChatGPT にプロンプトを貼り付けて使用

1. `tech-articles-prompt/` から使いたいプロンプトファイルを開く
2. ファイル全体をコピー
3. ChatGPT の会話に貼り付け
4. プロンプトの指示に従って記事を入力・レビュー

## 利用可能なプロンプト

| ファイル                      | 用途                     |
| ----------------------------- | ------------------------ |
| `article-review.prompt`       | 記事のレビュー・改善提案 |
| `article-proofreading.prompt` | 校正・表記ゆれチェック   |
| `article-writer.prompt`       | 記事執筆支援             |

## プロンプトの基本操作

各プロンプトは 3 モードで動作します:

### コマンドモード (初期状態)

| コマンド | 説明                                  |
| -------- | ------------------------------------- |
| `/begin` | 入力モード開始 (記事を貼り付ける準備) |

### 入力モード

- 記事内容を貼り付け
- `/end` で入力完了、レビューモード/ライターモードへ移行

### レビューモード

| コマンド               | 説明                       |
| ---------------------- | -------------------------- |
| `/review`              | レビュー結果の全体表示     |
| `/review [セクション]` | 特定セクションのみ表示     |
| '/write [セクション]`  | 指定セクションの本文を記述 |
| `/exit`                | モード終了、最初に戻る     |

## ライセンス

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx

## 開発者向け情報

プロンプトの改良、フレームワークへの貢献をお考えのほうは **[CLAUDE.md](./CLAUDE.md)** を参照してください。

- 技術スタック
- リポジトリ構造
- 開発ワークフロー
- コーディング規約
- CI/CD 設定
