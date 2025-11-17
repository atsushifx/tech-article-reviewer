# 🤝 コントリビューションガイドライン

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark,prh -->
このプロジェクトへの貢献をご検討いただき、ありがとうございます!
皆さまのご協力により、よりよいプロジェクトを築いていけることを願っております。
<!-- textlint-enable -->

## 📝 貢献の方法

### 1. Issue の建て方

バグ報告や機能提案は、[Issue](https://github.com/atsushifx/tech-article-reviewer/issues) にてお願いします。

#### Issue を建てる前に

- 既存の Issue を検索し、同様の報告がないか確認してください。
- 重複を避けることで、問題をスムーズに解決できます。

#### Issue の種類

本プロジェクトでは、以下の種類の Issue を受け付けています。

- **バグ報告** - 動作不良や予期しない挙動を報告
- **機能提案** - 新機能や改善案を提案
- **ドキュメント改善** - ドキュメントの誤りや改善提案
- **質問** - 使い方や仕様についての質問

#### Issue に含めるべき情報

**バグ報告の場合**:

- 再現手順（できるだけ詳細に）
- 期待される動作
- 実際の動作
- 環境情報（OS、Node.js バージョンなど）
- エラーメッセージやスクリーンショット

**機能提案の場合**:

- 提案する機能の概要
- 実現したいユースケース
- 既存機能との関係
- 実装案（あれば）

### 2. プルリクエストの提出

#### 基本的なワークフロー

1. **リポジトリのフォーク**

   GitHub 上でリポジトリをフォークします。

2. **ローカルにクローン**

   ```bash
   git clone https://github.com/<YOUR_USERNAME>/tech-article-reviewer.git
   cd tech-article-reviewer
   ```

3. **ブランチの作成**

   機能追加やバグ修正ごとに、わかりやすい名前でブランチを作成します:

   ```bash
   git checkout -b feature/your-feature-name
   # または
   git checkout -b fix/bug-description
   ```

4. **開発環境のセットアップ**

   ```bash
   pnpm install
   pnpm run prepare
   ```

5. **変更の実施**

   - コードやドキュメントを変更します。
   - コミットメッセージは [Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/) に従ってください。
   - 1 機能ごとにコミットすることを推奨します。

6. **品質チェック**

   コミット前に以下のコマンドで品質を確認してください:

   ```bash
   dprint fmt                  # フォーマット
   pnpm run check:spells       # スペルチェック
   pnpm run lint:text          # 日本語リント
   pnpm run lint:markdown      # Markdown リント
   pnpm run lint:filename      # ファイル名検証
   pnpm run lint:secrets       # シークレット検出
   ```

7. **コミットとプッシュ**

   ```bash
   git add .
   git commit    # Git hooks が自動実行されます
   git push origin feature/your-feature-name
   ```

8. **プルリクエストの作成**

   - GitHub 上でプルリクエストを作成します。
   - タイトルには変更の概要を 1 行で記述してください。
   - 本文には以下を含めてください:
     - 変更の目的と背景
     - 変更内容の詳細
     - 関連する Issue 番号（あれば `#123` の形式で）
     - テスト方法や確認事項

#### プルリクエストのガイドライン

- `main` ブランチに対してプルリクエストを作成してください。
- 1 つのプルリクエストでは 1 つの機能や修正に集中してください。
- レビュアーからのフィードバックには、できるだけ早く対応してください。
- CI チェックがすべて通過していることを確認してください。

## 🛠️ プロジェクト環境

### 技術スタック

| カテゴリ            | ツール       | 説明                                   |
| ------------------- | ------------ | -------------------------------------- |
| **Package Manager** | pnpm         | 高速・効率的なパッケージ管理           |
| **Formatter**       | dprint       | 120 文字幅、2 スペース、シングルクォート |
| **Linters**         | textlint     | 日本語技術文書スタイル検証             |
|                     | markdownlint | Markdown 構文検証                      |
|                     | ls-lint      | ファイル名規約検証                     |
| **Security**        | gitleaks     | Git リポジトリシークレットスキャン     |
|                     | secretlint   | テキストファイルシークレット検出       |
| **Git Hooks**       | lefthook     | 自動コミットメッセージ生成含む         |

### コーディング規約

#### Conventional Commits

コミットメッセージは以下の形式に従ってください。

```text
<type>(<scope>): <subject>

<body>
```

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

#### 日本語文書ルール

textlint による技術文書スタイル:

- 最大文長: 100 文字
- 最大連続漢字: 8 文字
- 見出し: である調
- 本文: ですます調
- 半角全角間にスペース必須
- 独自辞書: `https://atsushifx.github.io/proof-dictionary/`

#### コードフォーマット

- 最大行幅: 120 文字
- インデント: 2 スペース
- 文字列: シングルクォート
- 改行: LF（CRLF 禁止）

### Windows 環境での注意事項

本プロジェクトは Windows 環境をメインターゲットとしています。

- Git Bash 必須: `scripts/` 内の bash スクリプト実行時
- LF 改行: Windows 環境でも LF（CR+LF に自動変換しない）
- パス長制限: `core.longpaths true` を設定済み

Git 設定:

```bash
git config core.autocrlf true
git config --global core.longpaths true
```

### プロンプトファイルの編集について

`tech-articles-prompt/` ディレクトリ内のプロンプトファイルは、本プロジェクトのコア資産です。

- 変更時は慎重に検討してください。
- 大きな変更の場合は、必ず Issue で議論してから実施してください。
- 変数システムやコマンド構文の変更は、既存ユーザーへの影響を考慮してください。

## 行動規範

すべてのコントリビューターは、[行動規範](CODE_OF_CONDUCT.ja.md) を遵守してください。

## 参考資料

- [CLAUDE.md](./CLAUDE.md) - AI・開発者向けプロジェクトガイド
- [README.md](./README.md) - プロジェクト概要
- [Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/)
- [GitHub Docs: リポジトリコントリビューターのためのガイドラインを定める](https://docs.github.com/ja/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)

---

## 📬 クイックリンク

<!-- textlint-disable @textlint-ja/ai-writing/no-ai-list-formatting -->
- [🐛 バグ報告を作成する](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=bug_report.yml)
- [✨ 機能提案を作成する](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=feature_request.yml)
- [📄 ドキュメント改善を報告する](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=documentation_improvement.yml)
- [❓ 質問する](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=question.yml)
- [💬 自由トピックを投稿する](https://github.com/atsushifx/tech-article-reviewer/issues/new?template=open_topic.yml)
- [🔀 Pull Request を作成する](https://github.com/atsushifx/tech-article-reviewer/compare)
<!-- textlint-enable -->

---

## 🤖 Powered by

このプロジェクトのドキュメントや運営は、次の AI エージェント達に支えられています。

- **Elpha**（エルファ・ノクス）- クールで正確なサポート
- **Kobeni**（小紅）- 優しく寄り添うアシスト
- **Tsumugi**（つむぎ）- 明るく元気なフォロー

みんなで、よりよいコントリビューション体験を目指しています。
