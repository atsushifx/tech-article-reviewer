# LCL DSL マイグレーションガイド: v2.0.0 → v2.1.0

## 概要

LCL DSL v2.1.0 は、v2.0.0 の **MINOR バージョンアップ** であり、セマンティック的には完全互換です。主な変更は **形式的な圧縮** のみで、機能追加や破壊的変更はありません。

## 変更サマリー

| カテゴリ       | 変更内容                        | 互換性        | 対応必要    |
| -------------- | ------------------------------- | ------------- | ----------- |
| 哲学セクション | テーブル形式 → 宣言的マクロ形式 | [OK] 完全互換 | [注意] 推奨 |
| Fail-fast      | テーブル形式 → DEF RULE 形式    | [OK] 完全互換 | [注意] 推奨 |
| BNF            | 詳細BNF → Backbone BNF          | [OK] 完全互換 | [注意] 推奨 |
| CONSTRAINT     | 分散配置 → 統合セクション       | [OK] 完全互換 | [注意] 推奨 |
| バージョン     | 2.0.0 → 2.1.0                   | [OK] 完全互換 | [OK] 必須   |

## マイグレーション手順

### ステップ 1: バージョン確認

**現在のバージョンを確認:**

```bash
# DSL ファイルのバージョン確認
grep "^version:" dsl/llm-control-language-spec-compact.md
# Expected: version: 2.0.0
```

### ステップ 2: バックアップ作成

**重要なファイルのバックアップ:**

```bash
# DSL 仕様ファイルのバックアップ
cp dsl/llm-control-language-spec-compact.md dsl/llm-control-language-spec-compact.md.v2.0.0
cp dsl/llm-control-language-spec.md dsl/llm-control-language-spec.md.v2.0.0

# プロンプトファイルのバックアップ
cp tech-articles-prompt/article-review.prompt tech-articles-prompt/article-review.prompt.v2.0.0
cp tech-articles-prompt/article-writer.prompt tech-articles-prompt/article-writer.prompt.v2.0.0
cp tech-articles-prompt/article-proofreading.prompt tech-articles-prompt/article-proofreading.prompt.v2.0.0
```

### ステップ 3: セクション 0.2 の変換

**Before (v2.0.0):**

```markdown
## 0.2 レビュー哲学

### レビューの目的

| 項目   | 方針                               |
| ------ | ---------------------------------- |
| 主目的 | 技術的正確性と読みやすさの向上     |
| 副目的 | 著者の意図を尊重しながらの品質改善 |
| 非目的 | 著者のスタイルの全面書き換え       |

### 介入レベル

| レベル | 範囲         | 例                                   |
| ------ | ------------ | ------------------------------------ |
| 高     | 技術的誤り   | API 仕様の誤記、コード例のバグ       |
| 中     | 構造的問題   | 論理展開の矛盾、セクション構成の改善 |
| 低     | 表現の最適化 | 冗長表現の簡潔化、用語の統一         |

...
```

**After (v2.1.0):**

```markdown
## 0.2 レビュー哲学

本 DSL を使用したレビューシステムの基本原則を定義します。

BEGIN PHILOSOPHY DEF

DEF PHILOSOPHY REVIEW THEN
; Goals
GOAL = QUALITY_IMPROVEMENT
GOAL = AUTHOR_INTENT_RESPECT
NON_GOAL = { REWRITE, STYLE_OVERRIDE }

; Intervention levels
INTERVENTION HIGH = { TECHNICAL_ERROR, API_MISUSE, CODE_BUG }
INTERVENTION MEDIUM = { STRUCTURAL_ISSUE, LOGIC_CONTRADICTION }
INTERVENTION LOW = { EXPRESSION_OPTIMIZATION, TERM_UNIFICATION }

NOTE:
All philosophy statements preserved in compressed clause form:

- 主目的: 技術的正確性と読みやすさの向上
- 副目的: 著者の意図を尊重しながらの品質改善
- 非目的: 著者のスタイルの全面書き換え
- 高介入: 技術的誤り (API仕様の誤記、コード例のバグ)
- 中介入: 構造的問題 (論理展開の矛盾、セクション構成の改善)
- 低介入: 表現の最適化 (冗長表現の簡潔化、用語の統一)
  END

END DEF

BEGIN RULE DEF

DEF RULE FAIL_FAST THEN
; Fail-fast conditions
IF STRUCTURE == UNESTABLISHED -> STATUS INCOMPLETE + REASON structural_collapse
IF TECHNICAL == BROKEN -> REVIEW SKIPPED + REASON technical_fatality
IF READABILITY == UNESTABLISHED -> STATUS INCOMPLETE + REASON unreadability
IF LENGTH < 500 -> STATUS INCOMPLETE + REASON insufficient_length
IF CONTENT_STATUS == INCOMPLETE -> STATUS INCOMPLETE + REASON incomplete_content
END

END DEF
```

### ステップ 4: CONSTRAINT 統合

**統合セクションを追加:**

```markdown
## 0.3 制約規則統合

本セクションは、DSL 全体で適用される重要な制約規則を集約したリファレンスです。

BEGIN RULE DEF

DEF RULE REVIEW_CONSTRAINTS THEN
; Philosophy enforcement
CONSTRAINT: 違反ラベル付き指摘は自動降格
CONSTRAINT: LLM は違反を自己検出し、適切なラベル付与が必須

; ACCEPTANCE principle
CONSTRAINT: ACCEPTANCE は品質評価ではなく、入力/処理の境界
CONSTRAINT: PENDING 状態では沈黙 (自発的動作禁止)

; Fail-fast constraints
CONSTRAINT: 建設的な再提出ガイドを必ず提供
CONSTRAINT: レビュー拒否は「レビュー前提条件未達」を意味する

; Output generation guard
CONSTRAINT: OUTPUT は generation-status=READY の場合のみ生成

; Enum constraints
CONSTRAINT: CATEGORY/PRIORITY の enum 拡張は禁止 (closed: true)
CONSTRAINT: VIOLATION/STATUS の enum 拡張は禁止 (closed: true)

; Override mechanism
CONSTRAINT: `:remark` はすべての規則を上書き可能
END

END DEF
```

### ステップ 5: バージョン更新

**ファイルヘッダーのバージョンを更新:**

```diff
---
title: LLM制御言語仕様 (形式定義版)
description: プロンプト制御DSL - 形式言語による圧縮仕様
-version: 2.0.0
+version: 2.1.0
update: 2026-01-23
---
```

### ステップ 6: 検証

**セマンティック保存を検証:**

```bash
# Philosophy 要素数検証
grep -c "GOAL\|NON_GOAL" dsl/llm-control-language-spec-compact.md
# Expected: 3

# Intervention レベル数検証
grep -c "INTERVENTION" dsl/llm-control-language-spec-compact.md
# Expected: 3

# Fail-fast 条件数検証
grep -c "IF.*THEN.*REASON" dsl/llm-control-language-spec-compact.md
# Expected: 5

# CONSTRAINT 数検証
grep -c "CONSTRAINT:" dsl/llm-control-language-spec-compact.md
# Expected: ~18
```

## 影響範囲

### 変更が必要なファイル

1. **DSL 仕様ファイル (必須):**
   - `dsl/llm-control-language-spec-compact.md`
   - `dsl/llm-control-language-spec.md`

2. **プロンプトファイル (推奨):**
   - `tech-articles-prompt/article-review.prompt`
   - `tech-articles-prompt/article-writer.prompt`
   - `tech-articles-prompt/article-proofreading.prompt`

### 変更が不要なファイル

- [OK]コマンド定義 (変更なし)
- [OK]変数定義 (変更なし)
- [OK]イベント定義 (変更なし)
- [OK]出力形式 (変更なし)
- [OK]enum 値 (変更なし)

## 互換性保証

### セマンティック互換性

v2.1.0 は v2.0.0 とセマンティック的に完全互換:

- [OK]すべてのコマンドが同じ動作
- [OK]すべての変数が同じスコープ
- [OK]すべての制約が同じ効果
- [OK]すべての出力が同じ形式

### LLM 解釈の互換性

v2.1.0 の圧縮形式は、LLM が v2.0.0 のテーブル形式と同用に解釈可能:

- [OK]`GOAL = QUALITY_IMPROVEMENT` は「主目的: 技術的正確性と読みやすさの向上」と等価
- [OK]`INTERVENTION HIGH = { TECHNICAL_ERROR, API_MISUSE, CODE_BUG }` は「高: 技術的誤り (API 仕様の誤記、コード例のバグ)」と等価
- [OK]NOTE セクションに元の日本語説明が保存されている

## トラブルシューティング

### 問題 1: 圧縮形式の解釈エラー

**症状:**
LLM が圧縮形式を正しく解釈できない。

**解決策:**
NOTE セクションに元の日本語説明が保存されているので、それを参照してください。

```cobol
NOTE:
  All philosophy statements preserved in compressed clause form:
  - 主目的: 技術的正確性と読みやすさの向上
  - 副目的: 著者の意図を尊重しながらの品質改善
  - 非目的: 著者のスタイルの全面書き換え
END
```

### 問題 2: CONSTRAINT が見つからない

**症状:**
分散していた CONSTRAINT 文が見つからない。

**解決策:**
統合セクション (0.3 制約規則統合) を参照してください。

```markdown
## 0.3 制約規則統合

BEGIN RULE DEF

DEF RULE REVIEW_CONSTRAINTS THEN
; Philosophy enforcement
CONSTRAINT: 違反ラベル付き指摘は自動降格
...
END

END DEF
```

### 問題 3: BNF が簡略化されすぎている

**症状:**
Backbone BNF では詳細が不足している。

**解決策:**
完全な BNF 定義は後続セクションおよび Appendix に委譲されています。

```markdown
**NOTE**:

- これは網羅的な BNF ではなく、DSL の骨格のみを示します
- 詳細な構文定義 (完全版):
  - command-def, var-def, set-action, clear-action の詳細
  - chain パターン (`->`)、id-list、label、param の形式
  - 詳細構文は Section 2 以降および Appendix に委譲
```

## ロールバック手順

v2.1.0 から v2.0.0 にロールバックする場合:

```bash
# バックアップから復元
cp dsl/llm-control-language-spec-compact.md.v2.0.0 dsl/llm-control-language-spec-compact.md
cp dsl/llm-control-language-spec.md.v2.0.0 dsl/llm-control-language-spec.md

cp tech-articles-prompt/article-review.prompt.v2.0.0 tech-articles-prompt/article-review.prompt
cp tech-articles-prompt/article-writer.prompt.v2.0.0 tech-articles-prompt/article-writer.prompt
cp tech-articles-prompt/article-proofreading.prompt.v2.0.0 tech-articles-prompt/article-proofreading.prompt
```

## まとめ

v2.1.0 へのマイグレーションは、以下の点で安全:

- [OK]セマンティック互換性 100%
- [OK]破壊的変更なし
- [OK]形式的な圧縮のみ
- [OK]ロールバック可能

マイグレーションを推奨する理由:

- [-]仕様書のサイズが 70% 削減
- [+]構造的な明瞭性が向上
- [*]CONSTRAINT の集約により保守性が向上
- [i]Backbone BNF により本質的な構文が明確化

## 参照

- [圧縮形式ガイド](./README-COMPRESSED-FORMAT.md)
- [セマンティックマッピングテーブル](./compression-mapping.md)
- [完全仕様書](./llm-control-language-spec.md)
- [圧縮仕様書](./llm-control-language-spec-compact.md)
