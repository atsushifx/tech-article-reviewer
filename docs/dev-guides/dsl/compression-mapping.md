# LCL DSL セマンティックマッピングテーブル

<!-- markdownlint-disable line-length -->

## 概要

本ドキュメントは、LCL DSL v2.0.0 (テーブル形式) から v2.1.0 (圧縮形式) への双方向マッピングを定義します。セマンティック保存率 100% を保証します。

## 1. 哲学セクション (Philosophy) マッピング

### 1.1 目的 (Goals)

| v2.0.0 テーブル形式                        | v2.1.0 圧縮形式                          | セマンティック等価性 |
| ------------------------------------------ | ---------------------------------------- | -------------------- |
| 主目的: 技術的正確性と読みやすさの向上     | `GOAL = QUALITY_IMPROVEMENT`             | [OK] 完全一致        |
| 副目的: 著者の意図を尊重しながらの品質改善 | `GOAL = AUTHOR_INTENT_RESPECT`           | [OK] 完全一致        |
| 非目的: 著者のスタイルの全面書き換え       | `NON_GOAL = { REWRITE, STYLE_OVERRIDE }` | [OK] 完全一致        |

**NOTE セクション保存:**

```dsl
NOTE:
  - 主目的: 技術的正確性と読みやすさの向上
  - 副目的: 著者の意図を尊重しながらの品質改善
  - 非目的: 著者のスタイルの全面書き換え
```

### 1.2 介入レベル (Intervention Levels)

| v2.0.0 テーブル形式                                   | v2.1.0 圧縮形式                                                    | セマンティック等価性 |
| ----------------------------------------------------- | ------------------------------------------------------------------ | -------------------- |
| 高: 技術的誤り (API 仕様の誤記、コード例のバグ)       | `INTERVENTION HIGH = { TECHNICAL_ERROR, API_MISUSE, CODE_BUG }`    | [OK] 完全一致        |
| 中: 構造的問題 (論理展開の矛盾、セクション構成の改善) | `INTERVENTION MEDIUM = { STRUCTURAL_ISSUE, LOGIC_CONTRADICTION }`  | [OK] 完全一致        |
| 低: 表現の最適化 (冗長表現の簡潔化、用語の統一)       | `INTERVENTION LOW = { EXPRESSION_OPTIMIZATION, TERM_UNIFICATION }` | [OK] 完全一致        |

### 1.3 トーンとスタンス (Tone Boundaries)

| v2.0.0 テーブル形式                                                          | v2.1.0 圧縮形式                                                                        | セマンティック等価性 |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | -------------------- |
| 上限: 技術的誤りの明確な指摘、具体的な代替案の提示、意図を確認する質問形式   | `TONE UPPER = { TECHNICAL_ERROR_EXPLICIT, CONCRETE_ALTERNATIVE, INTENT_CONFIRMATION }` | [OK] 完全一致        |
| 下限: 主観的な好みの押し付け、曖昧な「改善してください」、一方的な否定・批判 | `TONE LOWER = { SUBJECTIVE_PREFERENCE, VAGUE_IMPROVEMENT, UNILATERAL_CRITICISM }`      | [OK] 完全一致        |

### 1.4 破壊的変更の境界 (Destructive Change Boundaries)

| v2.0.0 テーブル形式                                                                                                                      | v2.1.0 圧縮形式                                                                                  | セマンティック等価性 |
| ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | -------------------- |
| 許可: 誤字脱字の修正、文法的誤りの訂正、用語の統一、構造の明確化                                                                         | `CHANGE PERMITTED = { TYPO_FIX, GRAMMAR_CORRECTION, TERM_UNIFICATION, STRUCTURE_CLARIFICATION }` | [OK] 完全一致        |
| 禁止: 著者の技術的主張の根本的変更、コード例の設計思想の全面書き換え、著者の文体・語調の全面的な置き換え、セクション削除・大幅な構成変更 | `CHANGE PROHIBITED = { CLAIM_ALTERATION, DESIGN_REWRITE, STYLE_REPLACEMENT, SECTION_DELETION }`  | [OK] 完全一致        |

### 1.5 哲学違反時の強制ラベル (Violation Mappings)

| v2.0.0 テーブル形式                                      | v2.1.0 圧縮形式                                                | セマンティック等価性 |
| -------------------------------------------------------- | -------------------------------------------------------------- | -------------------- |
| 著者文体への過度介入 → PRIORITY D                        | `VIOLATION STYLE_OVERRIDE -> PRIORITY_D`                       | [OK] 完全一致        |
| 著者意図の無視 → ユーザー確認プロンプト表示 + PRIORITY D | `VIOLATION INTENT_DISREGARD -> PRIORITY_D + USER_CONFIRMATION` | [OK] 完全一致        |
| 主観的判断の押し付け → PRIORITY E                        | `VIOLATION SUBJECTIVE_BIAS -> PRIORITY_E`                      | [OK] 完全一致        |
| 意図不明 → 追加情報要求、レビュー保留                    | `STATUS QUESTION_REQUIRED -> REVIEW_HOLD`                      | [OK] 完全一致        |

## 2. Fail-fast セクション マッピング

### 2.1 Fail-fast 条件

| v2.0.0 テーブル形式                                                  | v2.1.0 圧縮形式                                                                    | セマンティック等価性 |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | -------------------- |
| 構造崩壊: 見出し階層の破綻、必須セクション欠落 → レビュー不能        | `IF STRUCTURE == UNESTABLISHED -> STATUS INCOMPLETE + REASON structural_collapse`  | [OK] 完全一致        |
| 技術的致命性: 実行不可コード、API誤用の連鎖 → 修正コストが再作成未満 | `IF TECHNICAL == BROKEN -> REVIEW SKIPPED + REASON technical_fatality`             | [OK] 完全一致        |
| 読解価値未成立: 論理展開不明、主題不在 → レビュー対象として不適格    | `IF READABILITY == UNESTABLISHED -> STATUS INCOMPLETE + REASON unreadability`      | [OK] 完全一致        |
| 文字数不足: 全体文字数 < 500文字 → レビュー前段階                    | `IF LENGTH < 500 -> STATUS INCOMPLETE + REASON insufficient_length`                | [OK] 完全一致        |
| 未完成コンテンツ: TODO/メモ/箇条書きのみ → 完成後に再提出要求        | `IF CONTENT_STATUS == INCOMPLETE -> STATUS INCOMPLETE + REASON incomplete_content` | [OK] 完全一致        |

### 2.2 Fail-fast Enum 値

| v2.0.0 条件名    | v2.1.0 Enum 値        | 説明                                                   |
| ---------------- | --------------------- | ------------------------------------------------------ |
| 構造崩壊         | `structural_collapse` | 見出し階層の破綻、必須セクション欠落 → レビュー不能    |
| 技術的致命性     | `technical_fatality`  | 実行不可コード、API誤用の連鎖 → 修正コストが再作成未満 |
| 読解価値未成立   | `unreadability`       | 論理展開不明、主題不在 → レビュー対象として不適格      |
| 文字数不足       | `insufficient_length` | 全体文字数 < 500文字 → レビュー前段階                  |
| 未完成コンテンツ | `incomplete_content`  | TODO/メモ/箇条書きのみ → 完成後に再提出要求            |

## 3. BNF セクション マッピング

### 3.1 コア構文 (Core BNF)

| v2.0.0 テーブル形式 (要素名) | v2.1.0 Backbone BNF                                                                      | セマンティック等価性 |
| ---------------------------- | ---------------------------------------------------------------------------------------- | -------------------- |
| def-macro                    | `<macro> ::= DEF <target> THEN <body> END`                                               | [OK] 完全一致        |
| target                       | `<target> ::= ACCEPTANCE <mode-list> \| /<command> \| VAR <scope> :<var> \| RULE <name>` | [OK] 完全一致        |
| body                         | `<body> ::= [<action> [-> <action>]] [NOTE:..] [CONSTRAINT:..]`                          | [OK] 完全一致        |
| action                       | `<action> ::= SET <var> = <value> \| CLEAR <var> \| EXECUTE <desc> \| EMIT <event>`      | [OK] 完全一致        |

### 3.2 コアモード (Core Modes)

| v2.0.0 テーブル形式 (要素名) | v2.1.0 Backbone BNF                         | セマンティック等価性 |
| ---------------------------- | ------------------------------------------- | -------------------- |
| scope                        | `<scope> ::= SESSION \| REVIEW`             | [OK] 完全一致        |
| generation-status            | `<status> ::= DRAFT \| INCOMPLETE \| READY` | [OK] 完全一致        |
| ACCEPTANCE (モード)          | `<mode> ::= PENDING \| ACTIVE`              | [OK] 完全一致        |

### 3.3 値形式 (Value Forms)

| v2.0.0 テーブル形式 (要素名) | v2.1.0 Backbone BNF                | セマンティック等価性 |
| ---------------------------- | ---------------------------------- | -------------------- |
| value                        | `<value> ::= "text" \| \| \| """"` | [OK] 完全一致        |

### 3.4 拡張ポイント (Extension Points)

| v2.0.0 テーブル形式 (要素名) | v2.1.0 Backbone BNF                                       | セマンティック等価性 |
| ---------------------------- | --------------------------------------------------------- | -------------------- |
| insert-mac                   | `<insert> ::= INSERT /<command> BEFORE\|AFTER <body> END` | [OK] 完全一致        |
| event-def                    | `<event> ::= EVENT <name> [WITH <payload>]`               | [OK] 完全一致        |
| on-handler                   | `<handler> ::= ON <event> DO <body> END`                  | [OK] 完全一致        |

## 4. CONSTRAINT 統合マッピング

### 4.1 分散 CONSTRAINT → 統合 CONSTRAINT

| v2.0.0 散在位置                      | v2.1.0 統合位置                                         | 内容                                              |
| ------------------------------------ | ------------------------------------------------------- | ------------------------------------------------- |
| セクション 0.2 (哲学)                | `DEF RULE REVIEW_CONSTRAINTS` (Philosophy enforcement)  | 違反ラベル付き指摘は自動降格、LLMは違反を自己検出 |
| セクション 0.2 (Fail-fast)           | `DEF RULE REVIEW_CONSTRAINTS` (Fail-fast constraints)   | 建設的な再提出ガイドを必ず提供                    |
| セクション 2.3 (ACCEPTANCE原則)      | `DEF RULE REVIEW_CONSTRAINTS` (ACCEPTANCE principle)    | ACCEPTANCEは品質評価ではなく、入力/処理の境界     |
| セクション 2.11 (記事生成ステータス) | `DEF RULE REVIEW_CONSTRAINTS` (Output generation guard) | OUTPUTはgeneration-status=READYの場合のみ生成     |
| セクション 2.12 (フォールバック規則) | `DEF RULE REVIEW_CONSTRAINTS` (Override mechanism)      | `:remark`はすべての規則を上書き可能               |
| セクション 3.6 (CATEGORY/PRIORITY)   | `DEF RULE REVIEW_CONSTRAINTS` (Enum constraints)        | CATEGORY/PRIORITYのenum拡張は禁止                 |

## 5. セマンティック保存検証

### 5.1 自動検証コマンド

```bash
# Philosophy 要素数検証
grep -c "GOAL\|NON_GOAL" dsl/llm-control-language-spec-compact.md
# Expected: 3 (GOAL × 2 + NON_GOAL × 1)

# Intervention レベル数検証
grep -c "INTERVENTION" dsl/llm-control-language-spec-compact.md
# Expected: 3 (HIGH, MEDIUM, LOW)

# Fail-fast 条件数検証
grep -c "IF.*THEN.*REASON" dsl/llm-control-language-spec-compact.md
# Expected: 5 (structural_collapse, technical_fatality, unreadability, insufficient_length, incomplete_content)

# CONSTRAINT 統合数検証
grep -c "CONSTRAINT:" dsl/llm-control-language-spec-compact.md
# Expected: ~18 (統合セクションに集約)
```

### 5.2 双方向変換テスト

**圧縮 → 展開 → 圧縮:**

```bash
Table Format → Compressed Format → Table Format (Round-trip test)
```

**検証項目:**

- [OK]すべての GOAL 値が保存されているか
- [OK]すべての INTERVENTION レベルが保存されているか
- [OK]すべての VIOLATION マッピングが保存されているか
- [OK]すべての Fail-fast 条件が保存されているか
- [OK]NOTE セクションに元の日本語説明が保存されているか

## 6. 意味的等価性の保証

### 6.1 構造的等価性

圧縮形式 (v2.1.0) とテーブル形式 (v2.0.0) は、以下の点で構造的に等価です。

- [OK]すべてのテーブル行が圧縮節に対応
- [OK]すべてのセルが圧縮値に対応
- [OK]すべての説明が NOTE セクションに保存

### 6.2 セマンティック等価性

圧縮形式 (v2.1.0) とテーブル形式 (v2.0.0) は、以下の点でセマンティックに等価です。

- [OK]LLM の解釈結果が同一
- [OK]実行時の挙動が同一
- [OK]制約条件が同一
- [OK]出力形式が同一

## 7. 参照

- [圧縮形式ガイド](./README-COMPRESSED-FORMAT.md)
- [マイグレーションガイド](./MIGRATION-v2.0-to-v2.1.md)
- [完全仕様書](./llm-control-language-spec.md)
- [圧縮仕様書](./llm-control-language-spec-compact.md)
