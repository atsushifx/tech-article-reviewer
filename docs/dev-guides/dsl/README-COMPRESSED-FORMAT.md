# LCL DSL 圧縮形式ガイド

## 概要

LCL DSL v2.1.0 では、冗長なテーブル形式から圧縮された宣言的マクロ形式への変換を実施しました。
この変換により、セマンティック情報を 100% 保持しながら、構造的な明瞭性と保守性を向上させています。

## 圧縮の原則

### 1. 哲学を宣言的マクロ化

**Before (v2.0.0)**: 4つのテーブル形式 (~80 行)

| 項目   | 方針                               |
| ------ | ---------------------------------- |
| 主目的 | 技術的正確性と読みやすさの向上     |
| 副目的 | 著者の意図を尊重しながらの品質改善 |
| 非目的 | 著者のスタイルの全面書き換え       |

**After (v2.1.0)**: 単一の `DEF PHILOSOPHY` マクロ (~20 行)

```COBOL
DEF PHILOSOPHY REVIEW THEN
  GOAL        = QUALITY_IMPROVEMENT
  GOAL        = AUTHOR_INTENT_RESPECT
  NON_GOAL    = { REWRITE, STYLE_OVERRIDE }

  NOTE: 詳細な日本語説明は NOTE セクションに保存
END
```

### 2. 制約をフェイルルール化

**Before**: Fail-fast 条件テーブル + 出力例 (~25 行)

| 条件         | 判定基準                             |
| ------------ | ------------------------------------ |
| 構造崩壊     | 見出し階層の破綻、必須セクション欠落 |
| 技術的致命性 | 実行不可コード、API誤用の連鎖        |

**After**: `DEF RULE FAIL_FAST` マクロ (~10 行)

```cobol
DEF RULE FAIL_FAST THEN
  IF STRUCTURE      == UNESTABLISHED -> STATUS INCOMPLETE + REASON structural_collapse
  IF TECHNICAL      == BROKEN        -> REVIEW SKIPPED    + REASON technical_fatality
  IF READABILITY    == UNESTABLISHED -> STATUS INCOMPLETE + REASON unreadability
  IF LENGTH         < 500            -> STATUS INCOMPLETE + REASON insufficient_length
  IF CONTENT_STATUS == INCOMPLETE    -> STATUS INCOMPLETE + REASON incomplete_content
END
```

### 3. "正姿勢BNF" (Backbone BNF)

**Before**: ~105 BNF 生成規則 (~150 行)

**After**: ~15 本質的なバックボーン規則 (~40 行)

```bnf
; Core Macro Structure
<macro>  ::= DEF <target> THEN <body> END
<target> ::= ACCEPTANCE <mode-list> | /<command> | VAR <scope> :<var> | RULE <name>
<body>   ::= [<action> [-> <action>]] [NOTE:..] [CONSTRAINT:..]

; Core Modes
<mode>   ::= PENDING | ACTIVE
<scope>  ::= SESSION | REVIEW
<status> ::= DRAFT | INCOMPLETE | READY
```

## セマンティック保存メカニズム

### NOTE セクションの活用

圧縮形式では、元の詳細な日本語説明を `NOTE:` セクションに保存することで、セマンティック情報を 100% 保持しています。

```COBOL
DEF PHILOSOPHY REVIEW THEN
  GOAL = QUALITY_IMPROVEMENT

NOTE:
  All philosophy statements preserved in compressed clause form:
  - 主目的: 技術的正確性と読みやすさの向上
  - 副目的: 著者の意図を尊重しながらの品質改善
  - 非目的: 著者のスタイルの全面書き換え
END
```

### 構造化コメント

圧縮形式では、構造化コメント (`;`) を使用してセクションを明確に区分します。

```COBOL
DEF PHILOSOPHY REVIEW THEN
  ; Goals
  GOAL        = QUALITY_IMPROVEMENT

  ; Intervention levels
  INTERVENTION HIGH   = { TECHNICAL_ERROR, API_MISUSE, CODE_BUG }

  ; Tone boundaries
  TONE UPPER = { TECHNICAL_ERROR_EXPLICIT, CONCRETE_ALTERNATIVE }
END
```

## 読みやすさの向上

### デコンプレス例

圧縮形式から元のテーブル形式への逆マッピング例:

**圧縮形式:**

```COBOL
GOAL        = QUALITY_IMPROVEMENT
GOAL        = AUTHOR_INTENT_RESPECT
NON_GOAL    = { REWRITE, STYLE_OVERRIDE }
```

**対応するテーブル (参考):**

| 項目   | 方針                               |
| ------ | ---------------------------------- |
| 主目的 | 技術的正確性と読みやすさの向上     |
| 副目的 | 著者の意図を尊重しながらの品質改善 |
| 非目的 | 著者のスタイルの全面書き換え       |

### インライン展開

圧縮形式の `{}` 記法は、複数の関連要素を簡潔に表現します。

```cobol
INTERVENTION HIGH = { TECHNICAL_ERROR, API_MISUSE, CODE_BUG }
```

**展開形:**

- 技術的誤り (TECHNICAL_ERROR)
- API 仕様の誤記 (API_MISUSE)
- コード例のバグ (CODE_BUG)

## 圧縮メトリクス

| セクション  | v2.0.0  | v2.1.0   | 削減率 |
| ----------- | ------- | -------- | ------ |
| 哲学        | ~80行   | ~20行    | 75%    |
| Fail-fast   | ~25行   | ~10行    | 60%    |
| BNF         | ~150行  | ~40行    | 73%    |
| 全体 (圧縮) | 836行   | ~250行   | 70%    |
| 全体 (完全) | 2,552行 | ~1,800行 | 30%    |

## ベストプラクティス

### 1. 階層構造の維持

圧縮形式でも、明確な階層構造を維持します。

```COBOL
BEGIN PHILOSOPHY DEF
  DEF PHILOSOPHY REVIEW THEN
    ; Level 1: Goals
    GOAL = ...

    ; Level 2: Intervention levels
    INTERVENTION HIGH = ...
  END
END DEF
```

### 2. NOTE の戦略的使用

`NOTE:` は以下の目的で使用します。

- 元のテーブル内容の保存
- 判定基準の詳細説明
- 例外ケースの記述

### 3. CONSTRAINT の集約

分散していた CONSTRAINT 文を `DEF RULE REVIEW_CONSTRAINTS` に集約し、クイックリファレンスとして機能させます。

## 互換性

圧縮形式 (v2.1.0) は、セマンティック的に v2.0.0 と完全互換です。形式的な変換のみで、意味論的な変更はありません。

## 参照

- [セマンティックマッピングテーブル](./compression-mapping.md)
- [マイグレーションガイド](./MIGRATION-v2.0-to-v2.1.md)
- [完全仕様書](../../../dsl/llm-control-language-spec.md)
- [圧縮仕様書](../../../dsl//llm-control-language-spec-compact.md)
