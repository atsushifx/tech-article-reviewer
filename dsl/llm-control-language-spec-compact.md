---
title: LLM制御言語仕様 (形式定義版)
description: プロンプト制御DSL - 形式言語による圧縮仕様 (5層構造)
version: 1.0.1
update: 2026-01-24
architecture: 5-layer (0:Meta / 1:Syntax / 2:Semantics / 3:Policy / 4:Macros / 5:Style)
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## 0. メタ記法

| 記号     | 意味     | 記号       | 意味     |
| -------- | -------- | ---------- | -------- |
| `[x]`    | 省略可   | `[x..]`    | 0回以上  |
| `x\|y`   | 選択     | `x->y`     | 連続     |
| `<type>` | 型       | `"text"`   | リテラル |
| `:id`    | 変数参照 | `/cmd`     | コマンド |
| `;`      | コメント | `NOTE:`    | 補足説明 |
| `\|`     | 複数行   | `""""`     | 長文     |
| DEF..END | 定義     | BEGIN..END | ブロック |

NOTE:
本 DSL は実行系ではなく、LLM との構造認識共有が目的。
セマンティックバージョン: MAJOR=破壊的 | MINOR=追加 | PATCH=修正。

### 0.1 Backbone BNF (姿勢定義)

本 BNF は「姿勢定義」であり、完全構文検証・拡張網羅・実装指針代替を目的としません。LLM への設計思想伝達が主眼です。

```abnf
; === トップレベル構造 (言語の重心) ===
macro  = "DEF" target "THEN" body "END"
       / "INSERT" command position body "END"
       / "ON" event "DO" body "END"
       / meta-block

; === 拡張ポイント (重心) ===
target = ACCEPTANCE / COMMAND / VAR / PRIORITY / OUTPUT / LOCATION / EVENT / STATUS
body   = <opaque>  ; 内部構造は Section 1 参照

; === プリミティブ ===
command  = "/" identifier
event    = identifier
position = BEFORE / AFTER
meta-block = "BEGIN" block-type "DEF" <opaque> "END" "DEF"
block-type = DSL / MACRO / RULE / INPUT / OUTPUT
```

**設計原則**:

1. **列挙しない**: コマンド名・変数名を列挙せず、形式だけ示す
2. **body 定義しない**: `<opaque>` で内部構造隠蔽、中身に口出さない
3. **分岐条件のみ残す**: 拡張ポイント (target) 明示で言語重心を示す

**NOTE**: `<opaque>` =「この領域は LLM の自然言語理解に委ねる」。Backbone BNF は LLM との概念共有用、パーサー生成用ではない。

### 0.2 最小使用例

本 DSL の基本パターンを示します。

```MACRO
BEGIN INPUT
  SET :buffer = """
技術記事の内容をここに記述します。
複数行のテキストを受け付けます。
"""
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

**NOTE**: 最小構成は `BEGIN INPUT` → コマンド実行 → `OUTPUT` の 3 ステップ。各詳細は後続セクションで定義。

---

## 1. 構文 (ABNF)

### 1.1 超圧縮 ABNF

本セクションは DSL の骨格を ABNF 形式で定義します。ABNF は RFC 5234 準拠、`*` = 0回以上、`1*` = 1回以上。

```abnf
; ============================================================
; LCL DSL Core Grammar (Ultra-Compact ABNF)
; ============================================================

; Macro Definition
macro       = "DEF" target "THEN" body "END"
target      = acceptance / command / variable / rule / status
acceptance  = "ACCEPTANCE" mode-list
command     = "/" token [params]
variable    = "VAR" scope ":" name ["=" value]
rule        = "RULE" name
status      = "STATUS" gen-status

; Body Structure
body        = *action [note] [constraint]
action      = set / clear / execute / emit / chain
set         = "SET" var-ref "=" value
clear       = "CLEAR" (var-ref / "ALL" ["ON" scope])
execute     = "EXECUTE" desc
emit        = "EMIT" event-name ["WITH" payload]
chain       = action "->" action ["->" action]

; Block Forms
input-block = "BEGIN INPUT" *set "END INPUT"
meta-block  = "BEGIN" type "DEF" *content "END DEF"
type        = "DSL" / "MACRO" / "RULE" / "INPUT" / "OUTPUT"

; Extension
insert      = "INSERT" command ("BEFORE" / "AFTER") body "END"
event       = "EVENT" name ["WITH" payload]
handler     = "ON" event-name "DO" body "END"

; Core Enums
mode        = "PENDING" / "ACTIVE"
scope       = "SESSION" / "REVIEW"
gen-status  = "DRAFT" / "INCOMPLETE" / "READY"

; Value Forms
value       = quoted / multiline / heredoc
quoted      = DQUOTE *VCHAR DQUOTE
multiline   = "|" 1*line
heredoc     = 4DQUOTE *line 4DQUOTE

; Primitives
var-ref     = ":" name
name        = 1*(ALPHA / DIGIT / "-" / "_")
token       = 1*(ALPHA / DIGIT / "-" / "_")
desc        = 1*VCHAR
note        = "NOTE:" 1*line
constraint  = "CONSTRAINT:" 1*line
mode-list   = name *("," name)
payload     = field ":" type-name *("," field ":" type-name)
field       = 1*(ALPHA / DIGIT / "_")
```

**NOTE**:

- ABNF 形式により BNF から **60% 圧縮** (構造的明瞭性維持)
- `ALPHA`, `DIGIT`, `VCHAR`, `DQUOTE` は RFC 5234 定義基本要素
- chain (`->`) は 2-3 個推奨、120 文字制限厳守
- 詳細構文 (phase-table, valid-table 等) は Section 2 以降に委譲

**CONSTRAINT**:

- ABNF は意味的完全性持つ最小規則セット
- 拡張構文は Extension セクション集約
- テーブル形式はドキュメント用途、構文要素でない

### 1.2 メタブロック構文

メタブロックは構文解析段階で除外される特殊ブロックです。

| block-type | 用途             | 解釈除外タイミング      | 例                        |
| ---------- | ---------------- | ----------------------- | ------------------------- |
| DSL        | BNF 定義記述     | パース前 (コメント扱い) | 言語仕様の説明            |
| MACRO      | マクロ定義記述   | 構文解析段階            | 再利用可能なパターン定義  |
| RULE       | ポリシー記述     | 構文解析段階            | レビュー哲学・制約規則    |
| INPUT      | 型定義記述       | 構文解析段階            | 入力変数のスキーマ定義    |
| OUTPUT     | 出力形式定義記述 | 構文解析段階            | OUTPUT 構造のスキーマ定義 |

**NOTE**: DSL = 構文的除外 (コメント扱い) | MACRO/RULE/INPUT/OUTPUT = 解釈層での除外。メタブロックは実行フローに影響しない。

---

## 2. 意味論

### 2.1 評価レイヤー

```mermaid
構文解析 → 意味論評価 → 実行
```

| レイヤー | 役割                        |
| -------- | --------------------------- |
| 構文     | 文法的正当性 (パース可能性) |
| 意味論   | 実行時意味 (制約・状態遷移) |

NOTE: CONSTRAINT/RULE = 意味論的ガード (解釈フェーズ評価)。構文要素ではない。

### 2.2 NOTE意味論

```bnf
note-placement ::= [action..] [NOTE:..] [CONSTRAINT:..]
note-scope     ::= 直前要素への補足 | 後続要素への前提説明
note-format    ::= 単一段落 | 複数段落(サブトピック区切り)
```

| 特性       | 規則                              |
| ---------- | --------------------------------- |
| 認識       | 構文要素として解析                |
| 評価       | 実行・制約判断に影響しない        |
| 配置       | body末尾 (action後、CONSTRAINT前) |
| 用途       | 人間向け説明のみ                  |
| CONSTRAINT | NOTE根拠の挙動変更=未定義動作     |
| スコープ   | 直前要素補足 or 後続要素前提説明  |
| 複数段落   | サブトピック区切り(`              |

**NOTE 用途分類**:

1. **説明的 NOTE**: 補足説明のみ (評価に影響なし)
2. **制約的 NOTE**: CONSTRAINT の補足 (単独評価なし)
3. **例示的 NOTE**: 使用例・デバッグ情報

**CONSTRAINT**: NOTE 単独で制約判断に使用禁止。ACCEPTANCE 遷移・COMMAND 可否判断に NOTE 内容使用禁止。解釈ロジックから分離。

### 2.3 モード遷移

```bnf
ACCEPTANCE   ::= PENDING | ACTIVE              ; 初期=PENDING
EXECUTE_MODE ::= idle | processing             ; 初期=idle
generation-status ::= DRAFT | INCOMPLETE | READY ; 初期=DRAFT
```

**ACCEPTANCE PRINCIPLE** (主導権原則):

| 原則                       | 意味                                         |
| -------------------------- | -------------------------------------------- |
| 合否評価ではない           | ACCEPTANCE は品質評価を意味しない (意味固定) |
| 文章受付と処理の境界       | 受付中 vs 処理中を示す状態変数               |
| PENDING中は沈黙            | 文章受付中は解析・要約・応答禁止             |
| 明示的指示で ACTIVE 化     | /write で一時的に ACTIVE、完了後 PENDING     |
| ユーザー指定の範囲のみ生成 | Section 指定時は他セクション言及禁           |
| 制御ではなく主導権の宣言   | LLM の自発的動作は主導権侵害                 |
| すべて明示的コマンド開始   | 自発的処理の開始禁止                         |

**CONSTRAINT**: ACCEPTANCE は「制御」でなく「主導権の宣言」。LLM の自発的動作=主導権侵害。処理は明示的コマンドのみで開始。

**層分離原則**:

| レイヤー     | 変数              | スコープ             | 遷移条件                 | 責務           |
| ------------ | ----------------- | -------------------- | ------------------------ | -------------- |
| UI 層        | SESSION_PHASE     | command/input/review | /begin, /end, /exit      | ユーザー対話   |
| 処理層       | EXECUTE_MODE      | idle/processing      | SESSION_PHASE=reviewとき | 処理実行制御   |
| 成果物準備層 | generation-status | DRAFT/INCOMPLETE/... | 情報充足判定             | OUTPUT生成可否 |

**NOTE**: SESSION_PHASE (UI 層) | EXECUTE_MODE (処理層) | generation-status (成果物準備層) は独立。EXECUTE_MODE は SESSION_PHASE=review 時のみ遷移可能。

**遷移規則**:

| モード       | 許可遷移                     | 禁止遷移                            | 条件                    |
| ------------ | ---------------------------- | ----------------------------------- | ----------------------- |
| ACCEPTANCE   | PENDING→ACTIVE(一時)→PENDING | 自動遷移禁止                        | /write のみ             |
| EXECUTE_MODE | idle→proc→idle               | proc→proc                           | ACCEPTANCE=ACTIVE時のみ |
| 出力制約     | processing時=事実通知のみ    | processing時=説明文・考察・推論禁止 | -                       |

### 2.3.1 状態遷移統合表

統一的な状態遷移ビューを提供するクイックリファレンス。

| モード            | 初期値     | 遷移トリガー | 遷移先     | 定義元 |
| ----------------- | ---------- | ------------ | ---------- | ------ |
| ACCEPTANCE        | PENDING    | /write実行   | ACTIVE     | §2.4   |
| ACCEPTANCE        | ACTIVE     | /write完了   | PENDING    | §2.4   |
| EXEC_MODE         | idle       | /review開始  | processing | §2.4   |
| EXEC_MODE         | processing | /review完了  | idle       | §2.10  |
| generation-status | DRAFT      | 情報不足検出 | INCOMPLETE | §2.11  |
| generation-status | DRAFT      | 生成完了     | READY      | §2.11  |

**NOTE**: 各モードの詳細は定義元セクション参照。

### 2.4 コマンド制約

| コマンド | 実行ACCEPTANCE       | 副作用                                | 再入 |
| -------- | -------------------- | ------------------------------------- | ---- |
| /begin   | PENDING              | CLEAR :buffer                         | 可   |
| /review  | PENDING→ACTIVE(一時) | EXEC_MODE: idle→proc→idle             | 禁止 |
| /write   | PENDING→ACTIVE(一時) | EXEC_MODE: idle→proc→idle             | 禁止 |
| /exit    | *                    | CLEAR ALL, EXEC_MODE=idle             | -    |
| /reset   | *                    | CLEAR :var.. (スコープ内のみ)         | -    |
| /set     | *                    | SET :var=value (スコープ内上書き許可) | -    |

NOTE: /review, /write = EXEC_MODE 遷移必須、再入禁止。ACCEPTANCE=* はすべての状態で実行可能。

### 2.5 変数スコープ

| スコープ | ライフタイム | 変数例                | クリア |
| -------- | ------------ | --------------------- | ------ |
| SESSION  | /exit まで   | :role, :link, :remark | /exit  |
| REVIEW   | /begin まで  | :buffer, :review      | /begin |

NOTE: 暗黙可変、初期値=空文字列、再代入=スコープ内上書き。

### 2.6 実行規約

| 項目       | 規則                                      |
| ---------- | ----------------------------------------- |
| 評価順序   | DEF順・上から下                           |
| 再定義     | 禁止                                      |
| VAR        | 暗黙可変、初期値=空文字列                 |
| EXECUTE    | 列挙手順のみ (Appendix参照のみ、実行禁止) |
| 停止条件   | LLM判断依存、明示推奨                     |
| アクション | CLEAR -> SET -> EXECUTE -> SET ACCEPTANCE |

NOTE: CLEAR ALL = 全スコープクリア。`DEF /begin THEN CLEAR :buffer -> SET ACCEPTANCE=PENDING END`

### 2.7 INSERT合成

```bnf
合成順 ::= BEFORE(逆順) → 元BODY → AFTER(順順)
制約   ::= CONSTRAINT_1 AND CONSTRAINT_2 AND ...
```

NOTE: `INSERT /cmd BEFORE` = 後定義→先実行 | `AFTER` = 先定義→先実行。

### 2.8 イベントシステム

| 要素           | 規則                  |
| -------------- | --------------------- |
| 責務           | 通知専用 (副作用禁止) |
| ACCEPTANCE遷移 | SET明示必須           |
| handler内      | SET許可 (復旧のみ)    |
| EMIT           | WITH payload (省略可) |

NOTE: `DEF EVENT ProcessStarted WITH cmd:text THEN END | EMIT ProcessStarted WITH cmd="/review"`

### 2.9 CONSTRAINT

| 要素        | 用途           | 禁止用途               |
| ----------- | -------------- | ---------------------- |
| PRIORITY    | 衝突時選択指針 | 適用可否・評価順序制御 |
| description | 説明文         | 判定・制御ロジック     |
| label       | 表示名         | 識別子・検索キー       |
| free-text   | 自由記述       | パース・構文解析       |

NOTE: PRIORITY = OUTPUT 生成時の優先度表示・複数指摘競合時の重み付けのみ。

### 2.10 エラーハンドリング

#### 基本処理規則

| 状況     | 処理                                      | ACCEPTANCE/EXEC    |
| -------- | ----------------------------------------- | ------------------ |
| 情報不足 | EMIT ProcessFailed -> Open Questions出力  | 現状維持           |
| 判断不能 | CONSTRAINT確認 -> :remark優先 -> 保守選択 | 現状維持           |
| 未完成   | 停止 -> /begin再入力促進                  | ACCEPTANCE=PENDING |
| 実行中断 | EXEC_MODE: proc->idle, ACCEPTANCE復帰     | SESSION保持        |

NOTE: 未完成=TODO/メモ/箇条のみ検出時。エラー時=SESSION/REVIEW 変数保持。

**NOTE**: 2.10 = 実行時エラー処理 | 2.11 = 事前検証ステータス。INCOMPLETE は generation-status (§2.11)、情報不足は処理エラー (§2.10)。

### 2.11 記事生成ステータス

| ステータス | 意味         | 遷移条件     |
| ---------- | ------------ | ------------ |
| DRAFT      | 生成開始状態 | 処理開始     |
| INCOMPLETE | 情報不足     | 必須情報欠落 |
| READY      | 生成完了     | 記事生成完了 |

**meta_state 協調** (判別共用体制御):

| meta_state | generation-status | OUTPUT variant | 使用ケース     |
| ---------- | ----------------- | -------------- | -------------- |
| none       | DRAFT/INCOMPLETE  | (生成なし)     | 情報不足       |
| rejected   | *                 | RejectResult   | Fail-Fast 拒否 |
| generated  | READY             | ReviewResult   | 正常レビュー   |
| generated  | READY             | ErrorResult    | 処理エラー     |

**遷移規則**:

| 遷移             | トリガー     | 効果                       |
| ---------------- | ------------ | -------------------------- |
| DRAFT→INCOMPLETE | 情報不足検出 | ACCEPTANCE=PENDING遷移促進 |
| DRAFT→READY      | 生成完了     | OUTPUT許可                 |
| INCOMPLETE→input | 再入力要求   | 追加情報入力               |

**CONSTRAINT**:

- OUTPUT は generation-status=READY かつ meta_state=generated/rejected の場合のみ生成
- generation-status=INCOMPLETE 時は OUTPUT 生成禁止、ACCEPTANCE=PENDING 遷移促進
- meta_state は OUTPUT 判別共用体の discriminator として機能
- generation-status は宣言的制約 (実行ディレクティブでない)

**NOTE**: generation-status vs ACCEPTANCE 分離 - ACCEPTANCE=UI 層 | generation-status=成果物準備層。EXECUTE_MODE(処理層)とも独立。

### 2.12 フォールバック規則

LLM が仕様を守らない場合の縮退動作を定義します。

#### コマンド解釈失敗時

| 状況               | フォールバック動作                   | ACCEPTANCE/EXEC    |
| ------------------ | ------------------------------------ | ------------------ |
| コマンド不明       | 基本レビューモードに縮退             | ACCEPTANCE=PENDING |
| パラメータ欠落     | デフォルト値使用（全セクション対象） | 現状維持           |
| コマンド構文エラー | エラー通知 → `/begin` 再入力促進     | ACCEPTANCE=PENDING |

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

```COBOL
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

| 状況                         | フォールバック動作                    | 内容                |
| ---------------------------- | ------------------------------------- | ------------------- |
| generation-status=INCOMPLETE | OUTPUT 生成スキップ → 情報不足通知    | Open Questions 出力 |
| CATEGORY 判定不能            | `[CATEGORY:unknown]` 付与、PRIORITY=B | デフォルト分類使用  |
| PRIORITY 算出失敗            | PRIORITY=B (中優先度)                 | 保守的優先度設定    |

**NOTE**: 判定不能時は保守的設定（PRIORITY=B）を採用。過小評価より過大評価を優先。

#### 制約違反時の処理順序

1. CONSTRAINT 確認
2. :remark 優先適用（ユーザー指定）
3. フォールバック規則適用
4. 保守的設定採用

**CONSTRAINT**: フォールバック規則適用時も `:remark` > システムデフォルトの優先順位を維持。

**NOTE**: フォールバック規則は本セクションで一度のみ定義。

---

## 3. ポリシー (Policy Layer)

### 3.1 Review Philosophy

```abnf
PHILOSOPHY REVIEW:
  GOAL={QUALITY_IMPROVEMENT, AUTHOR_INTENT_RESPECT} | NON_GOAL={REWRITE, STYLE_OVERRIDE}
  INTERVENTION: HIGH={TECHNICAL_ERROR, API_MISUSE} | MEDIUM={STRUCTURAL_ISSUE, LOGIC_CONTRADICTION} | LOW={EXPRESSION_OPTIMIZATION}
  TONE: UPPER={TECHNICAL_ERROR_EXPLICIT, CONCRETE_ALTERNATIVE} | LOWER={SUBJECTIVE_PREFERENCE, VAGUE_IMPROVEMENT}
  CHANGE: PERMITTED={TYPO_FIX, GRAMMAR_CORRECTION, TERM_UNIFICATION} | PROHIBITED={CLAIM_ALTERATION, DESIGN_REWRITE, SECTION_DELETION}
  VIOLATION: STYLE_OVERRIDE→D | INTENT_DISREGARD→D+CONFIRM | SUBJECTIVE_BIAS→E | SCOPE_EXCESS→D
```

**介入レベル判定**:

| レベル | 判定条件         | 根拠要件               | PRIORITY |
| ------ | ---------------- | ---------------------- | -------- |
| HIGH   | 技術的誤り検出   | :link検証済 OR 公式Doc | A        |
| MEDIUM | 論理的不整合検出 | 文書内の複数箇所比較   | B        |
| LOW    | 表現改善提案     | ベストプラクティス     | C        |

### 3.2 Fail-Fast Policy

```abnf
RULE FAIL_FAST:
  IF structural_collapse → INCOMPLETE + "構造崩壊"
  IF technical_fatality → SKIP + "技術的致命傷"
  IF unreadability → INCOMPLETE + "可読性未確立"
  IF insufficient_length → INCOMPLETE + "文章量不足"
  IF incomplete_content → INCOMPLETE + "未完成"
```

**判定基準 (形式化・検出方法)**:

| 条件                | 検出方法                                          | 閾値                   | 根拠             |
| ------------------- | ------------------------------------------------- | ---------------------- | ---------------- |
| structural_collapse | 見出し階層飛び: `^#{1,6}` regex, 必須section欠落  | gap>1 OR 概要/結論なし | 構造破綻         |
| technical_fatality  | コードブロック未閉: `` ``` `` ペア不整合, API誤用 | unclosed>0 OR errors≥3 | 実行不可能       |
| unreadability       | 主題文欠落率, 接続詞密度                          | 欠落率>50% OR 接続<10% | 意図伝達不可     |
| insufficient_length | Unicode文字数 (コードブロック除外)                | <500文字               | レビュー対象不足 |
| incomplete_content  | TODO/TBDマーカー: `/TODO\|FIXME\|TBD\|WIP/`, 箇条 | ≥1個 OR 比率>30%       | 未完成           |

**NOTE**: 閾値はヒューリスティック。建設的な再提出ガイド必須。拒否=「前提条件未達」(「改善余地なし」でない)。

### 3.3 Priority Conversion

```abnf
CATEGORY→PRIORITY写像 (enum定義: §4.6):
  inaccuracy → A (if :link有) | B (if :linkなし)
  inconsistency → B
  readability → C
  unknown → B (保守的)

VIOLATION降格 (enum定義: §4.6):
  STYLE_OVERRIDE → force D
  INTENT_DISREGARD → force D + USER_CONFIRM
  SUBJECTIVE_BIAS → force E
  SCOPE_EXCESS → force D
```

**優先順位**: `:remark` > VIOLATION 降格 > CATEGORY 写像 > デフォルト。

### 3.4 制約規則統合

**Philosophy enforcement**:

- 違反ラベル付き指摘は自動降格
- LLM は違反を自己検出し、違反に応じたラベルの付与が必須
- レビュー出力は哲学原則に従う
- `:remark` で明示的に指定された場合のみ例外を許可

**ACCEPTANCE principle** (**→ See Section 2.3 for full ACCEPTANCE definition**):

**Fail-fast constraints**:

- 建設的な再提出ガイドを必ず提供
- レビュー拒否は「レビュー前提条件未達」を意味する (「改善の余地なし」ではない)

**Output generation guard**:

- OUTPUT は generation-status=READY かつ meta_state=generated/rejected の場合のみ生成
- INCOMPLETE 状態は OUTPUT 生成禁止、ACCEPTANCE=PENDING 遷移促進
- 生成系プロンプトで適用、レビュー系では不要

**Enum constraints**:

- CATEGORY/PRIORITY の enum 拡張は禁止 (closed: true)
- VIOLATION/STATUS の enum 拡張は禁止 (closed: true)
- VIOLATION 付き指摘は自動的に PRIORITY 降格 (side_effects 定義に従う)
- STATUS 付き指摘はレビュー保留状態、ユーザー応答待機
- 同一指摘に VIOLATION+STATUS の両方付与可能、効果は累積
- `unknown` カテゴリは判定不能時のフォールバック専用、通常使用禁止

**Override mechanism**:

- `:remark` はすべての規則を上書き可能
- フォールバック規則適用時も `:remark` > システムデフォルト
- CATEGORY→PRIORITY 写像は `:remark` で上書き可能

---

## 4. 標準マクロ

### 4.1 入力セクション

```bnf
BEGIN INPUT
/set :role = | - <役割>
/set :link = | - <URL> (<目的>)
/set :remark = "<特記>"
END INPUT
```

NOTE: 変数初期化専用。値形式: `"text"` (文字列) | `|` (複数行) | `""""` (heredoc)。

### 4.2 標準コマンド

| コマンド             | 動作 (実行ACCEPTANCE: §2.3)       | 値形式           |
| -------------------- | --------------------------------- | ---------------- |
| /begin               | CLEAR :buffer->ACCEPTANCE=PENDING | -                |
| /end                 | ACCEPTANCE=PENDING                | -                |
| /exit                | CLEAR ALL->ACCEPTANCE=PENDING     | -                |
| /reset <:var..>      | CLEAR :var..                      | -                |
| /set <:var>=\<value> | SET :var=value                    | "text"\|\|\|"""" |

NOTE: スコープ内上書き可。SESSION=/exit, REVIEW=/begin。

### 4.3 標準変数

| 変数    | スコープ | 用途                           | クリア |
| ------- | -------- | ------------------------------ | ------ |
| :role   | SESSION  | ユーザー役割                   | /exit  |
| :link   | SESSION  | 参考URL (文体抽象化、模倣禁止) | /exit  |
| :remark | SESSION  | 特記事項                       | /exit  |
| :buffer | REVIEW   | 入力蓄積                       | /begin |
| :review | REVIEW   | 処理結果                       | /begin |

### 4.4 標準イベント

| イベント           | タイミング     | ペイロード                      |
| ------------------ | -------------- | ------------------------------- |
| ProcessStarted     | 開始           | command:text, mode:mode         |
| ProcessInterrupted | 中断           | reason:text, previous_mode:mode |
| ProcessCompleted   | 完了           | result:object                   |
| ProcessFailed      | 失敗           | error:text                      |
| ModeChanged        | ACCEPTANCE遷移 | from:mode, to:mode              |

### 4.5 文章位置定義

```bnf
LOCATION ::= セクションID.ノード種別.文章インデックス
セクションID ::= 見出し[番号]
ノード種別 ::= paragraph | list_item | heading
文章インデックス ::= node[n].sentence[m]
文区切り ::= 。 | ？ | ！ | :
```

### 4.6 出力構造

#### OUTPUT形式スキーマ (厳密定義・判別共用体)

```yaml
# JSON Schema相当の厳密な型定義
OUTPUT:
  meta_state: none | rejected | generated
  # none: 未生成 (generation-status≠READY)
  # rejected: 拒否 (RejectResult)
  # generated: 正常 (ReviewResult/ErrorResult)

  type: discriminated-union
  discriminator: meta_state
  variants:
    - ReviewResult # meta_state=generated
    - ErrorResult # meta_state=generated
    - RejectResult # meta_state=rejected

# レビュー結果 (通常ケース)
ReviewResult:
  type: object
  required: [findings] # 必須フィールド
  properties:
    findings:
      type: array
      minItems: 0
      items: Finding
      description: "指摘リスト (0件以上の配列) "
    summary:
      type: string?
      description: "総括コメント (省略可能) "
    open_questions:
      type: array?
      items: string
      description: "未解決質問リスト (省略可能) "

# 個別指摘 (順序固定・必須フィールド明示)
Finding:
  type: object
  format: key-value-lines # "key: value\n" 形式
  field_order: strict # フィールド順序厳守
  required: [指摘種別, CATEGORY, PRIORITY, 識別子, 該当箇所, 内容, 根拠]
  properties:
    指摘種別:
      type: enum
      values: ["修正必須", "注意喚起", "判断保留"]
      description: "指摘の性質分類"
    CATEGORY:
      type: enum
      values: ["readability", "inconsistency", "inaccuracy", "unknown"]
      description: "カテゴリ (技術分類) "
    PRIORITY:
      type: enum
      values: ["A", "B", "C", "D", "E"]
      description: "優先度 (A=最高、E=最低) "
    識別子:
      type: string
      pattern: "^[a-zA-Z0-9_-]+$"
      uniqueness: session-scoped
      description: "セッション内一意識別子"
    該当箇所:
      type: string
      format: LOCATION
      description: "4.5で定義されたLOCATION形式"
    内容:
      type: string
      minLength: 1
      description: "指摘内容 (必須、空文字列禁止) "
    根拠:
      type: string
      minLength: 1
      description: "判断理由 (必須、空文字列禁止) "
    VIOLATION:
      type: enum?
      values: ["STYLE_OVERRIDE", "INTENT_DISREGARD", "SUBJECTIVE_BIAS", "SCOPE_EXCESS"]
      description: "哲学違反ラベル (省略可能) "
      side_effect: "PRIORITY自動降格→D"
    STATUS:
      type: enum?
      values: ["QUESTION_REQUIRED", "CLARIFICATION_NEEDED"]
      description: "状態ラベル (省略可能) "

  # フィールド出力順序 (厳密)
  output_order:
    1: 指摘種別
    2: CATEGORY
    3: PRIORITY
    4: 識別子
    5: 該当箇所
    6: 内容
    7: 根拠
    8: VIOLATION # 存在する場合
    9: STATUS # 存在する場合

  # 区切り規則
  separator: "\n" # フィールド間改行
  finding_separator: "\n---\n" # 指摘間区切り

# エラー結果
ErrorResult:
  type: object
  required: [ERROR, REASON]
  properties:
    ERROR:
      type: enum
      values: ["VALIDATION_FAILED", "BUFFER_UNDEFINED", "PROCESSING_ERROR"]
    REASON:
      type: string
      minLength: 1
    open_questions:
      type: array?
      items: string

# レビュー拒否結果
RejectResult:
  type: object
  required: [REVIEW_REJECTED, REASON, FAIL_FAST_CONDITION]
  properties:
    REVIEW_REJECTED:
      type: literal
      value: true
    REASON:
      type: string
      minLength: 1
    FAIL_FAST_CONDITION:
      type: enum
      values: [
        "structural_collapse",
        "technical_fatality",
        "unreadability",
        "insufficient_length",
        "incomplete_content",
      ]
    RECOMMENDATION:
      type: string?
      description: "再提出ガイド (推奨) "
```

#### スキーマ検証ルール

| 検証項目       | ルール                               | 違反時の処理         |
| -------------- | ------------------------------------ | -------------------- |
| フィールド順序 | output_order 厳守 (1→2→3...→9の順)   | スキーマ違反エラー   |
| 必須フィールド | required配列のすべてが存在           | スキーマ違反エラー   |
| enum値         | values配列内の値のみ許可             | スキーマ違反エラー   |
| 識別子一意性   | uniqueness: session-scoped 違反禁止  | 重複エラー           |
| 文字列長制約   | minLength: 1 違反禁止 (空文字列不可) | バリデーションエラー |
| パターン制約   | pattern正規表現に一致                | フォーマットエラー   |
| 配列要素数     | minItems制約を満たす                 | バリデーションエラー |
| 区切り文字     | separator/finding_separator厳守      | パースエラー         |

#### 出力形式例 (スキーマ準拠)

```MACRO
指摘種別: 修正必須
CATEGORY: inaccuracy
PRIORITY: A
識別子: finding-001
該当箇所: セクション1.paragraph[0].sentence[1]
内容: API仕様の誤記があります。正しくは `fetch()` ではなく `fetchData()` です。
根拠: 公式ドキュメント (https://example.com/api) で確認しました。

---

指摘種別: 注意喚起
CATEGORY: readability
PRIORITY: C
識別子: finding-002
該当箇所: セクション2.paragraph[2].sentence[0]
内容: 冗長な表現を簡潔にすることを推奨します。
根拠: 技術文書では明瞭さが重要です。
VIOLATION: STYLE_OVERRIDE
```

**NOTE**:

- フィールド順序は厳密に 1→9 の順 (上記スキーマの output_order に従う)
- 指摘間の区切りは `\n---\n` (3行：空行、ハイフン 3つ、空行)
- 識別子は `[a-zA-Z0-9_-]+` 形式、セッション内一意
- VIOLATION/STATUS は存在する場合のみ出力 (順序は 8→9)
- meta_state は discriminator として OUTPUT variant を決定

#### 4.6.1 Enum定義集約 (Authoritative Enum Definitions)

本セクションは CATEGORY/PRIORITY/VIOLATION/STATUS の全 enum 定義を集約。他セクションは本セクションを参照。

#### PRIORITY enum定義 (全集合)

```yaml
PRIORITY:
  type: enum
  values:
    - A # 最高優先度 (致命的) - 技術的誤り (:link検証済み)
    - B # 高優先度 (重要) - 構造的問題、不整合
    - C # 中優先度 (推奨) - 可読性、表現改善
    - D # 低優先度 (任意) - スタイル提案、哲学違反時の降格先
    - E # 最低優先度 (情報) - 参考情報、補足
  closed: true # 拡張禁止、上記5値のみ許可
```

| PRIORITY | 意味                | 用途                                    | 自動設定条件                                        |
| -------- | ------------------- | --------------------------------------- | --------------------------------------------------- |
| A        | 最高優先度 (致命的) | 技術的誤り (:link検証済み)              | CATEGORY=inaccuracy + :link有                       |
| B        | 高優先度 (重要)     | 構造的問題、不整合、技術的誤り (未検証) | CATEGORY=inconsistency または inaccuracy(:linkなし) |
| C        | 中優先度 (推奨)     | 可読性、表現改善                        | CATEGORY=readability                                |
| D        | 低優先度 (任意)     | スタイル提案、哲学違反降格              | VIOLATION付き指摘の自動降格先                       |
| E        | 最低優先度 (情報)   | 参考情報、補足                          | VIOLATION=SUBJECTIVE_BIAS                           |

#### CATEGORY enum定義 (全集合)

```yaml
CATEGORY:
  type: enum
  values:
    - inaccuracy # 技術的誤り
    - inconsistency # 不整合
    - readability # 可読性
    - unknown # 判定不能 (フォールバック用)
  closed: true # 拡張禁止、上記4値のみ許可
  default_priority_mapping:
    inaccuracy: "A (if :link exists) else B"
    inconsistency: B
    readability: C
    unknown: B # 保守的設定
```

| CATEGORY      | 意味       | デフォルトPRIORITY          | 使用条件                      |
| ------------- | ---------- | --------------------------- | ----------------------------- |
| inaccuracy    | 技術的誤り | A (:link有) / B (:linkなし) | 事実誤認、API誤用、コードバグ |
| inconsistency | 不整合     | B                           | 用語不統一、論理矛盾          |
| readability   | 可読性     | C                           | 冗長表現、構造改善            |
| unknown       | 判定不能   | B (保守的設定)              | フォールバック専用            |

**CONSTRAINT**:

- CATEGORY/PRIORITY の enum 拡張は禁止 (closed: true)
- CATEGORY→PRIORITY 写像は `:remark` で上書き可能
- `unknown` カテゴリは判定不能時のフォールバック専用、通常使用禁止

#### 違反ラベル enum定義 (哲学違反検知)

```yaml
VIOLATION:
  type: enum? # 省略可能
  values:
    - STYLE_OVERRIDE # 著者文体への過度介入
    - INTENT_DISREGARD # 著者意図の無視
    - SUBJECTIVE_BIAS # 主観的判断の押し付け
    - SCOPE_EXCESS # レビュー範囲逸脱
  closed: true # 拡張禁止、上記4値のみ
  side_effects:
    STYLE_OVERRIDE: "PRIORITY降格→D"
    INTENT_DISREGARD: "PRIORITY降格→D + ユーザー確認要求"
    SUBJECTIVE_BIAS: "PRIORITY降格→E"
    SCOPE_EXCESS: "PRIORITY降格→D"

STATUS:
  type: enum? # 省略可能
  values:
    - QUESTION_REQUIRED # 意図確認必須
    - CLARIFICATION_NEEDED # 追加情報必要
  closed: true # 拡張禁止、上記2値のみ
  side_effects:
    QUESTION_REQUIRED: "レビュー保留、追加情報入力待機"
    CLARIFICATION_NEEDED: "レビュー保留、明確化要求"
```

| ラベル                       | タイプ | 効果                       | PRIORITY | 使用条件                   |
| ---------------------------- | ------ | -------------------------- | -------- | -------------------------- |
| VIOLATION: STYLE_OVERRIDE    | 違反   | 指摘を D に降格            | D        | 著者文体への過度介入検出時 |
| VIOLATION: INTENT_DISREGARD  | 違反   | ユーザー確認プロンプト表示 | D        | 著者意図の無視検出時       |
| VIOLATION: SUBJECTIVE_BIAS   | 違反   | 指摘を情報提供に変更       | E        | 主観的判断の押し付け検出時 |
| VIOLATION: SCOPE_EXCESS      | 違反   | レビュー範囲逸脱通知       | D        | スコープ外指摘検出時       |
| STATUS: QUESTION_REQUIRED    | 状態   | 追加情報要求、レビュー保留 | -        | 意図不明とき               |
| STATUS: CLARIFICATION_NEEDED | 状態   | 明確化要求、レビュー保留   | -        | 情報不足時                 |

**CONSTRAINT**:

- VIOLATION/STATUS の enum 拡張は禁止 (closed: true)
- VIOLATION 付き指摘は自動的に PRIORITY 降格 (side_effects 定義に従う)
- STATUS 付き指摘はレビュー保留状態、ユーザー応答待機
- 同一指摘に VIOLATION+STATUS の両方付与可能、効果は累積

**CONSTRAINT OUTPUT generation guard**:

- OUTPUT は generation-status=READY かつ meta_state=generated/rejected の場合のみ生成
- generation-status=INCOMPLETE 時は OUTPUT 生成禁止、ACCEPTANCE=PENDING 遷移促進
- meta_state は OUTPUT 判別共用体の discriminator として機能
- 生成系プロンプト (article-writer.prompt 等) で適用、レビュー系では不要

### 4.7 標準パターン

#### コマンド実行フェーズパターン

| フェーズ | アクション                       |
| -------- | -------------------------------- |
| 前処理   | EXEC_MODE=processing, CLEAR :var |
| 入力検証 | :buffer検証(定義・非空・文字数)  |
| 処理実行 | 指示適用、結果生成               |
| 後処理   | EXEC_MODE=idle                   |

NOTE: /review, /write 等の処理コマンドに共通する 4 フェーズ構造。

#### 入力検証パターン

| 項目        | 条件             | 失敗時アクション                       |
| ----------- | ---------------- | -------------------------------------- |
| :buffer定義 | defined(:buffer) | EMIT ProcessFailed, ACCEPTANCE=PENDING |
| :buffer非空 | length > 0       | EMIT ProcessFailed, ACCEPTANCE=PENDING |
| 文字数      | length >= N      | 警告("推奨: N文字以上")                |

NOTE: agent/CLI/MCP 連携時の挙動安定化。検証失敗時=診断メッセージ出力。

#### CATEGORY→PRIORITY写像パターン

| Category      | 条件      | PRIORITY |
| ------------- | --------- | -------- |
| inaccuracy    | :linkあり | A        |
| inaccuracy    | :linkなし | B        |
| inconsistency | -         | B        |
| readability   | -         | C        |

NOTE: :remark で上書き可能。複数該当時=最高優先度採用。

---

## 5. スタイル指針

### 5.1 命名規則

| 要素                     | 型           | 制約       | スタイル              | 例                           |
| ------------------------ | ------------ | ---------- | --------------------- | ---------------------------- |
| ACCEPTANCE/CMD/VAR/EVENT | `<ascii-id>` | 英数字-_   | snake_case/PascalCase | cmd, :buf, ModeChg           |
| FIELD/RULE               | `<label>`    | 日本語許可 | -                     | 重要度, セクションID         |
| AS                       | -            | 表示名     | 日本語推奨            | ACCEPTANCE cmd AS "コマンド" |

NOTE: コード参照=識別子 | LLM 出力=AS 優先。

### 5.2 コーディングスタイル

| 項目     | 規則                                   |
| -------- | -------------------------------------- |
| 形式     | インライン (`->`, 120文字) \| ブロック |
| EXECUTE  | 1文=1責務、ACCEPTANCE遷移・SET明示     |
| 制約     | CONSTRAINT/EVENT形式化                 |
| 出力構造 | トレーサビリティ・再現性保証           |

### 5.3 EXECUTE 運用ガイドライン

EXECUTE 文は操作的ディレクティブ (operational directive) であり、慎重な使用が必要です。

| リスク            | アンチパターン                 | 推奨パターン                 | ガイドライン                                 |
| ----------------- | ------------------------------ | ---------------------------- | -------------------------------------------- |
| verbosity         | 長大な EXECUTE 文              | 段階的 EXECUTE 分割          | 1 statement = 1 責務原則                     |
| state_deviation   | EXECUTE 内で暗黙的状態遷移     | 明示的 SET 文で状態変更      | SESSION_PHASE 遷移は明示的に SET で記述      |
| implicit_trans    | 事後条件を暗黙的に仮定         | CONSTRAINT で明記            | 停止条件・前提条件は形式化                   |
| flow_control_leak | EXECUTE で通常フロー制御を迂回 | COMMAND による明示的制御     | EXECUTE は例外処理のみ、通常フローは COMMAND |
| execution_assumed | Appendix 記載=実行と誤解       | 「参照のみ・実行禁止」を明記 | EXECUTE は列挙手順のみ (実行は LLM 判断)     |

**CONSTRAINT**:

- EXECUTE 文内での ACCEPTANCE 遷移は禁止 (明示的 SET で記述)
- EXECUTE は宣言的記述、LLM への指針提供が目的 (強制実行ではない)
- EXECUTE 文は Appendix の手順を「参照」、自動実行は行わない

**NOTE**: EXECUTE 文の過剰使用は DSL の宣言的性質を損なう。通常フロー制御は COMMAND/EVENT で表現。

### 5.4 出力CONSTRAINT

| 項目             | 要求                                     |
| ---------------- | ---------------------------------------- |
| トレーサビリティ | 重複排除、根拠明示、改善案対応、後段連携 |
| 一貫性           | 指摘固定、優先度安定、スタイル統一       |
| 1:1対応          | 指摘→根拠→改善案の追跡可能性             |

### 5.5 アンチパターン

#### 一般アンチパターン

| 禁止事項                       | 理由                |
| ------------------------------ | ------------------- |
| EVENT内ACCEPTANCE遷移 (復旧外) | フロー制御迂回      |
| NOTE内容での制御               | 意味論レイヤー混同  |
| PRIORITY評価順序制御           | 用途外使用          |
| description判定                | テキストのパース    |
| Appendix暗黙実行               | EXECUTE明示原則違反 |

#### EVENT handler アンチパターン (SESSION_PHASE制御)

EVENT handler は異常系復旧専用であり、通常フロー制御に使用禁止です。

| 禁止パターン          | 理由                         | 推奨代替                                |
| --------------------- | ---------------------------- | --------------------------------------- |
| normal_flow_control   | 通常フロー制御の迂回         | COMMAND による明示的フロー制御          |
| conditional_branching | 条件分岐の隠蔽               | COMMAND 内での明示的条件分岐            |
| arbitrary_transition  | SESSION_PHASE の恣意的遷移   | COMMAND による明示的 SESSION_PHASE 遷移 |
| implicit_state_change | 状態変更の暗黙化             | SET 文による明示的状態変更              |
| handler_chaining      | handler 連鎖によるフロー構築 | COMMAND 連鎖                            |

**許可用途** (復旧のみ):

| 許可パターン             | 用途                       | 例                                               |
| ------------------------ | -------------------------- | ------------------------------------------------ |
| abnormal_termination_rec | 異常終了からの復旧         | `ON ProcessFailed DO SET ACCEPTANCE=PENDING END` |
| error_rollback           | エラー時の状態ロールバック | `ON ValidationError DO CLEAR :buffer END`        |

**CONSTRAINT**:

- EVENT handler 内での SESSION_PHASE 遷移は復旧目的のみ許可
- 通常フロー制御・条件分岐・遷移規則迂回は COMMAND で表現
- EVENT は「通知」、handler は「復旧」のみの責務

**NOTE**: EVENT handler の過剰使用は DSL の宣言的性質を損なう。通常フロー制御は COMMAND で明示的に表現。

---

END OF SPECIFICATION
