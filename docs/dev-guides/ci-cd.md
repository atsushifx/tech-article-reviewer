# CI/CD

## ワークフロー

### セキュリティスキャン

**ci-scan-all.yml** - セキュリティスキャン統合:

- gitleaks: Git リポジトリシークレットスキャン
- secretlint: テキストファイルシークレット検出

### 静的解析

**codeql-with-actions.yml** - CodeQL 静的解析:

コードの脆弱性を検出し、セキュリティ問題を早期に発見します。

### 依存関係管理

**Dependabot** - 依存関係自動更新:

定期的に依存パッケージの更新をチェックし、プルリクエストを自動作成します。

## ローカル品質チェック

CI/CD で実行されるチェックは、ローカルでも実行できます。

```bash
# スペルチェック
pnpm run check:spells

# 日本語リント
pnpm run lint:text

# Markdownリント
pnpm run lint:markdown

# ファイル名検証
pnpm run lint:filename

# シークレット検出
pnpm run lint:secrets
```

## Git Hooks

lefthook により、以下のフックが自動実行:

1. **pre-commit**: シークレットスキャン（gitleaks + secretlint）
2. **prepare-commit-msg**: Conventional Commits 形式のメッセージ自動生成
3. **commit-msg**: コミットメッセージ形式検証（commitlint）
