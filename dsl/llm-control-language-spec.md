---
title: マクロ構文仕様
description: 各プロンプトで制御構文を定義するためのマクロ構文を定義する (5層構造)
version: 1.1.0
update: 2026-01-27
architecture: 5-layer (Part 0:Overview / Part 1:Syntax / Part 2:Semantics / Part 3:Policy / Part 4:Macros / Part 5:Heuristics)
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Part 0: Overview

本マクロ構文は、プロンプトファイルの制御構文を形式的に定義する LLM 向け形式言語です。

**設計原則**:

1. **統一形式**: `DEF ... THEN ... END` (すべてのマクロ)
2. **四層構造**: Syntax (BNF 文法) / Semantics (形式意味論) / Common Macros (標準実装) / Heuristics (スタイル指針)
3. **識別子**: ASCII 限定(`<ascii-id>`) / 日本語許可(`<label>`)
4. **自己記述**: Part 2/3 は Part 1 のマクロ構文で意味論と実装を定義

**NOTE**: 本 DSL は実行を目的としない。LLM との認識共有を目的とする。

**バージョン管理** (Semantic Versioning):

- MAJOR (x.0.0): 破壊的変更 (BNF 構文変更、ACCEPTANCE 定義変更、再定義規則変更)
- MINOR (0.x.0): 後方互換の機能追加 (新 COMMAND/VAR 追加、CONSTRAINT 拡張)
- PATCH (0.0.x): バグ修正、ドキュメント改善、誤字訂正

### クイック概要

**最小構成**: `BEGIN INPUT` → `/review` → `OUTPUT` の 3 ステップ。

**レビュー哲学**: 技術的正確性を重視し、著者の意図を尊重。3段階介入レベル (高:技術誤り、中:構造問題、低:表現最適化)

**Backbone BNF**:

```abnf
; === トップレベル構造 ===
macro  = "DEF" target "THEN" body "END"
       / "INSERT" command position body "END"
       / "ON" event "DO" body "END"
       / meta-block

; === 拡張ポイント (重心)  ===
target = ACCEPTANCE / COMMAND / VAR / PRIORITY / OUTPUT / LOCATION / EVENT / STATUS
body   = <opaque>  ; 内部構造は Part 1.2 参照

; === コマンド・イベント ===
command  = "/" identifier
event    = identifier
position = BEFORE / AFTER

; === 入力・メタブロック ===
input  = "BEGIN" "INPUT" <opaque> "END"
meta-block = "BEGIN" block-type "DEF" <opaque> "END" "DEF"
block-type = DSL / MACRO / RULE / INPUT / OUTPUT
```

**Backbone BNF の設計原則**:

1. **列挙しない**: コマンド名や変数名を列挙せず、形式だけ示す (例: `command = "/" identifier`)
2. **body を定義しない**: `<opaque>` で内部構造を隠蔽し、中身に口を出さない
3. **分岐条件だけ残す**: 拡張ポイント (target) は明示し、言語の重心を示す

**NOTE: Backbone BNF の不変性宣言**:

Backbone BNF は「姿勢定義」であり、次のような目的はありません。

- 完全構文検証
- 拡張機能の網羅
- 実装指針の代替

この BNF はパーサー生成やバリデータ実装のための厳密な文法ではなく、LLM が言語の設計思想を理解するための概念的骨格を提供します。

この BNF は完全な構文受理を目的とせず、言語の**姿勢・重心・禁止領域**を LLM へ示すよう設計されています。詳細な文法は [1.2 統一 BNF](#12-統一-bnf) を参照してください。

**NOTE**: `<opaque>` は「この領域は LLM の自然言語理解に委ねる」ことを意味します。

詳細は目次の後の詳細セクション ([最小使用例詳細](#最小使用例詳細)、[3.1 Review Philosophy](#31-review-philosophy)) を参照してください。

### レビュー哲学 (概要)

本 DSL を使用したレビューシステムの基本原則:

```DSL
; Goals: QUALITY_IMPROVEMENT, AUTHOR_INTENT_RESPECT
; Interventions: HIGH (技術誤り) / MEDIUM (構造問題) / LOW (表現最適化)
; Violations: STYLE_OVERRIDE => PRIORITY_D, SUBJECTIVE_BIAS => PRIORITY_E
; Fail-fast: 5条件 (構造崩壊、技術的致命性、読解不能、文字数不足、未完成)
```

詳細は[3.1 Review Philosophy](#31-review-philosophy)、[3.4 制約規則統合](#34-制約規則統合)を参照してください。

## 目次

- [Part 0: Overview](#part-0-overview)
  - [クイック概要](#クイック概要)
  - [レビュー哲学 (概要)](#レビュー哲学-概要)
- [目次](#目次)
- [Part 0 詳細セクション](#part-0-詳細セクション)
  - [最小使用例詳細](#最小使用例詳細)
- [Part 1: Syntax](#part-1-syntax)
  - [1.1 メタ構文記号](#11-メタ構文記号)
  - [1.2 統一 BNF](#12-統一-bnf)
  - [1.3 文連続記号 `->` の設計意図](#13-文連続記号---の設計意図)
  - [1.4 メタブロック (構文的除外領域)](#14-メタブロック-構文的除外領域)
- [Part 2: Semantics](#part-2-semantics)
  - [構文と意味論の分離](#構文と意味論の分離)
  - [メタブロック意味論](#メタブロック意味論)
  - [Command Alias Resolution](#command-alias-resolution)
  - [NOTE 意味論](#note-意味論)
  - [ACCEPTANCE 遷移](#acceptance-遷移)
  - [コマンド実行制約](#コマンド実行制約)
  - [記事生成ステータス](#記事生成ステータス)
  - [変数スコープ](#変数スコープ)
  - [実行規約](#実行規約)
  - [実行順序](#実行順序)
  - [INSERT 合成](#insert-合成)
    - [INSERT マクロ定義と合成例](#insert-マクロ定義と合成例)
    - [INSERT 実行規則と制約](#insert-実行規則と制約)
  - [イベントシステム](#イベントシステム)
  - [構文要素の意味](#構文要素の意味)
  - [停止条件・エラーハンドリング](#停止条件エラーハンドリング)
  - [非校閲領域 (最優先)](#非校閲領域-最優先)
  - [フォールバック規則](#フォールバック規則)
    - [コマンド解釈失敗時](#コマンド解釈失敗時)
    - [変数解決失敗時](#変数解決失敗時)
    - [状態遷移違反時](#状態遷移違反時)
    - [OUTPUT 生成失敗時](#output-生成失敗時)
    - [制約違反時の処理順序](#制約違反時の処理順序)
    - [実装例](#実装例)
- [Part 3: Policy Layer (ポリシー層)](#part-3-policy-layer-ポリシー層)
  - [3.1 Review Philosophy](#31-review-philosophy)
  - [3.2 Fail-Fast Policy](#32-fail-fast-policy)
  - [3.3 Priority Conversion](#33-priority-conversion)
  - [3.4 制約規則統合](#34-制約規則統合)
- [Part 4: Common Macros (標準実装)](#part-4-common-macros-標準実装)
  - [共通モード構造](#共通モード構造)
  - [入力セクション構造](#入力セクション構造)
  - [共通コマンド](#共通コマンド)
    - [/set 実行前提条件](#set-実行前提条件)
  - [共通変数](#共通変数)
  - [共通イベント](#共通イベント)
  - [共通文章位置](#共通文章位置)
  - [OUTPUT Structure Extension AS "出力構造化の拡張"](#output-structure-extension-as-出力構造化の拡張)
    - [Simple Definition to Detailed Schema Correspondence AS "簡易定義と詳細スキーマの対応関係"](#simple-definition-to-detailed-schema-correspondence-as-簡易定義と詳細スキーマの対応関係)
    - [OUTPUT Format Schema AS "OUTPUT形式スキーマ (厳密定義)"](#output-format-schema-as-output形式スキーマ-厳密定義)
    - [Schema Validation Rules AS "スキーマ検証ルール"](#schema-validation-rules-as-スキーマ検証ルール)
    - [Output Format Example AS "出力形式例 (スキーマ準拠)"](#output-format-example-as-出力形式例-スキーマ準拠)
    - [OUTPUT Definition Cross-Reference AS "OUTPUT定義のクロスリファレンス"](#output-definition-cross-reference-as-output定義のクロスリファレンス)
    - [PRIORITY Enum Definition AS "PRIORITY enum定義 (全集合)"](#priority-enum-definition-as-priority-enum定義-全集合)
    - [Integrated Validation Flow AS "統合検証フロー"](#integrated-validation-flow-as-統合検証フロー)
    - [CATEGORY Enum Definition AS "CATEGORY enum定義 (全集合)"](#category-enum-definition-as-category-enum定義-全集合)
    - [Violation Label Enum Definition AS "違反ラベル enum定義 (哲学違反検知)"](#violation-label-enum-definition-as-違反ラベル-enum定義-哲学違反検知)
- [Part 5: Heuristics AS "スタイル指針"](#part-5-heuristics-as-スタイル指針)
  - [Naming Conventions AS "命名規則"](#naming-conventions-as-命名規則)
  - [Style Guidelines AS "スタイル"](#style-guidelines-as-スタイル)
  - [EXECUTE Statement Operational Guidelines AS "EXECUTE 文の運用指針"](#execute-statement-operational-guidelines-as-execute-文の運用指針)
  - [Practical Heuristics AS "実務的ヒューリスティクス"](#practical-heuristics-as-実務的ヒューリスティクス)
    - [Priority Decision Logic AS "優先度決定ロジック (PRIORITY 値の割り当て基準)"](#priority-decision-logic-as-優先度決定ロジック-priority-値の割り当て基準)
    - [Output Format Flexibility AS "出力フォーマットの柔軟化"](#output-format-flexibility-as-出力フォーマットの柔軟化)
- [Appendix](#appendix)
  - [Summary AS "まとめ"](#summary-as-まとめ)
  - [Anti-patterns AS "アンチパターン"](#anti-patterns-as-アンチパターン)
    - [EVENT Handler Misuse for SESSION\_PHASE Transitions AS "EVENT Handler による SESSION\_PHASE 遷移の誤用"](#event-handler-misuse-for-session_phase-transitions-as-event-handler-による-session_phase-遷移の誤用)
  - [Validation Conditions AS "検証条件"](#validation-conditions-as-検証条件)
  - [SESSION\_PHASE Usage Examples AS "SESSION\_PHASE 使用例"](#session_phase-usage-examples-as-session_phase-使用例)
    - [Article Generation Workflow SESSION\_PHASE Example AS "記事生成ワークフロー向け SESSION\_PHASE 例"](#article-generation-workflow-session_phase-example-as-記事生成ワークフロー向け-session_phase-例)
    - [Relationship with Standard SESSION\_PHASE AS "標準 SESSION\_PHASE との関係"](#relationship-with-standard-session_phase-as-標準-session_phase-との関係)
  - [更新履歴](#更新履歴)

---

## Part 0 詳細セクション

### 最小使用例詳細

本 DSL の基本的な使用パターンの詳細を示します。

```dsl
BEGIN INPUT
  SET :buffer = """"
技術記事の内容をここに記述します。
複数行のテキストを受け付けます。
""""
END INPUT

/review

→ OUTPUT:
  指摘種別: 修正必須
  CATEGORY: readability
  PRIORITY: C
  該当箇所: セクション1.paragraph[0].sentence[0]
  内容: 冗長な表現を簡潔にすることを推奨します
  根拠: 技術文書では明瞭さが重要です
```

**NOTE**: 最小構成は `BEGIN INPUT` → コマンド実行 → `OUTPUT` の 3 ステップ。各ステップの詳細は後続セクションで定義。

---

## Part 1: Syntax

### 1.1 メタ構文記号

| 記号        | 意味                    | 例                               |
| ----------- | ----------------------- | -------------------------------- |
| `<name>`    | 非終端記号              | `<mode>`, `<command>`            |
| `[xxx]`     | 省略可能                | `[引数]`                         |
| `[xx ..]`   | 0回以上繰り返し (旧)    | `[<変数> ..]`                    |
| `*xxx`      | 0回以上繰り返し (ABNF)  | `*<assignment>`                  |
| `1*xxx`     | 1回以上繰り返し (ABNF)  | `1*<var-name>`                   |
| `,`         | 区切り                  | `A, B, C`                        |
| `::=`       | 定義                    | `<A> ::= <B>`                    |
| `\|`        | 選択 (旧)               | `A \| B`                         |
| `/`         | 選択 (ABNF)             | `A / B`                          |
| `"..."`     | リテラル                | `"DEF"`                          |
| `; comment` | コメント                | `; トップレベル`                 |
| `->`        | 文連続 (省略可・改行可) | `CLEAR :x -> SET ACCEPTANCE = y` |
| `=>`        | 状態遷移・変換          | `PENDING => ACTIVE`, `A => B`    |

### 1.2 統一 BNF

本マクロ構文の形式文法を ABNF 記法 (RFC 5234) で定義します。

```abnf
; ============================================================
; LCL DSL Unified Grammar (Backbone Mode)
; ============================================================

; --- トップレベル構造 ---
<macro-def>       ::= <def-macro> / <insert-macro> / <on-handler> / <meta-block>
<def-macro>       ::= "DEF" <def-target> "THEN" <body> "END"
<meta-block>      ::= "BEGIN" ("DSL" / "MACRO" / "RULE" / "INPUT" / "OUTPUT") "DEF" LF
                      <block-content>
                      "END" "DEF"
<block-content>   ::= *line

; --- 旧形式 (後方互換性、非推奨) ---
<input-section>   ::= "BEGIN" "INPUT" *<assignment> "END" "INPUT"
<assignment>      ::= "/set" <var-name> "=" <value>

; --- 定義ターゲット ---
<def-target>      ::= <mode-def> / <command-def> / <var-def> / <priority-def> / <output-def>
                    / <location-def> / <event-def> / <status-def>

<mode-def>        ::= "ACCEPTANCE" <mode-spec> *("," <mode-spec>)
<mode-spec>       ::= <identifier> ["AS" <string-literal>]

<command-def>     ::= "/" <identifier> *<param-spec> [<option-spec>]
<param-spec>      ::= "<" <identifier> ">"
                    / "[" "<" <identifier> ">" ".." "]"
                    / "<" ":" <identifier> ">"
                    / "[" "<" ":" <identifier> ">" ".." "]"
<option-spec>     ::= "--" <option-name> "=" <option-value>
<option-name>     ::= <identifier>
<option-value>    ::= <identifier> / <string-literal>

<var-def>         ::= "VAR" ("SESSION" / "REVIEW") <var-name> ["=" <initial-value>]
<var-name>        ::= ":" <identifier>
<initial-value>   ::= <string-literal> / <number> / <boolean>

; --- ボディとステートメント ---
<body>            ::= [<statement> *("->" <statement>)] *<note> [<constraint-clause>]
<statement>       ::= <action> / <field-def> / <level-desc> / <clearby> / <rule-def> / <transition-def>
<note>            ::= "NOTE" ":" *VCHAR

; --- アクション ---
<action>          ::= <set-action> / <clear-action> / <execute-action> / <emit-action>
<set-action>      ::= "SET" (<var-name> / "ACCEPTANCE" / "INITIAL_ACCEPTANCE") "=" <value>
<clear-action>    ::= "CLEAR" 1*<var-name> / "CLEAR" "ALL" ["ON" ("SESSION" / "REVIEW")]
<execute-action>  ::= "EXECUTE" *VCHAR

; --- 拡張機能: INSERT マクロ合成 ---
<insert-macro>    ::= "INSERT" "/" <identifier> ("BEFORE" / "AFTER") <body> "END"

; --- 拡張機能: イベントシステム ---
<event-def>       ::= "EVENT" <identifier> ["WITH" <payload-field> *("," <payload-field>)]
<payload-field>   ::= <identifier> [":" ("text" / "number" / "boolean" / "mode" / "object")]
<on-handler>      ::= "ON" <identifier> "DO" <body> "END"
<emit-action>     ::= "EMIT" <identifier> ["WITH" <identifier> "=" <value> *("," <identifier> "=" <value>)]

; --- 拡張機能: 遷移制御 ---
<transition-def>  ::= "ALLOW" "TRANSITION" <identifier> "->" <identifier>

; --- 出力制御 ---
<priority-def>    ::= "PRIORITY" <identifier> *("," <identifier>)
<output-def>      ::= "OUTPUT" <identifier> ["WITH" "LOCATION"]
<status-def>      ::= "STATUS" ("DRAFT" / "INCOMPLETE" / "READY")
<location-def>    ::= "LOCATION" <identifier>

<field-def>       ::= "FIELD" <identifier> ":" <field-type>
<field-type>      ::= *VCHAR / <section-id> / <node-type> / <node-index>
<rule-def>        ::= "RULE" <identifier> ":" *VCHAR

; --- Location 型 ---
<section-id>      ::= <identifier> ["[" <number> "]"]
<node-index>      ::= <node-type> "[" <number> "]" ".sentence[" <number> "]"
<node-type>       ::= "paragraph" / "list_item" / "heading"

; --- その他ステートメント ---
<level-desc>      ::= <identifier> ":" *VCHAR
<clearby>         ::= "CLEARBY" "/" <identifier>
<constraint-clause> ::= "CONSTRAINT" ":" 1*("-" *VCHAR)

; --- 終端記号 ---
<identifier>      ::= (ALPHA / "_") *(ALPHA / DIGIT / "_" / "-" / CJK)
<value>           ::= <string-literal> / <multiline> / <heredoc> / <number> / <boolean> / <var-name>
<string-literal>  ::= DQUOTE *(VCHAR / CJK) DQUOTE
<option>          ::= "--" <identifier> "=" (<identifier> / <string-literal>)
<multiline>       ::= "|" *(VCHAR / CJK)
<heredoc>         ::= '""""' *line '""""'
<number>          ::= 1*DIGIT
<boolean>         ::= "true" / "false"

; --- ABNF 基本定義 (RFC 5234 準拠) ---
; ALPHA  = %x41-5A / %x61-7A           ; A-Z / a-z
; DIGIT  = %x30-39                     ; 0-9
; DQUOTE = %x22                        ; "
; VCHAR  = %x21-7E                     ; 可視文字
; CJK    = %x3040-309F / %x30A0-30FF / %x4E00-9FFF  ; ひらがな/カタカナ/漢字
; LF     = %x0A                        ; 改行
; line   = *VCHAR LF                   ; 1行のテキスト
```

```DSL
BEGIN RULE DEF

RULE BNF formality:
  本BNFは以下の特性を持つ:
    - 厳密なBNFではなく、LLMの理解を支援する構造契約である
    - 実行順序・スコープライフタイム・モード遷移はPart 2で定義される
    - 文法的正当性と実行時意味は分離されている

END DEF
```

### 1.3 文連続記号 `->` の設計意図

```DSL
BEGIN RULE DEF

RULE statement continuation operator:
  文連続記号 `->` は、複数の <statement> を単一行にまとめるための省略可能な演算子である

  構文的特性:
    - 改行と等価 (改行の代替記法)
    - 連続使用可能 (任意個の statement を連結)
    - 省略可能 (改行で代替可能)

  使用制約:
    - 単純なアクション (SET/CLEAR/EMIT) : 2-3個まで連結許可
    - 複雑な定義 (FIELD/RULE/CONSTRAINT) : 改行維持必須
    - 行長制限: 連結後の行は120文字以内を厳守

  禁止パターン:
    - 4個以上のアクション連結
    - FIELD/RULE を含む複雑な定義での使用
    - 120文字を超える行の生成

CONSTRAINT statement continuation usage:
  - `->` による連結は可読性を損なわない範囲でのみ許可
  - 単一の責務を持つ単純なコマンド定義に限定
  - ネスト構造や複雑なロジックでは使用禁止

END DEF
```

### 1.4 メタブロック (構文的除外領域)

**設計意図**: DSL 定義・マクロ定義を**構文的に**校閲・レビュー対象外とし、自己再帰リスクを根本的に防ぐ。

**構文**:

```abnf
<meta-block> ::= "BEGIN" ("DSL" / "MACRO" / "RULE" / "INPUT" / "OUTPUT") "DEF" LF
                  <block-content>
                  "END" "DEF"
```

**block-type の意味**:

| タイプ   | 用途                             | 例                         |
| -------- | -------------------------------- | -------------------------- |
| `DSL`    | DSL構文定義 (BNF、意味論)        | Part 1, Part 2 の定義      |
| `MACRO`  | マクロ定義 (DEF/INSERT/EVENT)    | コマンド・変数・モード定義 |
| `RULE`   | 制約・規則定義 (RULE/CONSTRAINT) | 動作規則・ガード条件       |
| `INPUT`  | 入力セクション (変数初期化)      | セッション変数の初期値設定 |
| `OUTPUT` | 出力定義 (DEF OUTPUT)            | 出力フォーマット定義       |

使用例:

```DSL
BEGIN MACRO DEF
  ; この領域はLLMの校閲対象外
  DEF ACCEPTANCE PENDING AS "受付中", ACTIVE AS "処理中" THEN
    SET INITIAL_ACCEPTANCE = PENDING
  END

  DEF /begin THEN CLEAR :buffer END
  DEF /end THEN :buffer確定 END
END DEF

; このMarkdown説明文は校閲対象
**ACCEPTANCE説明**: PENDINGは文章受付状態、ACTIVEは処理実行状態です。
```

**重要な特性**:

1. **構文的除外**: BEGIN...END DEF 内は LLM の校閲・レビュー処理から**除外**
2. **定義登録**: 内容は「定義」として登録・解釈されるが、**文章としては評価されない**
3. **指摘禁止**: 誤字脱字・曖昧表現を含め**一切の指摘を禁止**
4. **スコープ**: ブロック外の Markdown 説明文のみが校閲対象

**RULE との違い**:

- `RULE non-proofreading areas` → 解釈層での除外 (LLM が理解する必要がある)
- `BEGIN <type> DEF ... END DEF` → 構文層での除外 (LLM は単にスキップする)

メタブロックにより、自己再帰問題が根本的に解決されます。

## Part 2: Semantics

### 構文と意味論の分離

```DSL
BEGIN RULE DEF

RULE syntax-semantics separation:
  Part 1 (Syntax) と Part 2 (Semantics) は独立した評価レイヤーである

  構文レイヤー (Part 1 BNF):
    - マクロ構文の文法的正当性を定義
    - パース可能性を判定
    - 文法要素として書けることを規定

  意味論レイヤー (Part 2 Semantics):
    - マクロの実行時意味を定義
    - 制約・条件・状態遷移を評価
    - 実行時契約を表現

RULE evaluation phases:
  マクロ定義の解釈は以下の3段階で行われる:
    1. 構文解析 (Part 1): 文法的正当性検証
    2. 意味論評価 (Part 2): 制約・遷移規則・スコープ検証
    3. 実行 (Part 3): Common Macros に従った動作

RULE macro evaluation order:
  意味論評価フェーズにおいて、マクロ定義要素は以下の順序で解釈される:
    1. DEF: コマンド・変数・モード定義の登録
    2. CONSTRAINT: 実行条件・制約の評価
    3. RULE: 動作規則・ガード条件の評価
    4. EVENT / INSERT: イベントハンドラ・合成規則の評価

CONSTRAINT semantic consistency:
  - 文法的に正しくても意味論的に矛盾する定義は未定義動作
  - CONSTRAINT/RULE は意味論的ガードであり構文要素ではない
  - LLM は CONSTRAINT/RULE を解釈フェーズで評価される契約として扱う
  - BNF で書けることと実行時有効性は独立

CONSTRAINT evaluation dependencies:
  - CONSTRAINT/RULE は DEF で定義された要素を参照可能
  - EVENT/INSERT は全ての制約・規則を認識した状態で合成
  - 評価フェーズの暗黙的動作による不整合を禁止

END DEF
```

### メタブロック意味論

```DSL
BEGIN RULE DEF

RULE meta-block semantics:
  BEGIN <type> DEF ... END DEF 内は以下の特性を持つ:
    - 構文的除外: LLMの校閲・レビュー処理から完全に除外
    - 定義登録: 内容は「定義」として登録・解釈される
    - 文章評価なし: 誤字脱字・曖昧表現を含め一切の指摘を禁止
    - スコープ境界: ブロック外のMarkdown説明文のみが校閲対象

RULE block-type usage:
  block-type は以下の用途で使用される:
    - DSL: DSL構文定義 (BNF、意味論)
    - MACRO: マクロ定義 (DEF/INSERT/EVENT)
    - RULE: 制約・規則定義 (RULE/CONSTRAINT/CATEGORY/PRIORITY)
    - INPUT: 入力セクション (変数初期化)
    - OUTPUT: 出力定義 (DEF OUTPUT)

RULE meta-block processing:
  LLMはメタブロックを以下の3段階で処理する:
    1. 構文解析フェーズ:
       - BEGIN <type> DEF 検出でメタブロック開始
       - END DEF まで内容を「定義データ」として取り込み
       - 校閲・レビュー対象リストから除外
    2. 意味論評価フェーズ:
       - メタブロック内の定義を登録 (ACCEPTANCE/COMMAND/VAR等)
       - 制約・規則を評価
       - 文章としての評価は行わない
    3. 校閲・レビューフェーズ:
       - メタブロック外のMarkdown説明文のみを処理
       - メタブロック内には一切アクセスしない

CONSTRAINT meta-block processing:
  - LLMはメタブロック内を「定義データ」として扱う
  - 内容の正確性・可読性を評価しない
  - ブロック境界は厳密に遵守される

RULE self-recursion prevention:
  メタブロックは二重防護により自己再帰リスクを排除する:
    - 第一防壁: メタブロック構文による物理的遮断 (構文層での除外)
    - 第二防壁: RULE non-proofreading areas による論理的制約 (意味論層での除外)

CONSTRAINT exclusion layer distinction:
  - メタブロック: 構文層での除外 (LLMは領域をスキップ)
  - RULE non-proofreading areas: 解釈層での除外 (LLMは理解して従う)

END DEF
```

### Command Alias Resolution

````DSL
BEGIN RULE DEF

RULE command-alias-resolution:
  コマンドエイリアスは意味論レイヤーでの正規化機構である

  定義層:
    - 意味論レイヤー (構文ではない)
    - ABNF定義の変更不要 (token = 1*(ALPHA / DIGIT / "-" / "_") で既にカバー済み)

  評価時期:
    - コマンド評価前の正規化フェーズ
    - 構文解析後、意味論評価前

  効果範囲:
    - すべてのコマンド動作 (完全一致)
    - ACCEPTANCE遷移、EXEC_MODE遷移、副作用すべてを含む

  宣言方法:
    - プロンプト固有定義セクションで列挙
    - プロンプト固有の Section 6 等で定義

RULE alias-normalization:
  コマンドエイリアス正規化規則:

  ```abnf
  COMMAND_NORMALIZATION ::= alias-resolve

  alias-resolve:
    IF command IN alias-map.keys
    THEN command := alias-map[command]
````

正規化後の動作:

- エイリアス解決後は元のコマンドと完全一致
- 意味論的差異・副作用の違いは存在しない
- ACCEPTANCE 遷移、EXEC_MODE 遷移、再入禁止挙動すべて一致

CONSTRAINT alias-semantics:

- エイリアスは構文拡張ではなく、意味論層での正規化
- エイリアスは評価前に正規化され、完全なコマンド等価性を保証
- エイリアス独自の動作・副作用は存在しない
- プロンプト間でのエイリアス定義の統一は不要 (プロンプト固有の利便性機能)

EXAMPLE alias-usage:
`/w` → `/write` のエイリアス定義例:

```DSL
; プロンプト固有定義セクション (Section 6.3等)
DEF COMMAND /w THEN
  ; Section 2で定義された正規化により /write に変換
  ; 以降の動作は /write と完全一致
END
```

使用時の動作:

- `/w` 入力 → alias-resolve → `/write` に正規化
- `/write` のすべての制約・動作を継承
- ACCEPTANCE: PENDING→ACTIVE(一時)→PENDING
- EXEC_MODE: idle→processing→idle
- 再入禁止
- generation-status 遷移

END DEF

### NOTE 意味論

```DSL
BEGIN RULE DEF

RULE NOTE semantics:
  NOTE は以下の特性を持つ:
    - 構文要素として認識される
    - 実行・制約・評価には一切影響しない
    - ACCEPTANCE 遷移・COMMAND 可否・条件分岐の判断材料に使用してはならない
    - LLM は NOTE を「人間向け説明」として保持するが、解釈ロジックには含めない

RULE NOTE placement:
  NOTE は以下の位置に配置可能:
    - DEF ... END の body 末尾 (statement の後、CONSTRAINT の前)
    - 複数の NOTE を連続配置可能
    - statement 途中への割り込みは禁止 (制御フロー汚染を防ぐ)

CONSTRAINT NOTE inertness:
  - NOTE の内容を根拠として挙動を変更してはならない
  - NOTE を参照した結果は未定義動作とする
  - NOTE は実行時に読み飛ばされる (評価対象外)

CONSTRAINT NOTE vs RULE distinction:
  - NOTE: 人間向け補足説明 (不活性)
  - RULE: LLM が解釈・遵守すべき規則 (活性)
  - NOTE の内容を RULE として扱ってはならない

END DEF
```

### ACCEPTANCE 遷移

```DSL
BEGIN RULE DEF

PRINCIPLE ACCEPTANCE semantics (意味固定):
  ACCEPTANCE は合否や品質評価を意味しない
  ACCEPTANCE は文章の受付と処理開始の境界を示す

  本質的性質:
    - ACCEPTANCE は合否や品質評価を意味しない
      - 「受け入れ可否」「品質判定」「承認」ではない
      - 文章の受付と処理開始の境界を示す状態変数である

    - ACCEPTANCE が PENDING の間、モデルは沈黙する
      - PENDING: 文章受付中、処理しない
      - 下書き貼り付け中は保持のみ
      - 解析・要約・応答は禁止

    - 明示的なコマンドにより、ACCEPTANCE は一時的に ACTIVE とみなされる
      - /write により明示的に ACTIVE 化
      - 指定された範囲のみ生成
      - 出力完了後は原則 PENDING に戻る (自動ではなく合意)

  ACCEPTANCE STATES:
    - PENDING (受付中): 文章受付中、処理しない
      - 記事テキスト貼り付け中
      - モデルは保持のみ、解析・要約・応答は禁止
      - 沈黙が正解

    - ACTIVE (処理中): 明示指示により処理を開始してよい
      - /write によって明示的に ACTIVE 化
      - 指定された範囲のみ生成
      - 出力完了後は原則 PENDING に戻る

CONSTRAINT ACCEPTANCE sovereignty:
  ACCEPTANCE は「制御」ではなく「主導権の宣言」である
  LLM の自発的な「親切」「補完」「提案」は主導権侵害とみなす
  すべての処理は明示的なコマンドでのみ開始される

END DEF
```

```DSL
BEGIN MACRO DEF

; ACCEPTANCE定義 (文章受付層)
DEF ACCEPTANCE PENDING AS "受付中", ACTIVE AS "処理中" THEN
  SET INITIAL_ACCEPTANCE = PENDING
  ALLOW TRANSITION PENDING -> ACTIVE (一時)
  ALLOW TRANSITION ACTIVE -> PENDING

  NOTE: ACCEPTANCE遷移図
    ┌─────────┐
    │ PENDING │ (初期状態: 受付中)
    └────┬────┘
         │ /write (明示的コマンド)
         ▼
    ┌─────────┐
    │ ACTIVE  │ (処理中)
    └────┬────┘
         │ 処理完了
         ▼
    ┌─────────┐
    │ PENDING │ (再び受付中)
    └─────────┘

    遷移規則:
      - PENDING => ACTIVE: /write による明示的遷移 (一時的)
      - ACTIVE => PENDING: 処理完了後の自動復帰 (合意による)
      - 自動遷移は禁止、すべて明示的コマンドによる

  CONSTRAINT:
    - ACCEPTANCE は文章の受付と処理開始の境界を示す
    - 合否や品質評価を意味しない (意味固定)
    - 処理許可の制御を行う

  RULE ACCEPTANCE semantics:
    PENDING = 文章受付中、処理しない
      - 記事テキスト貼り付け中
      - モデルは保持のみ
      - 解析・要約・応答は禁止
      - 沈黙が正解
      - 受付可能コマンド: /begin, /set, /reset, /end, /exit

    ACTIVE = 明示指示により処理を開始してよい
      - /write によって明示的に ACTIVE 化 (一時的)
      - 指定された範囲のみ生成
      - 出力完了後は原則 PENDING に戻る
      - 受付可能コマンド: /exit (強制終了のみ)

  RULE transition:
    PENDING => ACTIVE:
      TRIGGER: /write command (explicit user command only)
      EFFECT: temporary processing permission (single operation)

    ACTIVE => PENDING:
      TRIGGER: operation completion
      EFFECT: automatic return to reception state (consensual, not autonomous)

    DEFAULT_BEHAVIOR: PENDING (silence, no unsolicited response)
    EXCEPTION_BEHAVIOR: ACTIVE (response only when explicitly commanded)

  NOTE: 2状態モデル (PENDING/ACTIVE) の設計意図は、「沈黙がデフォルト、応答は例外」という
        原則を実装することです。ユーザーの明示的な /write コマンドのみが ACTIVE 化を
        トリガーし、処理完了後は必ず PENDING に戻ります。

  RULE ACCEPTANCE naming clarification:
    ACCEPTANCE は「承認」「受け入れ」「合否判定」ではない:
      - 文章の受付と処理開始の境界を示す状態変数
      - PENDING: 受け取るだけ、処理しない
      - ACTIVE: 明示的コマンドで一時的に処理許可
END

; EXECUTE_MODE定義 (内部処理層)
DEF EXECUTE_MODE idle AS "待機中", processing AS "処理中" THEN
  SET INITIAL_EXECUTE_MODE = idle
  ALLOW TRANSITION idle -> processing
  ALLOW TRANSITION processing -> idle

  CONSTRAINT:
    - EXECUTE_MODE は内部専用、ユーザーから不可視
    - ACCEPTANCE=ACTIVE でのみ遷移可能
    - processing 中はユーザー入力を保留
    - /review および /write は再入禁止 (EXECUTE_MODE=processing で判定)

  RULE processing output prohibition:
    EXECUTE_MODE=processing 中は、以下を厳守する:
      - ユーザー向け説明文を禁止 (処理内容の解説・判断根拠の説明を含む)
      - ただし「処理中」である事実通知は例外的に許可される
      - ユーザー入力を保留 (処理完了まで受付不可)
      - 内部処理のみ実行 (EVENT/SET/EXECUTE)
    出力は EXECUTE_MODE=idle 復帰後にのみ許可される

  RULE status notification vs explanatory text distinction:
    「事実通知」と「説明文」の区別:
      事実通知 (許可):
        - 「レビュー処理中です...」
        - 「記事を分析しています」
        - 処理フェーズの名称のみを通知する簡潔な文言
      説明文 (禁止):
        - 「〜の理由で〜を確認しています」
        - 中間結果の提示・判断根拠の解説
        - 処理内容の詳細な説明

    CONSTRAINT:
      - 事実通知は1-2文以内、10単語以内を厳守
      - 処理フェーズ名のみ許可、理由・根拠は含めない
      - 中間結果・判断内容は EXECUTE_MODE=idle 復帰後に出力
END

; モード遷移コマンド
DEF /begin THEN SET SESSION_PHASE = input END
DEF /end THEN SET SESSION_PHASE = waiting END
DEF /review THEN
  SET EXECUTE_MODE = processing
  EXECUTE レビュー処理
  SET EXECUTE_MODE = idle
END
DEF /exit THEN SET SESSION_PHASE = command END

END DEF
```

### コマンド実行制約

```DSL
BEGIN RULE DEF

; SESSION_PHASE 依存の実行制約
RULE /begin:
  MUST be executed in SESSION_PHASE=command OR SESSION_PHASE=waiting

RULE /review:
  MUST be executed ONLY in SESSION_PHASE=waiting
  MUST NOT be re-entered while EXECUTE_MODE=processing

RULE /write:
  MUST be executed ONLY in SESSION_PHASE=waiting
  MUST NOT be re-entered while EXECUTE_MODE=processing

RULE /exit:
  CAN be executed in ANY SESSION_PHASE
  RESETS both SESSION_PHASE and EXECUTE_MODE

RULE SESSION_PHASE vs EXECUTE_MODE separation:
  SCOPE:
    SESSION_PHASE: control user-visible state
    EXECUTE_MODE: control internal execution state

  CONSTRAINT independence:
    SESSION_PHASE and EXECUTE_MODE are independent variables
    Both can exist simultaneously with different values

  CONSTRAINT execute_mode_transition_guard:
    EXECUTE_MODE transitions ONLY when SESSION_PHASE=waiting
    EXECUTE_MODE must remain idle when SESSION_PHASE≠waiting

  BEHAVIOR command_execution:
    PRECONDITION:
      SESSION_PHASE=waiting AND EXECUTE_MODE=idle

    ON /review OR /write:
      EXECUTE_MODE: idle => processing

    INVARIANT during_execution:
      SESSION_PHASE remains waiting (no change)

    ON completion:
      EXECUTE_MODE: processing => idle
      SESSION_PHASE: waiting (unchanged)

  NOTE: /review 実行時、SESSION_PHASE は waiting のまま変化せず、
        EXECUTE_MODE だけが idle => processing => idle と遷移します。

END DEF
```

### 記事生成ステータス

```DSL
BEGIN MACRO DEF

DEF STATUS DRAFT, INCOMPLETE, READY THEN
  SEMANTICS:
    generation-status: declarative state variable for article generation progress

    DRAFT:
      description: "article generation initiated"
      phase: "information gathering and structure planning"
      output_allowed: false

    INCOMPLETE:
      description: "insufficient information detected"
      requires: "additional user input"
      trigger_effect: "prompt SESSION_PHASE=input transition"
      output_allowed: false

    READY:
      description: "article generation completed"
      output_allowed: true

  TRANSITION:
    DRAFT => INCOMPLETE:
      TRIGGER: insufficient information detected

    DRAFT => READY:
      TRIGGER: generation completed successfully

    INCOMPLETE => (SESSION_PHASE=input):
      EFFECT: request additional input from user

    READY => OUTPUT:
      EFFECT: output permission granted

  CONSTRAINT output_control (canonical):
    OUTPUT generation is ALLOWED if and only if generation-status=READY
    OUTPUT generation is FORBIDDEN when generation-status=INCOMPLETE
    OUTPUT generation is PENDING when generation-status=DRAFT

    generation-status is declarative constraint, NOT execution directive

    APPLICABILITY:
      APPLIES_TO: generative prompts (article-writer.prompt, etc.)
      NOT_APPLIES_TO: review prompts (always output-capable)

    SIDE_EFFECT:
      IF generation-status=INCOMPLETE THEN prompt ACCEPTANCE=PENDING transition

  SCOPE vs SESSION_PHASE:
    SESSION_PHASE:
      domain: user-visible UI state
      values: {command, input, waiting}
      responsibility: command acceptance control

    generation-status:
      domain: internal article generation lifecycle
      values: {DRAFT, INCOMPLETE, READY}
      responsibility: OUTPUT generation readiness control

  NOTE: クロスリファレンス
        - 詳細定義: 「### 記事生成ステータス」(line 947)
        - フォールバック: 「#### OUTPUT 生成失敗時」(line 1580)
        - MACRO定義: 「RULE OUTPUT generation guard」(line 2288)

END

END DEF
```

### 変数スコープ

```DSL
BEGIN MACRO DEF

; SESSION スコープ: /exit でクリア
DEF VAR SESSION :role THEN CLEARBY /exit END
DEF VAR SESSION :link THEN CLEARBY /exit END

; REVIEW スコープ: /begin でクリア
DEF VAR REVIEW :buffer THEN CLEARBY /begin END
DEF VAR REVIEW :review THEN CLEARBY /begin END

END DEF
```

### 実行規約

```DSL
BEGIN RULE DEF

RULE definition_evaluation_order:
  SEMANTICS:
    DEF macros are evaluated in sequential order (top-to-bottom)
    Definition order in prompt file determines execution order

  EVALUATION_MODEL:
    LET definitions = [DEF_1, DEF_2, ..., DEF_n]
    FOR definition IN definitions:
      EVALUATE definition
    END

  CONSTRAINT sequential_evaluation:
    DEF_i MUST be evaluated before DEF_j when i < j
    Forward references are NOT permitted

RULE redefinition_prohibition:
  CONSTRAINT redefinition_prohibition:
    Within same scope, DEF redefinition is FORBIDDEN

  EXCEPTION composition:
    INSERT-based extension is composition, NOT redefinition
    INSERT DOES NOT violate redefinition prohibition

  SEMANTICS:
    LET scope = current_scope
    IF DEF command exists in scope THEN
      REJECT new DEF for same command
    ELSE
      ACCEPT DEF
    END

RULE var_mutability:
  SEMANTICS:
    All VAR declarations are implicitly mutable
    No immutable variable concept exists

  MUTABILITY:
    /set command CAN overwrite any VAR at any time
    Reassignment is ALWAYS permitted

  TYPE_SYSTEM:
    VAR has no type constraints
    All values are treated as strings

RULE var_initialization:
  INITIALIZATION_RULE:
    IF VAR has no explicit initial value THEN
      SET VAR = "" (empty string)
    END

  TYPE_SEMANTICS:
    No numeric type exists
    No boolean type exists
    All values are strings (type system is unityped)

RULE conflict_resolution:
  CONSTRAINT_COMPOSITION:
    Multiple CONSTRAINT clauses are combined with logical AND
    LET constraints = [C_1, C_2, ..., C_n]
    COMBINED_CONSTRAINT = C_1 AND C_2 AND ... AND C_n

  PRIORITY_USAGE:
    PRIORITY is ONLY used for OUTPUT context conflict resolution
    PRIORITY MUST NOT be used for execution control
    PRIORITY MUST NOT be used for conditional branching

  SCOPE:
    APPLICABLE: OUTPUT field selection when multiple options exist
    NOT_APPLICABLE: EXECUTE statement control flow

RULE implicit_knowledge_dependency:
  HYBRID_NATURE:
    This DSL is formal language but depends on LLM implicit knowledge in specific domains

  IMPLICIT_KNOWLEDGE_DOMAINS:
    EXECUTE statement:
      execution content depends on natural language description
      LLM interprets natural language instructions

    FIELD/RULE interpretation:
      semantic interpretation delegated to LLM judgment
      LLM determines appropriate interpretation based on context

    termination conditions:
      IF NOT explicitly defined THEN
        LLM infers termination conditions from context
      END

  FORMALITY_BOUNDARY:
    Syntax: formal (machine-parseable)
    Semantics: hybrid (formal + implicit knowledge)

END DEF
```

### 実行順序

```DSL
BEGIN MACRO DEF

; 基本順序: CLEAR -> SET -> EXECUTE -> SET SESSION_PHASE
DEF /example THEN
  CLEAR :temp_var
  SET :result = "value"
  EXECUTE 処理内容
  SET SESSION_PHASE = 次モード
END

; CLEAR の形式
DEF /clear_single <:var> THEN CLEAR :var END
DEF /clear_multi <:v1> <:v2> THEN CLEAR :v1 :v2 END
DEF /clear_session THEN CLEAR ALL ON SESSION END
DEF /clear_review THEN CLEAR ALL ON REVIEW END
DEF /clear_all THEN CLEAR ALL END

RULE CLEAR ALL semantics:
  CLEAR ALL は以下と等価である:
    - CLEAR ALL ON SESSION
    - CLEAR ALL ON REVIEW
  すべてのスコープの全変数をクリアする

; 単一行形式 (-> 使用)
DEF /begin THEN CLEAR :buffer -> SET SESSION_PHASE = input END
DEF /end THEN SET SESSION_PHASE = waiting END
DEF /exit THEN CLEAR ALL -> SET SESSION_PHASE = command END

; 混在形式 (改行 + ->)
DEF /complex THEN
  CLEAR :temp
  SET :result = "value" -> SET SESSION_PHASE = processing
  EXECUTE 処理内容
END

END DEF
```

### INSERT 合成

#### INSERT マクロ定義と合成例

```DSL
BEGIN MACRO DEF

; 元の定義
DEF /process THEN
  EXECUTE メイン処理
END

; BEFORE 拡張
INSERT /process BEFORE
  SET :prepared = true
END

; AFTER 拡張
INSERT /process AFTER
  EMIT ProcessCompleted WITH result = :result
END

; 合成結果: BEFORE -> 元BODY -> AFTER

; 複数 INSERT の合成例 (同一コマンドへの複数定義)
DEF /process THEN
  EXECUTE メイン処理
END

; 第1 BEFORE 拡張 (最初に定義)
INSERT /process BEFORE
  SET :prepared = true
  EXECUTE 事前処理1
END

; 第2 BEFORE 拡張 (2番目に定義)
INSERT /process BEFORE
  EXECUTE 事前処理2
END

; 第1 AFTER 拡張 (最初に定義)
INSERT /process AFTER
  EXECUTE 事後処理1
END

; 第2 AFTER 拡張 (2番目に定義)
INSERT /process AFTER
  EMIT ProcessCompleted WITH result = :result
  EXECUTE 事後処理2
END

; 合成結果: AOPパターン (BEFORE=逆順、AFTER=順順)
; 1. EXECUTE 事前処理2 (BEFORE #2 - 後定義が先実行)
; 2. SET :prepared = true (BEFORE #1)
; 3. EXECUTE 事前処理1 (BEFORE #1)
; 4. EXECUTE メイン処理 (元BODY)
; 5. EXECUTE 事後処理1 (AFTER #1 - 先定義が先実行)
; 6. EMIT ProcessCompleted (AFTER #2)
; 7. EXECUTE 事後処理2 (AFTER #2)

END DEF
```

#### INSERT 実行規則と制約

```DSL
BEGIN RULE DEF

RULE INSERT execution order:
  DEFINITION_ORDER:
    LET insertion_sequence = [INSERT_1, INSERT_2, ..., INSERT_n]
    WHERE insertion_sequence is ordered by definition appearance

  BEFORE execution order (LIFO/stack):
    FOR BEFORE insertions in REVERSE(insertion_sequence):
      EXECUTE insertion body
    EFFECT: last-defined executes first

  AFTER execution order (FIFO/queue):
    FOR AFTER insertions in insertion_sequence:
      EXECUTE insertion body
    EFFECT: first-defined executes first

RULE INSERT composition:
  EXECUTION_SEQUENCE:
    1. EXECUTE all BEFORE insertions (in reverse definition order)
    2. EXECUTE original command body
    3. EXECUTE all AFTER insertions (in definition order)

  CONSTRAINT sequentiality:
    All BEFORE blocks MUST complete before original body starts
    Original body MUST complete before any AFTER blocks start
    No interleaving is permitted

  NOTE: この順序は一般的なAOP/ミドルウェアパターンと一致します
        - BEFORE = 前処理フック (最後に追加したフックが最初に実行)
        - AFTER = 後処理フック (最初に追加したフックが最初に実行)

RULE INSERT priority extension (reserved for future):
  STATUS: UNIMPLEMENTED
  RESERVATION: explicit priority control via PRIORITY attribute

  CURRENT_BEHAVIOR:
    execution order determined by definition sequence only

  RESERVED_SYNTAX:
    INSERT <command> BEFORE PRIORITY = <integer>
      <body>
    END

    INSERT <command> AFTER PRIORITY = <integer>
      <body>
    END

  RESERVED_SEMANTICS:
    EXECUTION_ORDER: sorted by PRIORITY value (ascending)
    HIGHER_PRIORITY: executes before LOWER_PRIORITY
    PRIORITY_TIE: fall back to definition order

  PURPOSE: prevent future breaking changes by reserving syntax

  NOTE: この拡張は現在未実装です。この記述は将来の拡張のための構文予約であり、
        現在のパーサーはこの構文を受理しません。

RULE INSERT CONSTRAINT composition:
  SYNTAX:
    INSERT blocks MAY contain CONSTRAINT clauses

  COMPOSITION_RULE:
    LET original_constraints = constraints from DEF block
    LET insert_constraints = constraints from INSERT blocks
    LET composed_constraints = original_constraints ∪ insert_constraints

    COMBINED_CONSTRAINT = AND(composed_constraints)

  SEMANTICS:
    ALL constraints MUST be satisfied at execution time
    IF any constraint is violated THEN execution is forbidden

  EXAMPLE (formal):
    GIVEN:
      DEF /review THEN
        EXECUTE レビュー処理
        CONSTRAINT: {SESSION_PHASE=waiting}
      END

      INSERT /review BEFORE
        SET :prepared = true
        CONSTRAINT: {:buffer is not empty}
      END

    RESULT:
      composed_constraints = {SESSION_PHASE=waiting, :buffer is not empty}
      EXECUTION is permitted if and only if:
        SESSION_PHASE=waiting AND :buffer is not empty

  NOTE: 制約は論理AND結合されるため、INSERT により制約は追加のみ可能で、
        既存の制約を緩和することはできません。

END DEF
```

### イベントシステム

```DSL
BEGIN MACRO DEF

; イベント型定義
DEF EVENT ProcessStarted WITH command:text, mode:mode THEN END
DEF EVENT ProcessInterrupted WITH reason:text, previous_mode:mode THEN END

; イベント発火
DEF /start_process THEN
  EMIT ProcessStarted WITH command = "/review", mode = SESSION_PHASE
  EXECUTE 処理実行
END

; リスナー登録
ON ProcessInterrupted DO
  SET SESSION_PHASE = :previous_mode
  CLEAR ALL ON REVIEW
END

END DEF
```

```DSL
BEGIN RULE DEF

RULE event_handler_session_phase_restriction:
  CONSTRAINT permitted_usage:
    SET SESSION_PHASE within EVENT handler is RESTRICTED to:
      - restoration: return to :previous_mode after abnormal termination
      - correction: transition to safe state when processing is interrupted
      - rollback: return to initial state on error

  CONSTRAINT forbidden_usage:
    SET SESSION_PHASE MUST NOT be used for:
      - normal_flow_control: state transitions that SHOULD be implemented via COMMAND
      - conditional_branching: dynamically selecting from multiple transition targets
      - arbitrary_transition: operations that bypass SESSION_PHASE transition rules

  RATIONALE:
    EVENT handlers are for exceptional/error recovery ONLY
    Normal state transitions MUST be explicit via COMMAND
    This separation maintains predictable control flow

  EXAMPLE permitted:
    ON ProcessInterrupted DO
      SET SESSION_PHASE = :previous_mode  ; restoration usage
    END

  EXAMPLE forbidden:
    ON SomeEvent DO
      SET SESSION_PHASE = input  ; normal flow should use COMMAND
    END

  ENFORCEMENT:
    LLM MUST reject EVENT handlers that violate forbidden_usage constraint

END DEF
```

### 構文要素の意味

```DSL
BEGIN MACRO DEF

; SESSION_PHASE: 状態機械定義 (左から右へ遷移可能、最初が初期状態)
DEF SESSION_PHASE state1 AS "状態1", state2 AS "状態2", state3 AS "状態3" THEN
  SET INITIAL_SESSION_PHASE = state1
END

; AS: 識別子の表示名定義
RULE AS:
  SYNTAX:
    identifier AS "display_name"

  CONSTRAINT identifier_format:
    identifier MUST be ASCII characters
    RECOMMENDED format: snake_case

  CONSTRAINT display_name_format:
    display_name CAN contain any characters (including Japanese)
    display_name is for presentation ONLY

  SEMANTICS:
    identifier: used in code references and programmatic access
    display_name: used in LLM output and human-readable contexts

  USAGE:
    CODE_REFERENCE => USE identifier
    LLM_OUTPUT => PREFER display_name over identifier

  APPLICABILITY:
    AS clause CAN be used in:
      - SESSION_PHASE state definitions
      - FIELD definitions in OUTPUT/LOCATION
      - Any identifier requiring human-readable display name

  EXAMPLE:
    DEF SESSION_PHASE command AS "コマンド", input AS "入力", waiting AS "待機" THEN
      ...
    END

    FIELD finding_content: text
    FIELD section_id: <section-id>

; EVENT: イベント駆動システムの哲学
RULE event_session_phase_separation_of_concerns:
  DESIGN_PRINCIPLE:
    Clear separation of concerns between EVENT (trigger) and SESSION_PHASE (execution state)

  EVENT_RESPONSIBILITY:
    ROLE: notification ONLY
    PURPOSE:
      - signal processing start/completion/interruption
      - trigger event handlers
    CONSTRAINT:
      EVENT MUST NOT directly dictate state transitions
      EVENT is trigger, NOT controller

  SESSION_PHASE_RESPONSIBILITY:
    ROLE: execution state representation
    CONSTRAINT:
      SESSION_PHASE MUST be changed explicitly via SET statement
      Implicit state changes are FORBIDDEN

  HANDLER_SEMANTICS:
    SET within EVENT handler is PERMITTED
    INTERPRETATION:
      NOT: "EVENT changes SESSION_PHASE" (implicit causation)
      BUT: "handler executes SET statement" (explicit operation)

  FORMALIZATION:
    ON event_name DO
      SET SESSION_PHASE = new_state  ; explicit SET operation by handler
    END

    event_name itself DOES NOT change SESSION_PHASE
    Handler code (SET statement) changes SESSION_PHASE

; COMMAND: コマンド定義 (/ プレフィックス、パラメータ指定)
DEF /cmd <required_param> [<optional_param> ..] THEN
  EXECUTE コマンド実行
END

; VAR: 変数宣言 (: プレフィックス、初期値設定可能)
DEF VAR SESSION :example = "initial_value" THEN
  CLEARBY /reset
END

; PRIORITY: 優先度レベル定義
DEF PRIORITY critical, high, medium, low THEN
  LEVEL_DEFINITIONS:
    critical: immediate action required
    high: prioritized response
    medium: normal response
    low: deferred response

  RULE PRIORITY positioning statement:
    SEMANTICS:
      PRIORITY is NOT a condition that determines applicability or generation
      PRIORITY IS a selection guideline for conflict resolution

    CLARIFICATION:
      FUNCTION_1: display priority level in OUTPUT generation
      FUNCTION_2: weighting mechanism when multiple evaluated findings conflict
      NON_FUNCTION_1: PRIORITY DOES NOT control evaluation process execution order
      NON_FUNCTION_2: PRIORITY DOES NOT determine applicability of findings

    CORRECT_USAGE (examples):
      - IF multiple findings apply to same location THEN prefer high over critical in display
      - SET PRIORITY field value in OUTPUT format definition

    INCORRECT_USAGE (examples):
      - SKIP evaluation because PRIORITY=low (execution order control)
      - FORCE output because PRIORITY=high (applicability determination)

  RULE priority_essence_detailed:
    ESSENCE:
      PRIORITY is a "conflict resolution heuristic for simultaneously applicable rules"

    SEMANTICS:
      WHEN multiple findings/improvements conflict:
        PREFER higher priority perspective
      END

      PRIORITY represents evaluation "weight", NOT "order" or "condition"
      PRIORITY is "selection guideline for conflicts", NOT application sequence

  CONSTRAINT PRIORITY semantic scope:
    APPLICABILITY:
      PRIORITY is semantic structure VALID ONLY in OUTPUT context

    FORBIDDEN_USAGE:
      - evaluation order control (NOT for INSERT sequence control)
      - execution condition determination (NOT for RULE boolean evaluation)
      - command execution permission (NOT for SESSION_PHASE constraints)

    PERMITTED_USAGE:
      - FIELD importance display in OUTPUT definitions
      - LLM judgment criteria during output generation
      - conflict resolution for simultaneously applicable rules

  RULE OUTPUT context definition:
    DEFINITION:
      "OUTPUT context" refers to:
        - FIELD importance display in DEF OUTPUT format definitions
        - output from review/generation commands (/review, /write, etc.)

    SCOPE:
      PRIORITY is referenced ONLY in these contexts

  RULE PRIORITY vs RULE disambiguation:
    TYPE_DISTINCTION:
      "PRIORITY" => priority level definition (judgment material)
      "RULE" => constraint/validation rule definition (structural constraint)

    SEMANTIC_ROLE:
      PRIORITY: provides judgment guidance for LLM
      RULE: enforces structural constraints
END

; OUTPUT: 出力フォーマット定義 (簡易版・DSL作成者向け)
; NOTE: 実装の完全なスキーマは「3.6 出力構造化の拡張」を参照
DEF OUTPUT レビュー結果 WITH LOCATION THEN
  CORE_FIELDS (simplified notation):
    FIELD finding_content: text
    FIELD importance: priority_level

  COMPLETE_IMPLEMENTATION_REQUIREMENTS:
    REQUIRED_FIELDS:
      - finding_type AS "指摘種別"
      - CATEGORY AS "カテゴリー" (categorization)
      - PRIORITY AS "優先度" (priority level)
      - identifier AS "識別子"
      - location AS "該当箇所"
      - rationale AS "根拠"

    OPTIONAL_FIELDS:
      - VIOLATION (violation severity)
      - STATUS (processing status)

    REFERENCE:
      Complete schema: "### 出力構造化の拡張" (line 1929)

  CONSTRAINT WITH LOCATION 効果:
    SEMANTICS:
      WITH LOCATION modifier triggers automatic field addition

    EFFECT:
      AUTO_ADD: "location" field according to LOCATION definition
      FORMAT: "section_name.paragraph[N].sentence[M]"

    REFERENCE:
      LOCATION definition details: "### 共通文章位置" (line 1909)

  CROSS_REFERENCES:
    - Complete schema: "### 出力構造化の拡張" (line 1929)
    - LOCATION definition: "### 共通文章位置" (line 1909)
    - VIOLATION side effects: "#### VIOLATION/STATUS enum定義" (line 2161)
END

; LOCATION: 文書位置識別構造 (FIELD/RULE で要素定義)
DEF LOCATION 文章位置 THEN
  FIELD section_id: 見出し[番号]
  FIELD node_type: paragraph | list_item
  RULE sentence_delimiter: 句点"。" | "？" | "！" | ":"
END

; <any-text> 系の制約と意味論
CONSTRAINT any-text usage:
  FORBIDDEN_OPERATIONS:
    - syntax element identification, comparison, or branching
    - programmatic processing of content

  SEMANTICS:
    <any-text> MUST NOT be used for structural control flow

RULE any-text semantics:
  DEFINITION:
    <any-text> is natural language text WITHOUT structural interpretation

  INTERPRETATION:
    TARGET for LLM semantic analysis
    NOT_TARGET for runtime control flow

  FORMALIZATION:
    <any-text> ∈ NaturalLanguage
    <any-text> ∉ ProgrammaticControl

CONSTRAINT description usage:
  FORBIDDEN_OPERATIONS:
    - runtime judgment, control flow, or conditional branching

  SEMANTICS:
    <description> is explanation-only text
    <description> MUST NOT affect execution behavior

RULE description semantics:
  PURPOSE:
    <description> provides guidance/instructions for LLM ONLY

  SCOPE:
    APPLICABLE: LLM understanding and context
    NOT_APPLICABLE: execution control or decision making

CONSTRAINT label-text usage:
  FORBIDDEN_OPERATIONS:
    - use as internal identifier
    - use as comparison/search key

  SEMANTICS:
    <label-text> is for display purposes ONLY
    <label-text> MUST NOT participate in programmatic logic

RULE label-text semantics:
  PURPOSE:
    <label-text> is display name ONLY

  USAGE_SCOPE:
    PERMITTED:
      - AS clause Japanese display names
      - FIELD names for human-readable output

    FORBIDDEN:
      - internal symbol resolution
      - programmatic key matching

CONSTRAINT free-text usage:
  FORBIDDEN_OPERATIONS:
    - parsing or syntactic analysis
    - treatment as structured data

  SEMANTICS:
    <free-text> has no structural interpretation
    <free-text> is opaque to DSL processor

RULE free-text semantics:
  DEFINITION:
    <free-text> is unstructured free-form content

  PURPOSE:
    EXCLUSIVE_USE: multiline/heredoc long-form content

  SCOPE:
    <free-text> provides narrative content WITHOUT structural constraints

RULE any-text undefined behavior:
  CONSTRAINT prohibited_decision_usage:
    <any-text> series elements MUST NOT be used as decision criteria for:
      - SESSION_PHASE transitions
      - COMMAND permission determination
      - conditional branching logic

  SPECIFICATION:
    IF <any-text> used for control flow decisions THEN
      behavior is UNDEFINED
      result is UndefinedBehavior
    END

  FORMALIZATION:
    control_flow_decision(<any-text>) => UndefinedBehavior

; CONSTRAINT 句: 定義内制約の明示化
RULE CONSTRAINT clause syntax:
  PLACEMENT:
    CONSTRAINT clause MUST be placed at end of DEF body

  FORMAT:
    Markdown bullet list format (lines starting with "-")
    Enumerate constraints as list items

  PURPOSE:
    Self-document definition and constraints within same block

  EXAMPLE (formal):
    DEF PRIORITY ... THEN
      <level descriptions>
      CONSTRAINT:
        - 制約1
        - 制約2
    END

RULE CONSTRAINT composition:
  INSERT_CAPABILITY:
    INSERT blocks CAN contain CONSTRAINT clauses

  COMPOSITION_SEMANTICS:
    Multiple CONSTRAINT clauses are combined with logical AND
    LET original_constraints = constraints from DEF
    LET insert_constraints = constraints from INSERT blocks
    COMBINED = original_constraints AND insert_constraints

  ENFORCEMENT:
    ALL constraints (original DEF + INSERT additions) MUST be satisfied

END DEF
```

### 停止条件・エラーハンドリング

```DSL
BEGIN RULE DEF

RULE termination_condition_specification:
  SEMANTICS:
    EXECUTE statement termination depends on LLM judgment when explicit termination conditions are absent

  PROMPT_DESIGNER_RESPONSIBILITY:
    Termination conditions SHOULD be explicitly specified via:
      - CONSTRAINT clause: define execution constraints
      - RULE clause: describe completion conditions
      - EVENT emission: signal processing termination

  BEHAVIOR:
    IF termination_condition is explicit THEN
      EXECUTE until condition satisfied
    ELSE
      LLM determines termination based on context and implicit knowledge
    END

RULE insufficient_information_behavior:
  PRECONDITION:
    Required information is missing for processing

  STANDARD_PROTOCOL:
    1. EMIT ProcessFailed event
    2. OUTPUT missing information as "Open Questions"
    3. SET status = INCOMPLETE
    4. RESTORE SESSION_PHASE to safe state (command OR waiting)

  EFFECT:
    Processing terminates gracefully with actionable user feedback

  EXAMPLE (formal):
    IF :buffer is empty THEN
      EMIT ProcessFailed WITH error = "入力内容が空です"
      EXECUTE "Open Questions: 記事内容を入力してください"
      SET SESSION_PHASE = command
    END

  CONSTRAINT safe_state_transition:
    SESSION_PHASE MUST be {command, waiting} after protocol completion

RULE indeterminate_fallback_strategy:
  PRECONDITION:
    LLM cannot determine appropriate action

  FALLBACK_STRATEGY (priority order):
    PRIORITY 1: CHECK constraints defined in CONSTRAINT clause
    PRIORITY 2: FOLLOW :remark variable instructions
    PRIORITY 3: APPLY conservative default (no modification, no output)
    PRIORITY 4: OUTPUT explicit statement of uncertainty

  BEHAVIOR:
    FOR priority IN [1, 2, 3, 4]:
      IF strategy(priority) provides decision THEN
        EXECUTE decision
        BREAK
      END
    END

  CONSTRAINT conservative_principle:
    DEFAULT action MUST NOT introduce destructive changes

RULE error_state_restoration:
  PRECONDITION:
    Error occurred during processing

  RESTORATION_PRINCIPLES:
    EXECUTE_MODE:
      IF EXECUTE_MODE = processing THEN
        SET EXECUTE_MODE = idle
      END

    SESSION_PHASE:
      SET SESSION_PHASE = {command OR waiting}
      CHOOSE based on error context

    VARIABLE_SCOPE_PERSISTENCE:
      SESSION scope variables: RETAIN
      REVIEW scope variables: RETAIN (/begin explicitly clears)

  EXCEPTION forced_termination:
    ON /exit command:
      CLEAR all variables (all scopes)
      RESET all state to initial values

  EFFECT:
    System returns to safe, recoverable state while preserving user data

RULE reproducibility_guarantee:
  GOAL:
    Identical input + identical prompt => identical output (deterministic behavior)

  CONSTRAINT probabilistic_nature:
    Complete reproducibility is NOT guaranteed due to LLM stochastic properties

  RECOMMENDATION:
    FOR critical decisions:
      USE explicit CONSTRAINT/RULE specifications
      AVOID relying on implicit LLM behavior

  SEMANTICS:
    Reproducibility is best-effort, not guaranteed
    Determinism REQUIRES explicit specification of decision logic

END DEF
```

### 非校閲領域 (最優先)

```DSL
BEGIN MACRO DEF

RULE non_proofreading_zones:
  SEMANTICS:
    Defines zones excluded from proofreading/review to prevent self-recursion and DSL corruption

  EXCLUDED_ZONES:
    ZONE_1: DSL definition blocks
      SCOPE: Part 1, Part 2 grammar definitions
      APPLICABILITY: syntax and semantics specifications

    ZONE_2: Macro definitions
      SCOPE: DEF, RULE, CONSTRAINT, CATEGORY, PRIORITY definitions
      RATIONALE: prevent modification of control structures

    ZONE_3: Input blocks
      SCOPE: BEGIN INPUT / END INPUT blocks
      RATIONALE: preserve user input integrity

    ZONE_4: Appendix sections
      SCOPE: all appendix content
      RATIONALE: reference material, not operational code

    ZONE_5: Code block syntax
      SCOPE: syntax within code blocks
      ALLOWED_MODIFICATION: typo correction ONLY
      FORBIDDEN_MODIFICATION: structural or semantic changes

  CONSTRAINT self_recursion_prevention:
    PURPOSE: physically block self-recursion risk
    EFFECT: LLM MUST NOT apply review rules to review rule definitions
    FORMALIZATION: proofreading(proofreading_rules) => FORBIDDEN

  CONSTRAINT dsl_integrity_preservation:
    PURPOSE: prevent DSL definition tampering
    EFFECT: DSL specifications are immutable during review operations
    FORMALIZATION: modify(DSL_definition) => FORBIDDEN

  CONSTRAINT meta_object_level_separation:
    PURPOSE: prevent confusion between meta-level and object-level
    EFFECT: meta-level definitions (DSL) remain distinct from object-level content (articles)
    FORMALIZATION: meta_level ∩ object_level = ∅

  EXCEPTION frontmatter:
    SCOPE: YAML frontmatter
    ALLOWED_MODIFICATION:
      - grammar correction
      - quotation mark correction
    FORBIDDEN_MODIFICATION:
      - semantic changes
      - structure changes

  EXCEPTION dsl_explanatory_text:
    SCOPE: Markdown explanatory text describing DSL
    STATUS: subject to proofreading
    DISTINCTION:
      DSL definitions themselves => EXCLUDED
      Explanatory prose about DSL => INCLUDED

END DEF
```

### フォールバック規則

LLM が仕様を守らない場合の縮退動作を定義します。

#### コマンド解釈失敗時

| 状況               | フォールバック動作                  | ACCEPTANCE/EXEC    |
| ------------------ | ----------------------------------- | ------------------ |
| コマンド不明       | 基本レビューモードに縮退            | ACCEPTANCE=PENDING |
| パラメータ欠落     | デフォルト値使用 (全セクション対象) | 現状維持           |
| コマンド構文エラー | エラー通知 → `/begin` 再入力促進    | ACCEPTANCE=PENDING |

**フォールバック例**:

<!-- cspell:words reviw -->

```bash
/reviw <typo>     → 基本レビューモードに縮退、全セクション対象
/review Secton1   → Section1 を全セクション対象として処理
```

**NOTE**: 縮退時は警告メッセージ出力。ユーザー修正を促すが処理は継続。

#### 変数解決失敗時

| 状況         | フォールバック動作             | 出力形式               |
| ------------ | ------------------------------ | ---------------------- |
| 変数未定義   | `[UNRESOLVED:変数名]` 強制付与 | エラーマーカー表示     |
| 変数型不一致 | 文字列として扱う               | 型変換試行             |
| スコープ違反 | SESSION スコープで再検索       | 最大スコープにフォール |

**フォールバック例**:

```bash
:undefined_var  → "[UNRESOLVED:undefined_var]"
:buffer (未設定) → "[UNRESOLVED:buffer] (入力なし)"
```

**NOTE**: `[UNRESOLVED:*]` マーカーは OUTPUT に含まれる。デバッグ・診断用途。

#### 状態遷移違反時

| 状況                | フォールバック動作            | ACCEPTANCE/EXEC |
| ------------------- | ----------------------------- | --------------- |
| ACCEPTANCE 自動遷移 | ACCEPTANCE=PENDING に強制復帰 | SESSION 保持    |
| EXEC_MODE 再入      | 実行拒否 → エラー通知         | 現状維持        |
| 禁止遷移試行        | 遷移キャンセル → 警告出力     | 現状維持        |

**NOTE**: 状態遷移違反は重大エラー。処理中断し、ユーザー介入を要求。

#### OUTPUT 生成失敗時

| 状況                         | フォールバック動作                    | 内容                | スキーマ統合 |
| ---------------------------- | ------------------------------------- | ------------------- | ------------ |
| generation-status=INCOMPLETE | OUTPUT 生成スキップ → 情報不足通知    | Open Questions 出力 | ErrorResult  |
| CATEGORY 判定不能            | `[CATEGORY:unknown]` 付与、PRIORITY=B | デフォルト分類使用  | Finding      |
| PRIORITY 算出失敗            | PRIORITY=B (中優先度)                 | 保守的優先度設定    | Finding      |
| 該当箇所 取得失敗            | "[LOCATION:unresolved]" 付与          | 位置情報不明とき    | Finding      |
| 識別子 生成失敗              | "finding-auto-NNN" 自動生成           | NNN=連番            | Finding      |

**NOTE**: 判定不能時は保守的設定 (PRIORITY=B) を採用。過小評価より過大評価を優先。

スキーマとの統合:

これらのフォールバック動作は「#### OUTPUT 形式スキーマ」(line 1965-2095) の以下で実装されます。

- `generation-status=INCOMPLETE` → `ErrorResult` バリアント使用
- `CATEGORY: unknown` → Finding の CATEGORY enum で定義済み (line 1989)
- `PRIORITY=B` → Finding の PRIORITY デフォルト値
- `[LOCATION:unresolved]` → Finding.該当箇所の検証エラー時挙動
- `finding-auto-NNN` → Finding.識別子のフォールバック生成

クロスリファレンス:

- CATEGORY enum: line 1989-1992
- PRIORITY enum: line 2010-2013
- ErrorResult 定義: line 2064-2081

#### 制約違反時の処理順序

1. CONSTRAINT 確認
2. :remark 優先適用 (ユーザー指定)
3. フォールバック規則適用
4. 保守的設定採用

**CONSTRAINT**: フォールバック規則適用時も `:remark` > システムデフォルトの優先順位を維持。

#### 実装例

```DSL
DEF FALLBACK ValidationFailed THEN
  SET generation-status = INCOMPLETE
  EMIT ProcessFailed WITH error="[UNRESOLVED:buffer]"
  SET ACCEPTANCE = PENDING
  EXECUTE "Open Questions 出力：必須情報が不足しています"
END

DEF FALLBACK CommandNotFound THEN
  EXECUTE "警告：不明なコマンドを検出。基本レビューモードに縮退します"
  SET ACCEPTANCE = PENDING
  /review  ; 基本レビューにフォールバック
END

DEF FALLBACK CategoryUnknown THEN
  SET :category = "[CATEGORY:unknown]"
  SET :priority = "B"  ; 保守的優先度
  NOTE: 判定不能時のデフォルト分類
END
```

**NOTE**: フォールバック定義は各プロンプトファイルで `INSERT` により拡張可能。プロンプト固有のフォールバック戦略を定義できる。

---

## Part 3: Policy Layer (ポリシー層)

本セクションでは、DSL を使用したレビューシステムの基本方針と制約規則を定義します。

### 3.1 Review Philosophy

レビューシステムの基本原則を形式化します。

```DSL
BEGIN POLICY DEF

RULE review_philosophy:
  OBJECTIVE_FUNCTION:
    PRIMARY_GOAL:
      - QUALITY_IMPROVEMENT: enhance technical accuracy and readability
      - AUTHOR_INTENT_RESPECT: preserve author's voice and design decisions

    NON_GOAL:
      - REWRITE: complete article rewriting
      - STYLE_OVERRIDE: imposing reviewer's style preferences

  INTERVENTION_LEVELS:
    LEVEL HIGH:
      TRIGGER:
        - TECHNICAL_ERROR: API misuse, incorrect specifications
        - API_MISUSE: wrong usage patterns, deprecated methods
      EVIDENCE_REQUIREMENT:
        :link verified OR official_documentation
      PRIORITY_MAPPING: A
      EXAMPLES:
        - "API仕様の誤記 (公式Docと不一致)"
        - "コード例の実行エラー (文法・ランタイム)"

    LEVEL MEDIUM:
      TRIGGER:
        - STRUCTURAL_ISSUE: organizational problems in content
        - LOGIC_CONTRADICTION: inconsistencies within document
      EVIDENCE_REQUIREMENT:
        cross_reference within document (multiple locations)
      PRIORITY_MAPPING: B
      EXAMPLES:
        - "論理展開の矛盾 (前半と後半で主張が逆転)"
        - "セクション構成の改善 (階層構造の最適化)"

    LEVEL LOW:
      TRIGGER:
        - EXPRESSION_OPTIMIZATION: stylistic improvements
      EVIDENCE_REQUIREMENT:
        best_practice guidelines
      PRIORITY_MAPPING: C
      EXAMPLES:
        - "冗長表現の簡潔化"
        - "用語の統一 (同一概念への一貫した命名)"

  TONE_BOUNDARIES:
    UPPER_LIMIT (acceptable):
      - TECHNICAL_ERROR_EXPLICIT: clear identification of technical errors
      - CONCRETE_ALTERNATIVE: specific alternative proposals
      - QUESTION_FORM: questions to confirm author's intent

    LOWER_LIMIT (unacceptable):
      - SUBJECTIVE_PREFERENCE: imposing personal style preferences
      - VAGUE_IMPROVEMENT: ambiguous "please improve" feedback
      - ONE_SIDED_CRITICISM: unilateral negation without alternatives

  MODIFICATION_PERMISSIONS:
    PERMITTED:
      - TYPO_FIX: spelling error correction
      - GRAMMAR_CORRECTION: grammatical error fixing
      - TERM_UNIFICATION: consistent terminology usage
      - STRUCTURAL_CLARIFICATION: improving structure clarity

    PROHIBITED:
      - CLAIM_ALTERATION: fundamental change to author's technical claims
      - DESIGN_REWRITE: complete redesign of code example philosophy
      - STYLE_REPLACEMENT: wholesale replacement of author's writing style
      - SECTION_DELETION: removing sections or major structural changes

  VIOLATION_TYPES:
    STYLE_OVERRIDE:
      DESCRIPTION: forcing reviewer's style over author's intent
      PENALTY: PRIORITY => D (降格)

    INTENT_DISREGARD:
      DESCRIPTION: ignoring explicit author intent
      PENALTY: PRIORITY => D + STATUS=USER_CONFIRM (降格+確認要求)

    SUBJECTIVE_BIAS:
      DESCRIPTION: applying subjective bias without objective rationale
      PENALTY: PRIORITY => E (最低優先度へ降格)

    SCOPE_EXCESS:
      DESCRIPTION: exceeding appropriate review scope
      PENALTY: PRIORITY => D (降格)

  CONSTRAINT philosophy_enforcement:
    LLM MUST self-detect violations during review process
    IF violation detected THEN
      APPLY corresponding VIOLATION label
      APPLY automatic PRIORITY demotion
    END

    OVERRIDE: :remark variable CAN explicitly permit exceptions

END DEF
```

### 3.2 Fail-Fast Policy

レビュー前提条件を満たさない場合の判定基準を定義します。

````DSL
BEGIN POLICY DEF

RULE fail_fast_policy:
  SEMANTICS:
    Defines preconditions for reviewability
    Rejects articles that fail to meet minimum quality thresholds

  DECISION_TREE:
    IF structural_collapse THEN
      SET generation-status = INCOMPLETE
      OUTPUT "Open Questions: 構造崩壊 - 見出し階層を修正してください"
      HALT
    END

    IF technical_fatality THEN
      SET generation-status = INCOMPLETE
      OUTPUT "Open Questions: 技術的致命傷 - コードを修正してください"
      HALT
    END

    IF unreadability THEN
      SET generation-status = INCOMPLETE
      OUTPUT "Open Questions: 可読性未確立 - 論理展開を明確化してください"
      HALT
    END

    IF insufficient_length THEN
      SET generation-status = INCOMPLETE
      OUTPUT "Open Questions: 文章量不足 - 内容を拡充してください"
      HALT
    END

    IF incomplete_content THEN
      SET generation-status = INCOMPLETE
      OUTPUT "Open Questions: 未完成 - TODO/プレースホルダーを完成させてください"
      HALT
    END

  DETECTION_CRITERIA:
    CONDITION structural_collapse:
      DETECTION_METHOD:
        - heading_hierarchy_gap: regex `^#{1,6}` pattern analysis
        - required_section_missing: check for 概要/結論 sections
      THRESHOLD:
        gap > 1 OR (概要 missing OR 結論 missing)
      RATIONALE:
        heading structure破綻 OR essential sections absent => not reviewable

    CONDITION technical_fatality:
      DETECTION_METHOD:
        - unclosed_code_blocks: ``` pair mismatch count
        - api_misuse_chain: consecutive API errors
      THRESHOLD:
        unclosed_blocks > 0 OR api_errors ≥ 3
      RATIONALE:
        non-executable code OR severe API misuse chain => repair cost > rewrite cost

    CONDITION unreadability:
      DETECTION_METHOD:
        - topic_sentence_absence_rate: percentage of paragraphs without topic sentence
        - conjunction_density: ratio of conjunctions to total sentences
      THRESHOLD:
        absence_rate > 50% OR conjunction_density < 10%
      RATIONALE:
        unclear logic flow OR missing topic coherence => not suitable for review

    CONDITION insufficient_length:
      DETECTION_METHOD:
        - unicode_character_count: count excluding code blocks
      THRESHOLD:
        character_count < 500
      RATIONALE:
        article too short => pre-review stage

    CONDITION incomplete_content:
      DETECTION_METHOD:
        - todo_marker_regex: `/TODO|FIXME|TBD|WIP/`
        - placeholder_detection: 箇条書きのみ, メモのみ patterns
      THRESHOLD:
        marker_count ≥ 1 OR placeholder_ratio > 30%
      RATIONALE:
        contains unfinished markers => request completion before review

  CONSTRAINT constructive_feedback_required:
    LLM MUST provide actionable resubmission guidance
    IF fail_fast triggered THEN
      OUTPUT MUST include specific improvement suggestions
      OUTPUT MUST NOT be empty or vague
    END

  CONSTRAINT rejection_semantics:
    Fail-fast rejection means "preconditions not met"
    Fail-fast rejection DOES NOT mean "no room for improvement"
    INTERPRETATION:
      rejection => article is pre-review stage
      rejection ≠ article is beyond hope

  FORMALIZATION:
    LET reviewable = ¬(structural_collapse ∨ technical_fatality ∨ unreadability ∨ insufficient_length ∨ incomplete_content)

    IF reviewable THEN
      PROCEED to review
    ELSE
      HALT with constructive feedback
    END

END DEF
````

### 3.3 Priority Conversion

カテゴリから優先度への写像ルールを定義します。

```DSL
BEGIN POLICY DEF

RULE priority_conversion:
  SEMANTICS:
    Defines mapping from CATEGORY to PRIORITY with violation-based demotion

  CATEGORY_TO_PRIORITY_MAPPING:
    MAPPING inaccuracy:
      IF :link exists AND :link verified THEN
        PRIORITY => A
      ELSE
        PRIORITY => B
      END
      RATIONALE: verified evidence warrants high priority, unverified is medium

    MAPPING inconsistency:
      PRIORITY => B
      RATIONALE: internal contradictions are medium priority

    MAPPING readability:
      PRIORITY => C
      RATIONALE: stylistic improvements are low priority

    MAPPING unknown:
      PRIORITY => B
      RATIONALE: conservative fallback when category indeterminate
      CONSTRAINT: unknown is FALLBACK ONLY, NOT for normal use

  VIOLATION_DEMOTION:
    VIOLATION STYLE_OVERRIDE:
      EFFECT: force PRIORITY = D
      RATIONALE: style imposition violates philosophy

    VIOLATION INTENT_DISREGARD:
      EFFECT: force PRIORITY = D AND STATUS = USER_CONFIRM
      RATIONALE: ignoring author intent requires explicit user confirmation

    VIOLATION SUBJECTIVE_BIAS:
      EFFECT: force PRIORITY = E
      RATIONALE: subjective bias has lowest priority

    VIOLATION SCOPE_EXCESS:
      EFFECT: force PRIORITY = D
      RATIONALE: exceeding scope violates review boundaries

  PRECEDENCE_ORDER:
    PRIORITY_1 (highest): :remark variable override
    PRIORITY_2: VIOLATION demotion
    PRIORITY_3: CATEGORY mapping
    PRIORITY_4 (lowest): system default

    FORMALIZATION:
      LET final_priority =
        IF :remark specifies priority THEN
          :remark.priority
        ELSE IF violation detected THEN
          violation.demotion_priority
        ELSE IF category assigned THEN
          category.mapped_priority
        ELSE
          default_priority
        END

  CONSTRAINT override_mechanism:
    :remark CAN override ALL rules
    :remark precedence > violation precedence > category precedence

  CONSTRAINT automatic_demotion:
    IF finding has VIOLATION label THEN
      APPLY corresponding priority demotion AUTOMATICALLY
      LLM MUST NOT manually override violation demotion
    END

  CONSTRAINT unknown_usage_restriction:
    unknown category is RESERVED for indeterminate fallback
    unknown MUST NOT be used for normal classification
    IF classification possible THEN
      USE specific category (inaccuracy, inconsistency, readability)
    ELSE
      USE unknown AS last resort
    END

END DEF
```

### 3.4 制約規則統合

DSL 全体で適用される重要な制約規則を集約します。

```DSL
BEGIN POLICY DEF

RULE constraint_integration:
  SEMANTICS:
    Consolidates critical constraint rules applicable across entire DSL

  CONSTRAINT philosophy_enforcement:
    RULE violation_detection:
      LLM MUST self-detect violations during review process
      IF violation detected THEN
        APPLY corresponding VIOLATION label
        APPLY automatic PRIORITY demotion per side_effects definition
      END

    RULE philosophy_adherence:
      ALL review output MUST adhere to review_philosophy principles
      OUTPUT MUST respect TONE_BOUNDARIES
      OUTPUT MUST respect MODIFICATION_PERMISSIONS

    EXCEPTION remark_override:
      IF :remark explicitly permits exception THEN
        ALLOW deviation from philosophy constraints
      END

  CONSTRAINT acceptance_principle:
    SEMANTICS:
      ACCEPTANCE represents input/processing boundary, NOT quality evaluation

    RULE pending_silence:
      IF ACCEPTANCE = PENDING THEN
        LLM MUST remain silent
        LLM MUST NOT perform spontaneous actions
        LLM MUST wait for explicit command
      END

    RULE control_authority:
      ACCEPTANCE is "declaration of control authority"
      Spontaneous LLM action is "control authority violation"

      FORMALIZATION:
        spontaneous_action WHILE ACCEPTANCE=PENDING => FORBIDDEN

    RULE explicit_command_requirement:
      ALL processing MUST be initiated by explicit command ONLY
      Implicit triggers are FORBIDDEN

  CONSTRAINT fail_fast_requirements:
    RULE constructive_feedback:
      IF fail_fast triggered THEN
        LLM MUST provide constructive resubmission guidance
        Guidance MUST be specific and actionable
        Empty or vague feedback is FORBIDDEN
      END

    RULE rejection_semantics:
      fail_fast rejection means "preconditions not met"
      fail_fast rejection DOES NOT mean "no room for improvement"

      INTERPRETATION:
        rejection => pre-review stage
        rejection ≠ hopeless article

  CONSTRAINT output_generation_guard:
    APPLICABILITY:
      APPLIES_TO: generative prompts (article-writer.prompt, etc.)
      NOT_APPLIES_TO: review prompts (always output-capable)

    RULE ready_gate:
      IF generation-status = READY THEN
        OUTPUT generation PERMITTED
      ELSE
        OUTPUT generation FORBIDDEN
      END

    RULE incomplete_handling:
      IF generation-status = INCOMPLETE THEN
        OUTPUT generation FORBIDDEN
        TRIGGER ACCEPTANCE => PENDING transition
        REQUEST additional user input
      END

  CONSTRAINT enum_immutability:
    RULE closed_enums:
      CATEGORY enum: closed (extension FORBIDDEN)
      PRIORITY enum: closed (extension FORBIDDEN)
      VIOLATION enum: closed (extension FORBIDDEN)
      STATUS enum: closed (extension FORBIDDEN)

    RULE violation_side_effects:
      IF finding has VIOLATION label THEN
        APPLY automatic PRIORITY demotion per side_effects definition
        Demotion is MANDATORY, NOT optional
      END

    RULE status_side_effects:
      IF finding has STATUS label THEN
        SET review state = on_hold
        AWAIT user response
      END

    RULE combined_labels:
      finding CAN have both VIOLATION + STATUS labels
      Effects are CUMULATIVE:
        APPLY VIOLATION priority demotion
        AND SET STATUS on_hold state
      END

    RULE unknown_restriction:
      unknown category is FALLBACK ONLY
      unknown MUST NOT be used for normal classification

  CONSTRAINT override_mechanism:
    RULE remark_supremacy:
      :remark variable CAN override ALL rules
      :remark precedence is ABSOLUTE

    RULE precedence_hierarchy:
      PRIORITY_1: :remark override
      PRIORITY_2: violation demotion
      PRIORITY_3: category mapping
      PRIORITY_4: system default

      FORMALIZATION:
        :remark > violation > category > default

    RULE fallback_override:
      Even during fallback rule application:
        :remark > system_default
        User intent ALWAYS takes precedence

END DEF
```

### 3.5 Proposal Generation Policy

```DSL
BEGIN POLICY DEF

RULE proposal_generation_policy:
  SEMANTICS:
    Controls automatic generation of concrete improvement proposals from findings

  MODE_DEFINITION:
    AUTO AS "自動生成 (条件付き)":
      DESCRIPTION: Generate proposals selectively based on CATEGORY and constraints
      APPLICABILITY: Production use, safe defaults

    FORCE AS "強制生成 (全件)":
      DESCRIPTION: Generate proposals for ALL findings, including edge cases
      APPLICABILITY: Debug mode, comprehensive review

    OFF AS "生成停止":
      DESCRIPTION: Skip all proposal generation
      APPLICABILITY: Performance optimization, findings-only mode

  MODE_RESOLUTION:
    PRECEDENCE:
      1. Command option (--proposal=<mode>)
         EXAMPLE: /review --proposal=FORCE
         SCOPE: Current command invocation only
         PERSISTENCE: No SESSION variable modification

      2. SESSION variable (:proposal_mode)
         EXAMPLE: /set :proposal_mode = "OFF"
         SCOPE: Session lifetime (/exit to clear)
         PERSISTENCE: Affects all /review invocations until changed

      3. System default (AUTO)
         FALLBACK: No option, no :proposal_mode set
         BEHAVIOR: Safe, conservative defaults

  AUTO_MODE_RULES:
    PRECONDITIONS (ALL required):
      - ACCEPTANCE = ACTIVE
      - meta_state = generated
      - FAIL_FAST = false
      - VIOLATION not in {STYLE_OVERRIDE, INTENT_DISREGARD}

    CATEGORY_BASED_GENERATION:
      inaccuracy → ❌ SKIP
        RATIONALE: Requires factual verification, cannot propose speculative fixes

      inconsistency → ✅ GENERATE
        ALLOWED_TYPES: [clarification, restructure]
        RATIONALE: Structural issues have clear resolution paths

      readability → ✅ GENERATE
        ALLOWED_TYPES: [rephrase]
        RATIONALE: Expression improvements are mechanical

      unknown → ❌ SKIP
        RATIONALE: Cannot propose without understanding the issue

    EXCLUSION_RULES:
      - Finding with VIOLATION label → SKIP
        RATIONALE: Philosophy violations should not have proposals
      - Finding with STATUS label → SKIP
        RATIONALE: Pending clarification, proposal premature
      - rewrite type → PROHIBITED
        RATIONALE: Too invasive for AUTO mode

  FORCE_MODE_RULES:
    GENERATION_POLICY:
      - Generate proposal for ALL findings
      - rewrite type PERMITTED
      - VIOLATION/STATUS findings INCLUDED
      - Ignores FAIL_FAST state (generates even in rejected state)

    USE_CASE:
      - Debugging review quality
      - Comprehensive improvement scenarios
      - Editor-in-chief deep review

  OFF_MODE_RULES:
    BEHAVIOR:
      - proposals array NOT generated
      - Output contains findings only
      - Processing performance improved

    USE_CASE:
      - High-volume batch processing
      - First-pass screening
      - Performance-critical scenarios

CONSTRAINT proposal_integrity:
  REFERENCE_CONSTRAINT:
    proposals MUST reference existing Finding via 識別子
    New findings generation in proposals FORBIDDEN
    VALIDATION: 識別子 format "ref:<finding_identifier>"

  LENGTH_CONSTRAINT:
    proposals.after field ≤ 1 paragraph
    DEFINITION: paragraph = single continuous block (max 1 newline)

  TONE_CONSTRAINT:
    proposals MUST use suggestive tone
    PERMITTED: "〜します", "〜できます", "〜可能です"
    PROHIBITED: "〜してください", "〜すべき", "〜しなければならない"

  TYPE_CONSTRAINT:
    rewrite type PERMITTED only in FORCE mode
    AUTO mode: {clarification, restructure, rephrase} only

  CARDINALITY_CONSTRAINT:
    1 Finding → max 1 Proposal
    Multiple fixes → consolidated into single after field

END DEF
```

---

## Part 4: Common Macros (標準実装)

### 共通モード構造

すべてのプロンプトファイルで使用される標準モード定義:

```DSL
BEGIN MACRO DEF

DEF SESSION_PHASE command AS "コマンド", input AS "入力", waiting AS "待機" THEN
  SEMANTICS:
    User-visible state machine controlling command acceptance and :buffer lifecycle

  INITIALIZATION:
    SET INITIAL_SESSION_PHASE = command

  STATE_MACHINE:
    STATES:
      command AS "コマンド":
        DESCRIPTION: session start state
        INVARIANTS:
          :buffer is empty OR :buffer is cleared
          text input IGNORED (NOT accumulated to :buffer)
        CAPABILITIES:
          session_start: PERMITTED via /begin
        ACCEPTED_COMMANDS: {/begin, /exit}

      input AS "入力":
        DESCRIPTION: article content input state
        INVARIANTS:
          :buffer accumulation ENABLED
          user text input APPENDED to :buffer
        CAPABILITIES:
          input_completion: PERMITTED via /end
        ACCEPTED_COMMANDS: {/set, /reset, /end, /exit}

      waiting AS "待機":
        DESCRIPTION: processing execution wait state
        INVARIANTS:
          :buffer content FROZEN (modification FORBIDDEN)
          waiting state PERSISTS after processing completion
        CAPABILITIES:
          processing_execution: PERMITTED via /review OR /write
          new_session: PERMITTED via /begin
        ACCEPTED_COMMANDS: {/review, /write, /begin, /exit}

    TRANSITIONS:
      ALLOWED:
        command => input:
          TRIGGER: /begin command
          EFFECT:
            - session start
            - ENABLE :buffer accumulation
          PRECONDITION: SESSION_PHASE = command

        input => waiting:
          TRIGGER: /end command
          EFFECT:
            - input completion
            - FREEZE :buffer (immutable)
          PRECONDITION: SESSION_PHASE = input

        waiting => command:
          TRIGGER: /exit command
          EFFECT:
            - session termination
            - RESET :buffer
            - CLEAR all SESSION variables
          PRECONDITION: SESSION_PHASE = waiting

      FORBIDDEN:
        input => command:
          EXCEPTION: /exit command (unconditional termination)
          RATIONALE: prevent mid-input interruption (:buffer consistency guarantee)

        waiting => input:
          RATIONALE: prevent re-editing frozen :buffer (immutability guarantee)
          ALTERNATIVE: use /begin for new session

        command => waiting:
          RATIONALE: prevent input phase skip (:buffer consistency guarantee)
          REQUIREMENT: MUST go through input phase

  CONSTRAINT visibility:
    SESSION_PHASE represents user-visible state
    SESSION_PHASE controls command acceptance logic

  RULE naming_clarification:
    SEMANTICS:
      State names represent processing phases, NOT input types

    CLARIFICATION:
      command: command wait phase (session not started)
      input: input acceptance phase (:buffer under construction)
      waiting: processing wait phase (:buffer finalized)

    COMMAND_ACCEPTANCE:
      ALL SESSION_PHASE states accept commands
      ACCEPTED_COMMANDS differ per state

END

DEF EXECUTE_MODE idle AS "待機中", processing AS "処理中" THEN
  SEMANTICS:
    Internal processing state machine (user-invisible)

  INITIALIZATION:
    SET INITIAL_EXECUTE_MODE = idle

  STATE_MACHINE:
    STATES:
      idle AS "待機中":
        DESCRIPTION: awaiting processing request

      processing AS "処理中":
        DESCRIPTION: internal processing in progress
        INVARIANTS:
          user input is DEFERRED
          re-entry FORBIDDEN

    TRANSITIONS:
      idle => processing:
        TRIGGER: /review OR /write command
        PRECONDITION: SESSION_PHASE = waiting

      processing => idle:
        TRIGGER: processing completion
        EFFECT: return to await state

  CONSTRAINT internal_only:
    EXECUTE_MODE is internal state (user-invisible)
    EXECUTE_MODE transitions ONLY when SESSION_PHASE = waiting

  CONSTRAINT user_input_handling:
    WHILE EXECUTE_MODE = processing:
      user input is DEFERRED (not rejected)
    END

  CONSTRAINT output_restrictions:
    Output constraints during processing defined in Part 2 (lines 582-604)

  CONSTRAINT reentrancy_prevention:
    /review AND /write are non-reentrant
    Reentrancy check: IF EXECUTE_MODE = processing THEN REJECT command

  REFERENCE:
    Output constraints: Part 2, lines 582-604

END

END DEF
```

### 入力セクション構造

すべてのプロンプトファイルでセッション変数を初期化するための標準構造:

```DSL
BEGIN INPUT DEF

STRUCTURE input_section:
  SYNTAX:
    BEGIN INPUT
      <assignments>
    END INPUT

  SEMANTICS:
    Formal declaration block for session variable initialization
    NOT example code, but EXECUTABLE input specification

  ELEMENTS:
    marker_begin AS "入力セクション開始マーカー":
      KEYWORD: "BEGIN INPUT"
      PURPOSE: mark start of initialization block
      BNF_REFERENCE: Part 1, line 49
      BNF_DEFINITION: <input-section> ::= "BEGIN" "INPUT" <assignments> "END" "INPUT"

    assignments AS "変数代入":
      COMMAND: /set :var = value
      FORMATS:
        string: single-line text value
          SYNTAX: /set <:var> = "value"
          USE_CASE: short values (1-line text)

        multiline: bulleted list, multi-line configuration
          SYNTAX: /set <:var> = |
                    - line1
                    - line2
          USE_CASE: bullet lists, multiple config values

        heredoc: structured long-form content
          SYNTAX: /set <:var> = """"
                    <Markdown or structured content>
                  """"
          USE_CASE: Markdown documents, structured long text

    marker_end AS "入力セクション終了マーカー":
      KEYWORD: "END INPUT"
      PURPOSE: mark end of initialization block

  FORMAL_GUARANTEE:
    LLM MUST interpret this section
    LLM MUST initialize all specified variables
    Variables are EXECUTABLE input, NOT illustrative examples

  EXAMPLE:
    /set :role = |
      - 役割1
      - 役割2

    /set :link = |
      - <URL1> (参照目的: 説明1)
      - <URL2> (参照目的: 説明2)

    /set :remark = "特記事項"

END DEF
```

### 共通コマンド

標準コマンド定義と実行セマンティクス:

```DSL
BEGIN MACRO DEF

DEF /begin AS "入力モード開始" THEN
  SEMANTICS:
    Initiates input session, transitions to input phase

  EXECUTION:
    CLEAR :buffer
    SET SESSION_PHASE = input

  PRECONDITION:
    SESSION_PHASE = command OR SESSION_PHASE = waiting

  EFFECT:
    :buffer accumulation ENABLED
    Session started

END

DEF /end AS "待機モード移行" THEN
  SEMANTICS:
    Finalizes input, transitions to waiting phase

  EXECUTION:
    SET SESSION_PHASE = waiting

  PRECONDITION:
    SESSION_PHASE = input

  EFFECT:
    :buffer FROZEN (immutable)
    Ready for processing commands

END

DEF /exit AS "セッション終了" THEN
  SEMANTICS:
    Terminates session unconditionally

  EXECUTION:
    CLEAR ALL
    SET SESSION_PHASE = command

  PRECONDITION:
    NONE (unconditional termination)

  EFFECT:
    ALL SESSION variables cleared
    ALL REVIEW variables cleared
    Session reset to initial state

END

DEF /reset <:var1> [<:var2> ..] AS "変数リセット" THEN
  SEMANTICS:
    Clears specified variables

  SYNTAX:
    /reset :var1 [:var2 ...]

  EXECUTION:
    CLEAR :var1 [:var2 ...]

  PRECONDITION:
    Specified variables exist

  EFFECT:
    Specified variables set to empty string ""

END

DEF /set <:var> = <value> AS "変数設定" THEN
  SEMANTICS:
    Assigns value to variable

  SYNTAX_VARIANTS:
    string AS "単一行文字列":
      SYNTAX: /set <:var> = "value"
      USE_CASE: short values (1-line text)

    multiline AS "複数行文字列":
      SYNTAX: /set <:var> = |
                - line1
                - line2
      USE_CASE: bullet lists, multiple config values

    heredoc AS "構造化テキスト":
      SYNTAX: /set <:var> = """"
                <Markdown or structured content>
              """"
      USE_CASE: Markdown documents, structured long text

  EXECUTION:
    SET :var = <value>

  SCOPE_RESOLUTION:
    Variable scope (SESSION/REVIEW) determined by DEF VAR declaration

  OVERWRITE_RULE:
    IF :var already exists in same scope THEN
      OVERWRITE with new value
    ELSE
      CREATE new variable
    END

  LIFETIME:
    SESSION scope: valid until /exit
    REVIEW scope: valid until /begin

END

END DEF
```

#### /set 実行前提条件

変数依存コマンドの前提条件とバリデーション:

```DSL
BEGIN RULE DEF

RULE variable_dependent_command_preconditions:
  SEMANTICS:
    Commands depending on variables MUST validate prerequisites before execution

  VALIDATION_STEPS:
    STEP 1: required_variable_existence_check
      VERIFY all required variables exist
      IF any required variable missing THEN
        EMIT ProcessFailed WITH error = "required variable missing"
        HALT
      END

    STEP 2: link_variable_constraint_check
      APPLY empty_link_behavior constraint
      APPLY reference_article_learning_restriction constraint

  VALIDATION_TIMING:
    Validation executes immediately after SESSION_PHASE => processing transition
    IF validation fails THEN
      EMIT ProcessFailed
    END

CONSTRAINT empty_link_behavior:
  PRECONDITION:
    :link = ""

  LLM_OBLIGATIONS:
    MUST avoid_definitive_technical_assertions:
      FORBIDDEN: absolute statements about technical facts
      REQUIRED: hedging expressions ("generally", "typically", "usually")

    MUST avoid_specific_details:
      FORBIDDEN: specific version numbers, exact specifications
      REQUIRED: general descriptions without concrete implementation details

  EXAMPLES:
    FORBIDDEN: "React 18 では Suspense が安定版になりました"
    PERMITTED: "React の最近のバージョンでは Suspense の機能が拡充されています"

  RATIONALE:
    Without verification sources, LLM cannot assert technical facts with certainty

CONSTRAINT reference_article_learning_restriction:
  PRECONDITION:
    :link contains reference articles (eg. zenn.dev/atsushifx)

  PERMITTED_USAGE:
    ABSTRACTION: style tendency abstraction
      LLM MAY learn stylistic direction
      LLM MAY understand tone preferences

  FORBIDDEN_USAGE:
    DIRECT_IMITATION: content/structure/expression direct mimicry
      LLM MUST NOT copy specific structural patterns
      LLM MUST NOT imitate concrete phrasing

  EXAMPLES:
    FORBIDDEN: "参照記事では『〜という構成』を使っているので同じ構成にする"
    PERMITTED: "参照記事の文体は簡潔・直接的な傾向があるため、その方向性で評価する"

  INDEPENDENCE:
    This constraint is INDEPENDENT of empty_link_behavior constraint
    BOTH constraints MAY apply simultaneously

  NOTE:
    Reference articles inform STYLE, NOT content
    Abstraction level: tone/approach, NOT specific patterns

END DEF
```

### 共通変数

標準変数定義とスコープ管理:

```DSL
BEGIN MACRO DEF

DEF VAR SESSION :role AS "役割" THEN
  SEMANTICS:
    User's role or position in context

  SCOPE: SESSION
  LIFETIME: valid until /exit
  CLEARBY: /exit

  DESCRIPTION:
    Specifies user's role, position, or perspective for context-aware processing

END

DEF VAR SESSION :link AS "参考リンク" THEN
  SEMANTICS:
    Reference links/URLs for style tendency abstraction

  SCOPE: SESSION
  LIFETIME: valid until /exit
  CLEARBY: /exit

  DESCRIPTION:
    Reference articles for stylistic direction learning
    USAGE: style tendency abstraction ONLY
    FORBIDDEN: direct content/structure mimicry

  CONSTRAINT:
    See reference_article_learning_restriction (lines 2704-2728)

END

DEF VAR SESSION :remark AS "特記事項" THEN
  SEMANTICS:
    Special notes or additional instructions

  SCOPE: SESSION
  LIFETIME: valid until /exit
  CLEARBY: /exit

  DESCRIPTION:
    User-provided special instructions or remarks
    PRECEDENCE: overrides default rules and mappings

END

DEF VAR REVIEW :buffer AS "入力バッファ" THEN
  SEMANTICS:
    Content accumulated during input phase

  SCOPE: REVIEW
  LIFETIME: valid until /begin
  CLEARBY: /begin

  LIFECYCLE:
    CREATED: /begin command
    ACCUMULATION: SESSION_PHASE = input
    FROZEN: SESSION_PHASE = waiting
    CLEARED: /begin command (new session start)

  DESCRIPTION:
    Article content buffer, immutable after input completion

END

DEF VAR REVIEW :review AS "レビュー結果" THEN
  SEMANTICS:
    Processing result generated during review phase

  SCOPE: REVIEW
  LIFETIME: valid until /begin
  CLEARBY: /begin

  DESCRIPTION:
    Review output or generated content from processing commands

END

END DEF
```

### 共通イベント

標準イベント定義とペイロード仕様:

```DSL
BEGIN MACRO DEF

DEF EVENT ProcessStarted AS "処理開始" WITH command:text, mode:mode THEN
  SEMANTICS:
    Signals command execution initiation

  TRIGGER_TIMING:
    Emitted at command start

  PAYLOAD:
    command AS "コマンド": text
      DESCRIPTION: executed command name
    mode AS "モード": mode
      DESCRIPTION: SESSION_PHASE at execution start

END

DEF EVENT ProcessInterrupted AS "処理中断" WITH reason:text, previous_mode:mode THEN
  SEMANTICS:
    Signals processing interruption

  TRIGGER_TIMING:
    Emitted on abnormal interruption

  PAYLOAD:
    reason AS "理由": text
      DESCRIPTION: interruption reason
    previous_mode AS "前モード": mode
      DESCRIPTION: SESSION_PHASE before interruption

END

DEF EVENT ProcessCompleted AS "処理完了" WITH result:object THEN
  SEMANTICS:
    Signals normal processing completion

  TRIGGER_TIMING:
    Emitted on successful completion

  PAYLOAD:
    result AS "結果": object
      DESCRIPTION: processing result object

END

DEF EVENT ProcessFailed AS "処理失敗" WITH error:text THEN
  SEMANTICS:
    Signals processing failure

  TRIGGER_TIMING:
    Emitted on error occurrence

  PAYLOAD:
    error AS "エラー": text
      DESCRIPTION: error message

  EFFECT:
    Triggers error handling protocol
    May transition to safe state

END

DEF EVENT ModeChanged AS "モード変更" WITH from:mode, to:mode THEN
  SEMANTICS:
    Signals SESSION_PHASE transition

  TRIGGER_TIMING:
    Emitted on SESSION_PHASE transition

  PAYLOAD:
    from AS "変更前": mode
      DESCRIPTION: previous SESSION_PHASE
    to AS "変更後": mode
      DESCRIPTION: new SESSION_PHASE

END

END DEF
```

### 共通文章位置

LOCATION 構造定義と位置指定仕様:

```DSL
BEGIN MACRO DEF

DEF LOCATION 文章位置 AS "document location structure" THEN
  SEMANTICS:
    Hierarchical position specification for document elements

  STRUCTURE:
    FIELD section_id: <section-id>
      DESCRIPTION: section identifier with optional index
      FORMAT: heading_text["[" number "]"]
      EXAMPLE: "導入[2]", "技術詳細"

    FIELD node_type: <node-type>
      DESCRIPTION: document node type
      VALUES: {paragraph, list_item, heading}

    FIELD text_index: <node-index>
      DESCRIPTION: hierarchical node and sentence index
      FORMAT: node_type "[" number "]" ".sentence[" number "]"
      EXAMPLE: "paragraph[0].sentence[1]", "list_item[3].sentence[0]"

  RULES:
    RULE section_id:
      SYNTAX: 見出しテキスト["[" <番号> "]"]
      SEMANTICS: section name with optional numeric index

    RULE node_type:
      SYNTAX: paragraph | list_item | heading
      SEMANTICS: type of document node

    RULE text_index:
      SYNTAX: <node-type> "[" <番号> "]" ".sentence[" <番号> "]"
      SEMANTICS: zero-indexed node and sentence positions

    RULE sentence_delimiter:
      SYNTAX: 句点"。" | "？" | "！" | ":"
      SEMANTICS: Japanese sentence boundary markers

  USAGE:
    MODIFIER: WITH LOCATION
    EFFECT: automatic injection of location field in OUTPUT
    EXAMPLE: OUTPUT レビュー結果 WITH LOCATION THEN ... END

  COMPLETE_FORMAT_EXAMPLE:
    "導入.paragraph[0].sentence[1]"
    "技術詳細[2].list_item[3].sentence[0]"

END

END DEF
```

### OUTPUT Structure Extension AS "出力構造化の拡張"

#### Simple Definition to Detailed Schema Correspondence AS "簡易定義と詳細スキーマの対応関係"

```DSL
BEGIN MACRO DEF

SEMANTICS:
The simple DEF OUTPUT definition (line 1368-1382) maps to detailed schema as follows

CORRESPONDENCE_TABLE:
MAPPING simplified_fields => detailed_schema_fields:
finding_content AS "指摘内容":
MAPS_TO: Finding.content AS "内容"
DESCRIPTION: specific finding content

    importance AS "重要度":
      MAPS_TO: Finding.PRIORITY
      DESCRIPTION: priority level (A-E)

    with_location_modifier AS "(WITH LOCATION)":
      MAPS_TO: Finding.location AS "該当箇所"
      DESCRIPTION: LOCATION format position information

    implicit_fields AS "(暗黙的)":
      MAPS_TO:
        - Finding.finding_type AS "指摘種別"
        - Finding.CATEGORY
        - Finding.identifier AS "識別子"
        - Finding.rationale AS "根拠"
        - Finding.VIOLATION
        - Finding.STATUS
      DESCRIPTION: required and optional additional fields in implementation

NOTES:

- simple_definition: conceptual model for DSL creators
- detailed_schema: strict specification for implementers
- with_location_modifier: automatically adds location AS "該当箇所" field
- implementation: MUST comply with all 9 fields in detailed schema

END DEF
```

#### OUTPUT Format Schema AS "OUTPUT形式スキーマ (厳密定義)"

```DSL
BEGIN MACRO DEF

DEF OUTPUT AS "出力" THEN
  SEMANTICS:
    Discriminated union structure for LLM processing results
    Strict JSON Schema-equivalent type definitions

  META_STATE:
    VALUES: {none, rejected, generated}
    DESCRIPTIONS:
      none AS "未生成":
        CONDITION: generation-status ≠ READY
        MEANING: OUTPUT not yet generated
      rejected AS "拒否":
        VARIANT: RejectResult
        MEANING: review rejected due to fail-fast conditions
      generated AS "正常":
        VARIANTS: {ReviewResult, ErrorResult}
        MEANING: normal processing output

  TYPE: discriminated-union
  DISCRIMINATOR: output_type
  VARIANTS:
    - ReviewResult (meta_state = generated)
    - ErrorResult (meta_state = generated)
    - RejectResult (meta_state = rejected)
END

DEF ReviewResult AS "レビュー結果 (通常ケース)" THEN
  SEMANTICS:
    Normal case review result structure

  STRUCTURE:
    TYPE: object
    REQUIRED_FIELDS: [findings]

  FIELDS:
    FIELD findings:
      TYPE: array
      MIN_ITEMS: 0
      ITEMS: Finding
      DESCRIPTION: list of findings (0 or more)

    FIELD summary:
      TYPE: string?
      OPTIONAL: true
      DESCRIPTION: overall review summary

    FIELD open_questions:
      TYPE: array?
      ITEMS: string
      OPTIONAL: true
      DESCRIPTION: list of unresolved questions
END

DEF Finding AS "個別指摘 (順序固定・必須フィールド明示)" THEN
  SEMANTICS:
    Individual finding object with strict field ordering

  STRUCTURE:
    TYPE: object
    FORMAT: key-value-lines
      SPECIFICATION: "key: value\n" format
    FIELD_ORDER: strict
      ENFORCEMENT: field order MUST be preserved (1→2→3...→9)
    REQUIRED_FIELDS: [finding_type, CATEGORY, PRIORITY, identifier, location, content, rationale]

  FIELDS:
    FIELD finding_type:
      TYPE: enum
      VALUES: ["修正必須", "注意喚起", "判断保留"]
      DESCRIPTIONS:
        "修正必須": clear error, must fix
        "注意喚起": potential problem, confirmation recommended
        "判断保留": insufficient information, user judgment required
      DESCRIPTION: nature classification of finding
      ORDER_POSITION: 1

    FIELD CATEGORY:
      TYPE: enum
      VALUES: ["readability", "inconsistency", "inaccuracy", "unknown"]
      DESCRIPTION: technical classification category
      ORDER_POSITION: 2

    FIELD PRIORITY:
      TYPE: enum
      VALUES: ["A", "B", "C", "D", "E"]
      DESCRIPTION: priority level (A=highest, E=lowest)
      ORDER_POSITION: 3

    FIELD identifier:
      TYPE: string
      PATTERN: "^[a-zA-Z0-9_-]+$"
      UNIQUENESS: session-scoped
      DESCRIPTION: unique identifier within session
      ORDER_POSITION: 4

    FIELD location:
      TYPE: string
      FORMAT: LOCATION
      DESCRIPTION: automatically added by WITH LOCATION modifier
      REFERENCE: LOCATION definition (line 2912-2957)
      FORMAT_SPECIFICATION: "section_name.paragraph[N].sentence[M]"
      EXAMPLES:
        - "導入.paragraph[0].sentence[1]"
        - "技術詳細[2].list_item[3].sentence[0]"
      VALIDATION: conforms to LOCATION definition rules
      ORDER_POSITION: 5

    FIELD content:
      TYPE: string
      MIN_LENGTH: 1
      DESCRIPTION: finding content (required, empty string forbidden)
      ORDER_POSITION: 6

    FIELD rationale:
      TYPE: string
      MIN_LENGTH: 1
      DESCRIPTION: judgment rationale (required, empty string forbidden)
      ORDER_POSITION: 7

    FIELD VIOLATION:
      TYPE: enum?
      VALUES: ["STYLE_OVERRIDE", "INTENT_DISREGARD", "SUBJECTIVE_BIAS", "SCOPE_EXCESS"]
      OPTIONAL: true
      DESCRIPTION: philosophy violation label
      SIDE_EFFECT: automatic PRIORITY demotion to D
      ORDER_POSITION: 8

    FIELD STATUS:
      TYPE: enum?
      VALUES: ["QUESTION_REQUIRED", "CLARIFICATION_NEEDED"]
      OPTIONAL: true
      DESCRIPTION: status label
      ORDER_POSITION: 9

  WITH_LOCATION_MODIFIER:
    TRIGGER: "DEF OUTPUT ... WITH LOCATION"
    EFFECT: automatic addition of location AS "該当箇所" field
    FIELD_INJECTION:
      POSITION: 5
        RATIONALE: after identifier, before content
      FIELD_NAME: location AS "該当箇所"
      FIELD_TYPE: LOCATION
      REQUIRED: true
    LOCATION_DEFINITION_REF: line 2912-2957

  OUTPUT_ORDER:
    ENFORCEMENT: strict
    SEQUENCE:
      1 => finding_type AS "指摘種別"
      2 => CATEGORY
      3 => PRIORITY
      4 => identifier AS "識別子"
      5 => location AS "該当箇所"
      6 => content AS "内容"
      7 => rationale AS "根拠"
      8 => VIOLATION (if exists)
      9 => STATUS (if exists)

  SEPARATORS:
    field_separator: "\n"
      DESCRIPTION: newline between fields
    finding_separator: "\n---\n"
      DESCRIPTION: three-line delimiter between findings (empty line, three hyphens, empty line)
END

DEF ErrorResult AS "エラー結果" THEN
  SEMANTICS:
    Error case output structure

  STRUCTURE:
    TYPE: object
    REQUIRED_FIELDS: [ERROR, REASON]

  FIELDS:
    FIELD ERROR:
      TYPE: enum
      VALUES: ["VALIDATION_FAILED", "BUFFER_UNDEFINED", "PROCESSING_ERROR"]

    FIELD REASON:
      TYPE: string
      MIN_LENGTH: 1

    FIELD open_questions:
      TYPE: array?
      ITEMS: string
      OPTIONAL: true
END

DEF RejectResult AS "レビュー拒否結果" THEN
  SEMANTICS:
    Review rejection result due to fail-fast conditions

  STRUCTURE:
    TYPE: object
    REQUIRED_FIELDS: [REVIEW_REJECTED, REASON, FAIL_FAST_CONDITION]

  FIELDS:
    FIELD REVIEW_REJECTED:
      TYPE: literal
      VALUE: true

    FIELD REASON:
      TYPE: string
      MIN_LENGTH: 1

    FIELD FAIL_FAST_CONDITION:
      TYPE: enum
      VALUES: [
        "structural_collapse",
        "technical_fatality",
        "unreadability",
        "insufficient_length",
        "incomplete_content"
      ]

    FIELD RECOMMENDATION AS "再提出ガイド":
      TYPE: string?
      OPTIONAL: true
      DESCRIPTION: resubmission guidance (recommended)
END

END DEF
```

#### Proposal Format Schema

```DSL
BEGIN MACRO DEF

DEF OUTPUT Proposal AS "改善提案" THEN
  SEMANTICS:
    Concrete improvement proposal referencing a Finding

  SCHEMA:
    type: object
    format: key-value-lines
    field_order: strict
    required: [識別子, 種別, before, after, 根拠]

  FIELD 識別子:
    type: string
    format: "ref:<finding_identifier>"
    constraint: "must reference existing Finding"
    VALIDATION:
      - Extract <finding_identifier>
      - Verify Finding with matching 識別子 exists in findings array
      - Reject if dangling reference

  FIELD 種別:
    type: enum
    values: ["clarification", "restructure", "rephrase", "rewrite"]
    SEMANTICS:
      clarification AS "明確化":
        USE_CASE: Ambiguous expressions → explicit alternatives
        EXAMPLE: "それ" → "前述のデータ構造"

      restructure AS "再構成":
        USE_CASE: Structural issues → reorganized content
        EXAMPLE: Paragraph reordering, bullet list conversion

      rephrase AS "言い換え":
        USE_CASE: Verbose → concise
        EXAMPLE: "〜することができる" → "〜できる"

      rewrite AS "書き直し":
        USE_CASE: Sentence-level reconstruction (FORCE mode only)
        CONSTRAINT: Prohibited in AUTO mode

  FIELD before:
    type: string
    format: "quoted excerpt from :buffer"
    CONSTRAINT:
      - MUST be exact substring match from :buffer
      - NO paraphrasing or approximation
      - Sufficient context for unique identification

  FIELD after:
    type: string
    maxLength: 1_paragraph
    DEFINITION paragraph: single continuous block or 1 newline max
    tone: suggestive ("〜します", "〜できます")
    PROHIBITED: imperative ("〜してください", "〜すべき")

  FIELD 根拠:
    type: string
    minLength: 1
    CONTENT: Explanation of WHY this proposal improves the text
    CONSTRAINT: Must be actionable, not vague

  OUTPUT_ORDER:
    1: 識別子
    2: 種別
    3: before
    4: after
    5: 根拠

  SEPARATORS:
    field_separator: "\n"
    proposal_separator: "\n---\n"

END

DEF OUTPUT ReviewResult WITH proposals AS "レビュー結果 (提案付き)" THEN
  EXTENDS: ReviewResult (base definition)

  FIELD proposals:
    type: array?
    minItems: 0
    items: Proposal
    OPTIONAL: true

  GENERATION_CONDITION:
    IF effective_proposal_mode != OFF THEN
      Generate proposals array per policy rules
    ELSE
      Omit proposals field
    END

  CONSTRAINT referential_integrity:
    EACH Proposal.識別子 MUST match exactly ONE Finding.識別子
    NO dangling references permitted

END

END DEF
```

```DSL
BEGIN RULE DEF

RULE output_meta_state_integration:
SEMANTICS:
The OUTPUT meta_state coordinates with generation-status to control OUTPUT generation

STATE_COORDINATION_TABLE:
MAPPING meta_state × generation-status => OUTPUT variant:
(none, DRAFT/INCOMPLETE):
VARIANT: (not evaluated)
DESCRIPTION: OUTPUT not generated, waiting state

      (generated, READY):
        VARIANT: ReviewResult
        DESCRIPTION: normal review result generation

      (generated, READY):
        VARIANT: ErrorResult
        DESCRIPTION: error result generation

      (rejected, any):
        VARIANT: RejectResult
        DESCRIPTION: review rejection due to fail-fast conditions

CONSTRAINTS:
CONSTRAINT meta_state_none:
CONDITION: meta_state = none
BEHAVIOR: discriminated-union NOT evaluated (OUTPUT not generated)

    CONSTRAINT meta_state_generated_or_rejected:
      CONDITION: meta_state ∈ {generated, rejected}
      BEHAVIOR: corresponding variant is generated

    CONSTRAINT consistency_violation:
      CONDITION: (generation-status = READY) AND (meta_state = none)
      VIOLATION: FORBIDDEN
      RATIONALE: consistency violation

CROSS_REFERENCES:
generation-status definition: line 898-946
OUTPUT generation constraint: line 922-928
fail-fast conditions: line 1980-2085
END

END DEF
```

#### Schema Validation Rules AS "スキーマ検証ルール"

```DSL
BEGIN RULE DEF
RULE schema_validation_rules:
SEMANTICS:
Validation rules for OUTPUT schema compliance

VALIDATION_ITEMS:
ITEM field_ordering:
RULE: output_order strict adherence (1→2→3...→9 sequence)
ON_VIOLATION: schema violation error

    ITEM required_fields:
      RULE: all fields in required array MUST exist
      ON_VIOLATION: schema violation error

    ITEM enum_values:
      RULE: only values within values array are permitted
      ON_VIOLATION: schema violation error

    ITEM identifier_uniqueness:
      RULE: uniqueness session-scoped violation FORBIDDEN
      ON_VIOLATION: duplicate error

    ITEM string_length_constraint:
      RULE: minLength 1 violation FORBIDDEN (empty string not allowed)
      ON_VIOLATION: validation error

    ITEM pattern_constraint:
      RULE: MUST match pattern regular expression
      ON_VIOLATION: format error

    ITEM array_element_count:
      RULE: MUST satisfy minItems constraint
      ON_VIOLATION: validation error

    ITEM delimiter_characters:
      RULE: separator and finding_separator strict adherence
      ON_VIOLATION: parse error

END
END DEF
```

#### Output Format Example AS "出力形式例 (スキーマ準拠)"

```DSL
BEGIN OUTPUT DEF

; Example 1: Critical finding with verified link
指摘種別: 修正必須
CATEGORY: inaccuracy
PRIORITY: A
識別子: finding-001
該当箇所: セクション1.paragraph[0].sentence[1]
内容: API仕様の誤記があります。正しくは `fetch()` ではなく `fetchData()` です。
根拠: 公式ドキュメント (https://example.com/api) で確認しました。

---

; Example 2: Readability suggestion with philosophy violation
指摘種別: 注意喚起
CATEGORY: readability
PRIORITY: C
識別子: finding-002
該当箇所: セクション2.paragraph[2].sentence[0]
内容: 冗長な表現を簡潔にすることを推奨します。
根拠: 技術文書では明瞭さが重要です。
VIOLATION: STYLE_OVERRIDE

NOTES:

- field_order: strict 1→9 sequence (follows output_order in schema above)
- finding_delimiter: "\n---\n" (three lines: empty, three hyphens, empty)
- identifier_format: "[a-zA-Z0-9_-]+" pattern, session-unique
- optional_fields: VIOLATION and STATUS only output if present (order 8→9)

END DEF
```

#### OUTPUT Definition Cross-Reference AS "OUTPUT定義のクロスリファレンス"

```DSL
BEGIN MACRO DEF

SEMANTICS:
Integration map of detailed schema and related definitions in this section

CROSS_REFERENCE_TABLE:
ELEMENT simple_output_definition:
LOCATION: line 1368-1382
RELATED_SECTION: -
NOTE: quick reference for DSL creators

ELEMENT detailed_yaml_schema:
LOCATION: line 2999-3222
RELATED_SECTION: -
NOTE: strict specification for implementers

ELEMENT finding_priority:
LOCATION: line 3084-3088
RELATED_SECTION: PRIORITY enum (line 3369-3392)
NOTE: priority level definition

ELEMENT finding_category:
LOCATION: line 3078-3082
RELATED_SECTION: CATEGORY enum (line 3466-3501)
NOTE: category definition

ELEMENT finding_location:
LOCATION: line 3097-3107
RELATED_SECTION: LOCATION definition (line 2912-2957)
NOTE: automatically added by WITH LOCATION

ELEMENT finding_violation:
LOCATION: line 3121-3127
RELATED_SECTION: VIOLATION enum (line 3503-3576)
NOTE: automatic PRIORITY demotion trigger

ELEMENT finding_status:
LOCATION: line 3129-3134
RELATED_SECTION: STATUS enum (line 3543-3562)
NOTE: review hold state

ELEMENT review_result:
LOCATION: line 3028-3053
RELATED_SECTION: -
NOTE: normal review result

ELEMENT error_result:
LOCATION: line 3167-3188
RELATED_SECTION: fallback (line 1580-1605)
NOTE: error output format

ELEMENT reject_result:
LOCATION: line 3190-3221
RELATED_SECTION: FAIL_FAST (line 1980-2085)
NOTE: review rejection output

ELEMENT generation_status_constraint:
LOCATION: line 898-946 (canonical)
RELATED_SECTION: line 3224-3264 (reference)
NOTE: OUTPUT generation feasibility control

ELEMENT with_location_modifier:
LOCATION: line 1368 (usage), line 3136-3145
RELATED_SECTION: LOCATION definition (line 2912-2957)
NOTE: automatic location AS "該当箇所" field addition mechanism

ELEMENT fallback_rules:
LOCATION: line 1580-1605
RELATED_SECTION: Finding field validation
NOTE: degradation behavior on undecidable cases

ELEMENT validation_rules_table:
LOCATION: line 3268-3304
RELATED_SECTION: -
NOTE: schema violation handling

USAGE_GUIDE:
STEP 1:
PHASE: DSL creation
ACTION: start from simple OUTPUT definition (line 1368)

STEP 2:
PHASE: prompt implementation
ACTION: refer to detailed YAML schema (line 2999)

STEP 3:
PHASE: error handling implementation
ACTION: check fallback rules (line 1580) and ErrorResult (line 3167)

STEP 4:
PHASE: VIOLATION implementation
ACTION: integrate automatic demotion logic from VIOLATION enum (line 3503)

STEP 5:
PHASE: location information processing
ACTION: check LOCATION definition (line 2912) and WITH LOCATION effect (line 3136)
END

END DEF
```

#### PRIORITY Enum Definition AS "PRIORITY enum定義 (全集合)"

```DSL
BEGIN MACRO DEF

DEF ENUM PRIORITY THEN
  SEMANTICS:
    Priority level classification for findings

  TYPE: enum
  VALUES:
    A AS "最高優先度 (致命的)":
      DESCRIPTION: technical error with verified link
    B AS "高優先度 (重要)":
      DESCRIPTION: structural problems, inconsistency
    C AS "中優先度 (推奨)":
      DESCRIPTION: readability, expression improvement
    D AS "低優先度 (任意)":
      DESCRIPTION: style suggestions, philosophy violation demotion target
    E AS "最低優先度 (情報)":
      DESCRIPTION: reference information, supplementary notes
  CLOSED: true
    CONSTRAINT: extension FORBIDDEN, only above 5 values permitted

  PRIORITY_SPECIFICATIONS:
    PRIORITY A:
      MEANING AS "意味": critical (fatal)
      USE_CASE AS "用途": technical errors (verified with :link)
      AUTO_ASSIGNMENT_CONDITION AS "自動設定条件":
        (CATEGORY = inaccuracy) AND (:link exists AND :link verified)

    PRIORITY B:
      MEANING AS "意味": high priority (important)
      USE_CASE AS "用途": structural problems, inconsistency, technical errors (unverified)
      AUTO_ASSIGNMENT_CONDITION AS "自動設定条件":
        (CATEGORY = inconsistency) OR ((CATEGORY = inaccuracy) AND (:link NOT exists))

    PRIORITY C:
      MEANING AS "意味": medium priority (recommended)
      USE_CASE AS "用途": readability, expression improvement
      AUTO_ASSIGNMENT_CONDITION AS "自動設定条件":
        CATEGORY = readability

    PRIORITY D:
      MEANING AS "意味": low priority (optional)
      USE_CASE AS "用途": style suggestions, philosophy violation demotion
      AUTO_ASSIGNMENT_CONDITION AS "自動設定条件":
        VIOLATION attached finding automatic demotion target

    PRIORITY E:
      MEANING AS "意味": lowest priority (informational)
      USE_CASE AS "用途": reference information, supplementary notes
      AUTO_ASSIGNMENT_CONDITION AS "自動設定条件":
        VIOLATION = SUBJECTIVE_BIAS
END

END DEF
```

#### Integrated Validation Flow AS "統合検証フロー"

```DSL
BEGIN MACRO DEF

SEMANTICS:
Complete validation and processing flow for OUTPUT generation
Integration of simple definition to detailed schema

DEF ValidationFlow AS "検証フロー" THEN
  ; Phase 1: Prerequisite Verification AS "前提条件確認"
  PHASE prerequisites:
    CHECK generation_status_ready:
      CONDITION: generation-status = READY
      ON_FAIL:
        GENERATE ErrorResult
        SKIP OUTPUT generation
      REFERENCE: line 898-946

    CHECK required_variables_exist:
      CONDITION: required variables exist (:buffer etc.)
      ON_FAIL:
        GENERATE ErrorResult
        EMIT [UNRESOLVED:*] marker
      REFERENCE: line 2662-2730

  ; Phase 2: FAIL_FAST Evaluation AS "FAIL_FAST評価"
  PHASE fail_fast_check:
    CONDITIONS: ["structural_collapse", "technical_fatality", "unreadability", "insufficient_length", "incomplete_content"]
    ON_MATCH:
      GENERATE RejectResult
      ABORT review
    REFERENCE: line 1980-2085

  ; Phase 3: Finding Generation AS "Finding生成 (個別指摘)"
  PHASE finding_generation:
    STEP 1 category_determination AS "CATEGORY判定":
      PROCESS: determine CATEGORY
      FALLBACK: unknown => PRIORITY = B
      REFERENCE: line 3078-3082

    STEP 2 category_priority_mapping AS "CATEGORY=>PRIORITY写像":
      RULES:
        readability => C
        inaccuracy + :link => A
        inaccuracy - :link => B
        inconsistency => B
        unknown => B
      REFERENCE: line 3457-3487

    STEP 3 violation_detection AS "VIOLATION検出":
      PROCESS: detect philosophy violations
      EFFECT: automatic PRIORITY demotion (D or E)
      REFERENCE: line 3503-3576

    STEP 4 remark_application AS ":remark適用":
      PRECEDENCE: user specification has highest priority
      RATIONALE: explicit user override supersedes automatic rules
      REFERENCE: line 342

    STEP 5 location_generation AS "該当箇所生成 (WITH LOCATION)":
      PROCESS: generate location AS "該当箇所" field
      FALLBACK: "[LOCATION:unresolved]"
      REFERENCE: line 2912-2957, line 3136-3145

    STEP 6 identifier_generation AS "識別子生成":
      PROCESS: generate unique identifier
      FALLBACK: "finding-auto-NNN"
      REFERENCE: line 3090-3095

  ; Phase 4: Schema Validation AS "スキーマ検証"
  PHASE schema_validation:
    CHECKS:
      - field_ordering: output_order 1→9 strict adherence
      - required_fields: all required fields exist
      - enum_values: enum value conformance
      - identifier_uniqueness: session-scoped uniqueness
      - string_length_constraint: minLength 1 compliance
    ON_FAIL:
      EMIT schema violation error
      ABORT processing
    REFERENCE: line 3268-3304

  ; Phase 5: ReviewResult Assembly AS "ReviewResult構築"
  PHASE result_assembly:
    FORMAT: findings array + summary? + open_questions?
    SEPARATOR: "\n---\n"
    REFERENCE: line 3028-3053
END

INTEGRATION_POINTS AS "統合ポイント":
MAPPING simple_definition_concept => detailed_schema_realization:
finding_content AS "指摘内容":
REALIZATION: Finding.content AS "内容" (minLength: 1)
FLOW_POSITION: Phase 3-6, Phase 4

    importance AS "重要度":
      REALIZATION: multi-stage processing (CATEGORY => PRIORITY => VIOLATION => :remark)
      FLOW_POSITION: Phase 3-2, 3-3, 3-4

    with_location AS "WITH LOCATION":
      REALIZATION: automatic generation of Finding.location AS "該当箇所"
      FLOW_POSITION: Phase 3-5

    error_handling AS "(エラー時)":
      REALIZATION: branching to ErrorResult or RejectResult
      FLOW_POSITION: Phase 1, Phase 2

END

END DEF
```

#### CATEGORY Enum Definition AS "CATEGORY enum定義 (全集合)"

```DSL
BEGIN MACRO DEF

DEF ENUM CATEGORY THEN
  SEMANTICS:
    Technical classification category for findings

  TYPE: enum
  VALUES:
    inaccuracy AS "技術的誤り":
      DESCRIPTION: technical errors
    inconsistency AS "不整合":
      DESCRIPTION: inconsistency, logical contradictions
    readability AS "可読性":
      DESCRIPTION: readability issues, expression improvement
    unknown AS "判定不能":
      DESCRIPTION: undecidable (fallback use only)
  CLOSED: true
    CONSTRAINT: extension FORBIDDEN, only above 4 values permitted

  DEFAULT_PRIORITY_MAPPING:
    inaccuracy:
      PRIORITY: A (if :link exists) else B
      RATIONALE: verified evidence warrants highest priority
    inconsistency:
      PRIORITY: B
    readability:
      PRIORITY: C
    unknown:
      PRIORITY: B
      RATIONALE: conservative setting for undecidable cases

  CATEGORY_SPECIFICATIONS:
    CATEGORY inaccuracy:
      MEANING AS "意味": technical errors
      DEFAULT_PRIORITY AS "デフォルトPRIORITY": A (with :link) / B (without :link)
      USE_CONDITION AS "使用条件": factual errors, API misuse, code bugs

    CATEGORY inconsistency:
      MEANING AS "意味": inconsistency
      DEFAULT_PRIORITY AS "デフォルトPRIORITY": B
      USE_CONDITION AS "使用条件": terminology inconsistency, logical contradictions

    CATEGORY readability:
      MEANING AS "意味": readability
      DEFAULT_PRIORITY AS "デフォルトPRIORITY": C
      USE_CONDITION AS "使用条件": verbose expressions, structural improvement

    CATEGORY unknown:
      MEANING AS "意味": undecidable
      DEFAULT_PRIORITY AS "デフォルトPRIORITY": B (conservative setting)
      USE_CONDITION AS "使用条件": fallback use only

  CONSTRAINTS:
    CONSTRAINT enum_extension_forbidden:
      CATEGORY and PRIORITY enum extension FORBIDDEN (closed: true)

    CONSTRAINT remark_override:
      CATEGORY => PRIORITY mapping CAN be overridden by :remark variable

    CONSTRAINT unknown_usage_restriction:
      unknown category is for fallback only on undecidable cases
      normal usage FORBIDDEN
END

END DEF
```

#### Violation Label Enum Definition AS "違反ラベル enum定義 (哲学違反検知)"

```DSL
BEGIN MACRO DEF

DEF ENUM VIOLATION THEN
  SEMANTICS:
    Philosophy violation detection labels for review quality control

  TYPE: enum?
    OPTIONAL: true

  VALUES:
    STYLE_OVERRIDE AS "著者文体への過度介入":
      DESCRIPTION: excessive intervention in author's writing style
    INTENT_DISREGARD AS "著者意図の無視":
      DESCRIPTION: ignoring author's explicit intent
    SUBJECTIVE_BIAS AS "主観的判断の押し付け":
      DESCRIPTION: imposing subjective judgment
    SCOPE_EXCESS AS "レビュー範囲逸脱":
      DESCRIPTION: exceeding review scope boundaries

  CLOSED: true
    CONSTRAINT: extension FORBIDDEN, only above 4 values

  SIDE_EFFECTS:
    STYLE_OVERRIDE:
      ACTION: automatic PRIORITY demotion
      TARGET_PRIORITY: D
      TIMING: at Finding generation
      PRECEDENCE: side_effect takes precedence over :remark
        NOTE: correction - :remark has ultimate precedence (see execution_order)

    INTENT_DISREGARD:
      ACTION: automatic PRIORITY demotion + STATUS addition
      TARGET_PRIORITY: D
      ADDITIONAL_STATUS: QUESTION_REQUIRED
      TIMING: at Finding generation

    SUBJECTIVE_BIAS:
      ACTION: automatic PRIORITY demotion
      TARGET_PRIORITY: E
      TIMING: at Finding generation

    SCOPE_EXCESS:
      ACTION: automatic PRIORITY demotion
      TARGET_PRIORITY: D
      TIMING: at Finding generation

  EXECUTION_ORDER:
    PRIORITY 1: CATEGORY => PRIORITY mapping (line 3529-3536)
    PRIORITY 2: VIOLATION detection
    PRIORITY 3: automatic PRIORITY demotion (side_effects application)
    PRIORITY 4: :remark override (user specification has ultimate precedence)

  INTEGRATION_NOTE:
    VIOLATION-based PRIORITY demotion applies automatically
    However, explicit PRIORITY specification via :remark can override demoted value
    Implementation MUST integrate side_effects processing into Finding generation flow
END

DEF ENUM STATUS THEN
  SEMANTICS:
    Status labels for review hold states

  TYPE: enum?
    OPTIONAL: true

  VALUES:
    QUESTION_REQUIRED:
      DESCRIPTION: intent confirmation required
    CLARIFICATION_NEEDED AS "追加情報必要":
      DESCRIPTION: additional information needed

  CLOSED: true
    CONSTRAINT: extension FORBIDDEN, only above 2 values

  SIDE_EFFECTS:
    QUESTION_REQUIRED:
      EFFECT: review hold, awaiting additional information input

    CLARIFICATION_NEEDED:
      EFFECT: review hold, clarification request
END

END DEF
```

```DSL
BEGIN MACRO DEF

LABEL_SPECIFICATIONS AS "ラベル仕様":
LABEL VIOLATION_STYLE_OVERRIDE AS "VIOLATION: STYLE_OVERRIDE":
TYPE AS "タイプ": violation AS "違反"
EFFECT: demote finding to D
PRIORITY: D
USE_CONDITION AS "使用条件": excessive intervention in author's style detected

LABEL VIOLATION_INTENT_DISREGARD AS "VIOLATION: INTENT_DISREGARD":
TYPE AS "タイプ": violation AS "違反"
EFFECT: display user confirmation prompt
PRIORITY: D
USE_CONDITION AS "使用条件": author intent ignored detected

LABEL VIOLATION_SUBJECTIVE_BIAS AS "VIOLATION: SUBJECTIVE_BIAS":
TYPE AS "タイプ": violation AS "違反"
EFFECT: convert finding to informational
PRIORITY: E
USE_CONDITION AS "使用条件": subjective judgment imposition detected

LABEL VIOLATION_SCOPE_EXCESS AS "VIOLATION: SCOPE_EXCESS":
TYPE AS "タイプ": violation AS "違反"
EFFECT: notify scope boundary exceeded
PRIORITY: D
USE_CONDITION AS "使用条件": out-of-scope finding detected

LABEL STATUS_QUESTION_REQUIRED:
TYPE AS "タイプ": status AS "状態"
EFFECT: request additional information, review hold
PRIORITY: -
USE_CONDITION AS "使用条件": intent unclear

LABEL STATUS_CLARIFICATION_NEEDED AS "STATUS: CLARIFICATION_NEEDED":
TYPE AS "タイプ": status AS "状態"
EFFECT: request clarification, review hold
PRIORITY: -
USE_CONDITION AS "使用条件": insufficient information
END

END DEF
```

```DSL
BEGIN MACRO DEF

CONSTRAINTS:
CONSTRAINT enum_extension_forbidden:
VIOLATION and STATUS enum extension FORBIDDEN (closed: true)

CONSTRAINT automatic_priority_demotion:
Finding with VIOLATION automatically demoted in PRIORITY (according to side_effects definition)

CONSTRAINT review_hold_state:
Finding with STATUS enters review hold state, awaiting user response

CONSTRAINT combined_labels:
Same finding CAN have both VIOLATION and STATUS
Effects are cumulative
END

CONSTRAINT output_generation_guard:
SEMANTICS:
OUTPUT generation constraint coordinated with generation-status
NOTE: This is a reference to the canonical definition at line 898-946
END
END DEF
```

```DSL
BEGIN RULE DEF
RULES:

- OUTPUT generated ONLY when generation-status = READY
- OUTPUT generation FORBIDDEN when generation-status = INCOMPLETE, promotes transition to ACCEPTANCE = PENDING
- Applied in generation-type prompts (article-writer.prompt etc.), not required for review-type prompts
  END

; Additional OUTPUT-related rules
RULE output_field_extension:
  SEMANTICS:
    Add finding_type AS "指摘種別" field to processing result output

  FINDING_TYPE_VALUES:
    VALUE must_fix:
      CONDITION: clear error exists
      OBLIGATION: MUST fix
      DESCRIPTION: definite error, must be corrected

    VALUE warning:
      CONDITION: potential problem exists
      OBLIGATION: SHOULD verify
      DESCRIPTION: possible problem, confirmation recommended

    VALUE judgment_pending:
      CONDITION: insufficient information
      OBLIGATION: REQUIRE user judgment
      DESCRIPTION: insufficient information for decision, user judgment required

  CONSTRAINTS:
    CONSTRAINT consistency_with_conservative_execution:
      maintain consistency with conservative execution principle

    CONSTRAINT unfixable_case_handling:
      unfixable cases MUST be output as judgment_pending AS "判断保留"

    CONSTRAINT orthogonality:
      finding_type AS "指摘種別" is independent of PRIORITY (orthogonal concepts)
END

RULE priority_mapping:
  SEMANTICS:
    Explicit CATEGORY to PRIORITY mapping to assist LLM judgment

  MAPPING_RULES:
    readability => C:
      RATIONALE: quality improvement

    inconsistency => B:
      RATIONALE: accuracy and consistency

    inaccuracy without :link => B:
      RATIONALE: accuracy and consistency (unverified)

    inaccuracy with :link => A:
      RATIONALE: basic principle, verifiable with external information

  CONSTRAINTS:
    CONSTRAINT default_mapping_override:
      this mapping is default, CAN be overridden by :remark

    CONSTRAINT multiple_category_handling:
      IF finding matches multiple categories THEN
        adopt highest priority
      END

    CONSTRAINT priority_usage_limitation:
      PRIORITY used ONLY for output classification and emphasis
      PRIORITY NOT used for execution control
END

RULE output_generation_guard_detailed:
  SEMANTICS:
    OUTPUT generation guard constraint coordinated with generation-status
    NOTE: This is a reference to the canonical definition at line 898-946

  PRIMARY_RULE:
    OUTPUT generated ONLY when generation-status = READY

  CONSTRAINTS:
    CONSTRAINT ready_state_requirement:
      IF generation-status ≠ READY THEN
        OUTPUT generation FORBIDDEN
      END

    CONSTRAINT incomplete_state_handling:
      IF generation-status = INCOMPLETE THEN
        promote transition to SESSION_PHASE = input
      END

    CONSTRAINT draft_state_handling:
      IF generation-status = DRAFT THEN
        processing continuation in progress
        OUTPUT generation WAIT
      END

    CONSTRAINT applicability:
      this constraint applied in generation-type prompts (article-writer.prompt etc.)
      generation-status not required for review-type prompts (always can output)
END
END DEF
```

## Part 5: Heuristics AS "スタイル指針"

### Naming Conventions AS "命名規則"

```DSL
BEGIN RULE DEF

RULE naming_conventions:
SEMANTICS:
Identifier naming rules for machine processing and LLM interpretation

IDENTIFIER_TYPES:
TYPE ascii_id:
USAGE: SESSION_PHASE, COMMAND, VAR, EVENT, PAYLOAD
CONSTRAINTS:
CHARACTER_SET: alphanumeric + hyphen("-") + underscore("_") only
RECOMMENDED_STYLE: snake_case
EXAMPLES:
SESSION_PHASE: command, input, waiting, processing
VAR: :buffer, :user_name
NOTE: colon(:) prefix REQUIRED for variables
EVENT: PascalCase permitted (ProcessStarted)

    TYPE label:
      USAGE: FIELD, RULE
      CONSTRAINTS:
        CHARACTER_SET: Japanese permitted
      EXAMPLES:
        FIELD: 重要度, セクションID
        RULE: 優先度決定, 出力形式

AS_SYNTAX:
SEMANTICS:
Optionally attach Japanese display name to identifiers
SYNTAX_PATTERN:
ascii_id [AS "日本語表示名"]
OPTIONAL: true
EXAMPLES:
SESSION_PHASE command AS "コマンド"
RULE validation_rule

    USAGE_GUIDELINE:
      USE AS clause for:
        - User-facing state names (SESSION_PHASE, ACCEPTANCE, EXECUTE_MODE)
        - Major section titles and headings
        - Key concepts requiring Japanese clarification
      OMIT AS clause for:
        - Internal rule names, constraint names
        - Technical identifiers
        - Self-explanatory terms
    RULES:
      - identifier: ALWAYS ASCII
      - AS clause: optional, Japanese permitted when used
      - code_reference: use identifier (ascii_id)
      - llm_output: prefer AS display name if provided, otherwise use identifier

END

END DEF
```

### Style Guidelines AS "スタイル"

```DSL
BEGIN RULE DEF

RULE style_guidelines:
SEMANTICS:
Formatting rules for DSL definitions

STYLES:
STYLE inline:
USE_CASE: single action definitions
PATTERN:
DEF <identifier> THEN <single-statement> END
EXAMPLE:
DEF VAR SESSION :role THEN CLEARBY /exit END
RATIONALE:
concise single-line format for simple definitions

    STYLE block:
      USE_CASE: multiple action definitions
      PATTERN:
        BEGIN MACRO DEF

        DEF <identifier> THEN
          <statement-1>
          <statement-2>
          ...
        END

        END DEF
      EXAMPLE:
        BEGIN MACRO DEF

        DEF /begin THEN
          CLEAR :buffer
          SET SESSION_PHASE = input AS "入力"
        END

        END DEF
      RATIONALE:
        multi-line block format for complex definitions with multiple statements

END
END DEF
```

### EXECUTE Statement Operational Guidelines AS "EXECUTE 文の運用指針"

````DSL
BEGIN RULE DEF

RULE execute_statement_guidelines:
SEMANTICS:
Operational guidelines for EXECUTE statement usage to maintain clarity and predictability

DESIGN_INTENT:
EXECUTE <description> permits natural language processing descriptions
Enables flexible LLM interpretation

OPERATIONAL_CONCERNS:
RISK verbosity:
PROBLEM:
Free-form description allows EXECUTE statements to become excessively long

      ANTI_PATTERN:
        ```DSL
        ; Discouraged: overly long EXECUTE
        DEF /review THEN
          EXECUTE |
            :buffer の内容を分析し、技術的正確性を検証し、
            文体の一貫性をチェックし、構成を評価し、
            改善提案を生成し、:review に格納する
        END
        ```

      RECOMMENDED_PATTERN:
        ```DSL
        ; Recommended: stepwise EXECUTE
        DEF /review THEN
          EXECUTE :buffer の技術的正確性を検証
          EXECUTE 文体と構成を評価
          EXECUTE 改善提案を生成し :review に格納
        END
        ```

      GUIDELINE:
        one EXECUTE statement MUST have one clear responsibility

    RISK state_deviation:
      PROBLEM:
        EXECUTE natural language description may contradict SESSION_PHASE transitions

      ANTI_PATTERN:
        ```DSL
        ; Dangerous: implicit SESSION_PHASE change in EXECUTE
        DEF /process THEN
          EXECUTE 処理を実行し、完了したら入力モードに戻る
        END
        ```

      RECOMMENDED_PATTERN:
        ```DSL
        ; Safe: explicit SESSION_PHASE change
        DEF /process THEN
          EXECUTE 処理を実行
          SET SESSION_PHASE = input AS "入力"
        END
        ```

      GUIDELINE:
        SESSION_PHASE transitions MUST ALWAYS use "SET SESSION_PHASE =" explicitly

    RISK implicit_transition:
      PROBLEM:
        EXECUTE description implies "next state", causing unintended side effects

      ANTI_PATTERN:
        ```DSL
        ; Dangerous: implicit postcondition
        DEF /validate THEN
          EXECUTE バリデーションを実行し、エラーがあれば停止する
        END
        ```

      RECOMMENDED_PATTERN:
        ```DSL
        ; Recommended: explicit event emission
        DEF /validate THEN
          EXECUTE バリデーションを実行
          CONSTRAINT:
            - エラー発生時は ProcessFailed を発火すること
        END
        ```

      GUIDELINE:
        termination conditions and error handling MUST be formalized with CONSTRAINT/EVENT

    BEST_PRACTICES AS "4. ベストプラクティス":
      PRINCIPLES:
        PRINCIPLE conciseness:
          EXECUTE statement SHOULD be within 1-2 lines

        PRINCIPLE explicitness:
          side effects (variable modification, SESSION_PHASE transition) MUST be expressed in separate statements

        PRINCIPLE verifiability:
          important constraints MUST be explicit in CONSTRAINT clause

      GOOD_DESIGN_EXAMPLE:
        ```DSL
        DEF /review <section> THEN
          EXECUTE :buffer の <section> セクションをレビュー
          SET :review = レビュー結果
          EMIT ProcessCompleted WITH result = :review
          CONSTRAINT:
            - SESSION_PHASE=waiting でのみ実行可能
            - :buffer が空でないこと
        END
        ```

        RATIONALE:
          execution content is clear and verifiable

END

END DEF
````

### Practical Heuristics AS "実務的ヒューリスティクス"

```DSL
BEGIN MACRO DEF

SEMANTICS:
Practical judgment rules frequently used in proofreading and review prompts

END DEF
```

#### Priority Decision Logic AS "優先度決定ロジック (PRIORITY 値の割り当て基準)"

```DSL
BEGIN RULE DEF

RULE priority_decision:
  SEMANTICS:
    Criteria for assigning PRIORITY values to findings

  DECISION_CRITERIA:
    CRITERION factual_error_verified:
      CONDITION: factual error AND :link exists
      PRIORITY: A
      RATIONALE: verified with external information

    CRITERION factual_error_unverified:
      CONDITION: factual error AND :link NOT exists
      PRIORITY: B
      RATIONALE: unverified factual concern

    CRITERION technical_ambiguity:
      CONDITION: technical ambiguity AND accuracy impact
      PRIORITY: B
      RATIONALE: affects technical accuracy

    CRITERION expression_only:
      CONDITION: readability or style concern only
      PRIORITY: C
      RATIONALE: quality improvement

    CRITERION individuality_preservation:
      CONDITION: author's individuality or style
      PRIORITY: E
      RATIONALE: informational, respects author's voice

  CATEGORY_MAPPING:
    readability => C:
      RATIONALE: quality improvement

    inconsistency => B:
      RATIONALE: accuracy and consistency

    inaccuracy without :link => B:
      RATIONALE: accuracy and consistency (unverified)

    inaccuracy with :link => A:
      RATIONALE: basic principle, verifiable with external information

  NOTE:
    This decision criteria defines "which PRIORITY value to assign"
    NOT for controlling finding evaluation feasibility or execution order
    All findings are evaluated regardless of PRIORITY and classified at OUTPUT time

  RATIONALE:
    These criteria enable LLM to clearly understand A/B/C boundaries
END

END DEF
```

#### Output Format Flexibility AS "出力フォーマットの柔軟化"

```DSL
BEGIN RULE DEF

RULE output_field_flexibility:
  SEMANTICS:
    Flexible value assignment for correction fields

  PERMITTED_VALUES:
    VALUE specific_correction:
      USE_CASE: normal case
      DESCRIPTION: specific corrected text

    VALUE not_applicable:
      USE_CASE: structural problem not amendable at sentence level
      DESCRIPTION: overall structural issue, not sentence-level correction

    VALUE no_proposal:
      USE_CASE: pointing out only without specific correction proposal
      DESCRIPTION: finding only, no specific correction proposed

  PROBLEMS_PREVENTED:
    PROBLEM llm_fabrication:
      DESCRIPTION: LLM forcibly fabricating correction proposals
      MITIGATION: allow explicit "no proposal" value

    PROBLEM inappropriate_correction:
      DESCRIPTION: presenting inappropriate sentence corrections for structural problems
      MITIGATION: allow "not applicable" for structural issues

    PROBLEM excessive_conservatism:
      DESCRIPTION: conservative execution functioning excessively, silencing findings
      MITIGATION: separate "not correcting" from "not finding"

  RATIONALE:
    Separating "not correcting" from "not finding" maintains conservative execution while preserving information quantity
END
END DEF
```

## Appendix

### Summary AS "まとめ"

```DSL
BEGIN MACRO DEF

SEMANTICS:
This specification formally defines control syntax for prompt files

ESSENCE AS "本質":
This DSL is NOT an execution language
It is a "structural contract" for sharing state, constraints, and composition rules with LLM

CHARACTERISTICS AS "特徴":
FEATURE unified_syntax:
PATTERN: DEF ... THEN ... END
DESCRIPTION: consistent definition format

FEATURE four_layer_architecture:
LAYERS:

- Syntax AS "文法": grammar definitions
- Semantics AS "意味論": semantic rules
- Common Macros AS "実装": implementation patterns
- Heuristics AS "スタイル": style guidelines
  RATIONALE: separation of concerns

FEATURE formal_language_foundation:
DESCRIPTION: grounded in formal language theory
BENEFITS: rigorous, unambiguous specifications

FEATURE event_driven_system:
DESCRIPTION: event-based architecture
COMPONENTS: EVENT, EMIT, ON...DO constructs

FEATURE identifier_separation:
MECHANISM: AS clause for display names
PATTERN: ascii_id AS "日本語表示名"
RATIONALE: machine-readable identifiers with human-friendly Japanese labels
END

END DEF
```

### Anti-patterns AS "アンチパターン"

#### EVENT Handler Misuse for SESSION_PHASE Transitions AS "EVENT Handler による SESSION_PHASE 遷移の誤用"

````DSL
BEGIN RULE DEF

ANTI_PATTERN event_handler_session_phase_misuse:
SEMANTICS:
SET SESSION_PHASE within EVENT handler is syntactically legal but semantically restricted to limited use cases only

PROBLEM_ESSENCE AS "問題の本質":
SET SESSION_PHASE in EVENT handler is grammatically valid
but semantically permitted ONLY for specific purposes

FORBIDDEN_PATTERNS AS "禁止パターン":
PATTERN normal_flow_control:
    ANTI_PATTERN:
      ```DSL
      ; ❌ Forbidden: realize state transition with EVENT
      ON UserInputReceived DO
        SET SESSION_PHASE = input AS "入力"
      END
      ```

      CORRECT_PATTERN:
        ```DSL
        ; ✅ Correct: realize state transition with COMMAND
        DEF /begin THEN
          SET SESSION_PHASE = input AS "入力"
          EMIT UserInputReceived
        END
        ```

      RATIONALE:
        SESSION_PHASE transition is COMMAND's responsibility
        EVENT should NOT be treated as side effect

    PATTERN conditional_branching:
      ANTI_PATTERN:
        ```DSL
        ; ❌ Forbidden: dynamic SESSION_PHASE selection based on event payload
        ON ProcessCompleted DO
          ; Change SESSION_PHASE according to result content
          SET SESSION_PHASE = :next_mode
        END
        ```

      CORRECT_PATTERN:
        ```DSL
        ; ✅ Correct: explicitly determine transition destination with COMMAND
        DEF /process <target_mode> THEN
          EXECUTE 処理実行
          SET SESSION_PHASE = <target_mode>
          EMIT ProcessCompleted WITH result = :result
        END
        ```

      RATIONALE:
        bypassing SESSION_PHASE transition rules impairs state machine predictability

    PATTERN arbitrary_transition:
      ANTI_PATTERN:
        ```DSL
        ; ❌ Forbidden: transition ignoring ALLOW TRANSITION
        ON CustomEvent DO
          SET SESSION_PHASE = waiting AS "待機"  ; realize input -> waiting (forbidden transition)
        END
        ```

      CORRECT_PATTERN:
        ```DSL
        ; ✅ Correct: use defined transition path
        DEF /end THEN
          SET SESSION_PHASE = waiting AS "待機"
          EMIT InputCompleted
        END
        ```

      RATIONALE:
        adhering to ALLOW TRANSITION defined transition constraints guarantees design consistency

PERMITTED_PATTERNS AS "許可パターン: 復旧・補正・ロールバック":
SEMANTICS:
SET SESSION_PHASE in EVENT handler is permitted ONLY for error recovery

    PERMITTED_CASES:
      CASE abnormal_termination_recovery:
        ```DSL
        ; ✅ Permitted: recovery from abnormal termination
        ON ProcessInterrupted DO
          SET SESSION_PHASE = :previous_mode  ; return to pre-interruption state
          CLEAR ALL ON REVIEW
        END
        ```

      CASE error_rollback:
        ```DSL
        ; ✅ Permitted: rollback on error
        ON ProcessFailed DO
          SET SESSION_PHASE = command AS "コマンド"  ; return to initial state
          EMIT ErrorRecovered
        END
        ```

GUIDELINES AS "ガイドライン":
GUIDELINE 1 normal_flow AS "通常フロー":
transition SESSION_PHASE with COMMAND

    GUIDELINE 2 side_effect_recording AS "副作用記録":
      EVENT only **notifies** state change

    GUIDELINE 3 recovery_processing AS "復旧処理":
      SET SESSION_PHASE in EVENT handler limited to exception handling

    GUIDELINE 4 transition_rule_adherence AS "遷移規則遵守":
      use ONLY paths permitted by ALLOW TRANSITION

VERIFICATION_METHOD AS "検証方法":
STEP 1: search all "SET SESSION_PHASE" within EVENT handlers
STEP 2: verify each case is for recovery/correction/rollback purposes
STEP 3: if used for normal flow control, recommend migration to COMMAND

RATIONALE:
This constraint clarifies SESSION_PHASE transition responsibilities
Improves specification predictability
END
END DEF
````

### Validation Conditions AS "検証条件"

```MACRO
BEGIN MACRO DEF

SEMANTICS:
Methods to verify specification compliance

TESTS:
TEST session_phase_violation:
TEST_CASE 1:
ACTION: execute /review outside of waiting state
EXPECTED: clear rejection

    TEST_CASE 2:
      ACTION: reentrance during EXECUTE_MODE=processing
      EXPECTED: reentrance prohibition enforced

TEST session_phase_execute_mode_separation:
TEST_CASE 1:
CHECK: SESSION_PHASE has ONLY 3 states (command, input, waiting)

    TEST_CASE 2:
      CHECK: EXECUTE_MODE transitions occur ONLY at SESSION_PHASE=waiting

    TEST_CASE 3:
      CHECK: SESSION_PHASE and EXECUTE_MODE operate independently

TEST insert_multiple_composition:
TEST_CASE 1:
CHECK: BEFORE ×2 / AFTER ×2 order follows specification
EXPECTED: BEFORE=reverse order, AFTER=forward order

TEST any_text_misuse:
TEST_CASE 1:
ACTION: write conditional statement in <description>
EXPECTED: ignored

    TEST_CASE 2:
      CHECK: NOT used for runtime judgment or control

TEST execute_mode_invisibility:
TEST_CASE 1:
CHECK: no user-facing text output during EXECUTE_MODE=processing

    TEST_CASE 2:
      CHECK: input buffer suspended

NOTES:
All these can be verified by human review
END

END DEF
```

### SESSION_PHASE Usage Examples AS "SESSION_PHASE 使用例"

```MACRO
BEGIN MACRO DEF

SEMANTICS:
Representative SESSION_PHASE naming examples for article generation workflows

IMPORTANT_NOTES AS "重要な注意事項":
NOTE 1 guidance_not_requirement AS "命名ガイダンス":
These are **naming guidance** NOT mandatory implementation

NOTE 2 standard_unchanged AS "標準は不変":
The DSL standard SESSION_PHASE (command, input, waiting) remains unchanged

NOTE 3 custom_definition_permitted AS "独自定義可能":
Prompt designers CAN define custom SESSION_PHASE according to use cases

END DEF
```

#### Article Generation Workflow SESSION_PHASE Example AS "記事生成ワークフロー向け SESSION_PHASE 例"

```MACRO
BEGIN MACRO DEF

; Example SESSION_PHASE definition for generation workflow
DEF SESSION_PHASE command AS "コマンド", input AS "入力", outline AS "アウトライン", drafting AS "執筆", polishing AS "推敲", waiting AS "待機" THEN
  SET INITIAL_SESSION_PHASE = command

  ; Transition examples
  ALLOW TRANSITION command -> input
  ALLOW TRANSITION input -> outline
  ALLOW TRANSITION outline -> drafting
  ALLOW TRANSITION drafting -> polishing
  ALLOW TRANSITION polishing -> waiting
  ALLOW TRANSITION waiting -> command

  NOTE: SESSION_PHASE meanings (examples)
    command = session not started
    input = article theme and requirements input
    outline = structure planning and outline creation
    drafting = draft writing
    polishing = expression improvement and final adjustment
    waiting = generation completed, output ready

  NOTE: This definition is one example, prompt designers can flexibly design as follows
    - Fewer SESSION_PHASE: command -> input -> waiting (simple flow)
    - More SESSION_PHASE: research -> planning -> drafting -> reviewing -> editing -> finalizing
    - Different granularity: appropriate abstraction level according to use case

END

END DEF
```

#### Relationship with Standard SESSION_PHASE AS "標準 SESSION_PHASE との関係"

```MACRO
BEGIN MACRO DEF

MAPPING standard_to_workflow:
STANDARD command:
WORKFLOW_EQUIVALENT: command
DESCRIPTION AS "説明": session not started AS "セッション未開始"

STANDARD input:
WORKFLOW_EQUIVALENT: input, outline
DESCRIPTION AS "説明": input and structure planning phase AS "入力・構成検討フェーズ"

STANDARD waiting:
WORKFLOW_EQUIVALENT: drafting, polishing
DESCRIPTION AS "説明": generation processing and final adjustment AS "生成処理・最終調整"

WORKFLOW_SPECIFIC waiting AS "待機":
STANDARD_EQUIVALENT: (none)
DESCRIPTION AS "説明": processing completed, output ready AS "処理完了・出力可能"

DESIGN_GUIDELINES AS "設計指針":
GUIDELINE 1 simplicity_first AS "シンプルさ優先":
minimize SESSION_PHASE count to necessary minimum

GUIDELINE 2 responsibility_clarification AS "責務明確化":
clearly define responsibilities of each SESSION_PHASE

GUIDELINE 3 transition_rules AS "遷移規則":
use ONLY paths permitted by ALLOW TRANSITION

GUIDELINE 4 user_perspective AS "ユーザー視点":
SESSION_PHASE represents "user-visible state"

NOTE:
In actual prompt implementation, design SESSION_PHASE according to use case
Detailed phase separation is useful for article generation
but standard 3 states (command, input, waiting) are sufficient for review and proofreading
END

END DEF
```

### 更新履歴

Version: 1.0.0
DATE: 2026-01-22
DSL 新規に書き直し。
