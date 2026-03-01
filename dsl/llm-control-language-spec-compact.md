---
title: LCL Runtime DSL
version: 2.0
type: compact-runtime
architecture: meta / syntax / runtime / output / projection
---

## 0 Meta Notation

```text
[x]         optional
[x..]       repetition
x|y         choice
x->y        sequence
<type>      type
"text"      literal
:id         variable
/cmd        command
*           repetition
;           comment
|           multiline
BEGIN..END  block
DEF..END    definition
```

Purpose:

```text
DSL shared structure for LLM runtime interpretation
Not a full grammar validator
```

## 1 Backbone Grammar

```text
macro =
   "DEF" target "THEN" body "END"
 / "INSERT" command position body "END"
 / "ON" event "DO" body "END"
 / meta-block

target =
   ACCEPTANCE
 | COMMAND
 | VAR
 | PRIORITY
 | OUTPUT
 | LOCATION
 | EVENT
 | STATUS

command  = "/" identifier
event    = identifier
position = BEFORE | AFTER

meta-block =
   "BEGIN" type "DEF" <opaque> "END" "DEF"

type =
   DSL
 | MACRO
 | RULE
 | INPUT
 | OUTPUT
```

## 2 Core Grammar

```text
macro       = "DEF" target "THEN" body "END"
command     = "/" token [option]
option      = "--" name "=" value

variable    = "VAR" scope ":" name ["=" value]

body        = *action
action      = set | clear | execute | emit | chain

set         = "SET" var "=" value
clear       = "CLEAR" (var | "ALL")

execute     = "EXECUTE" desc
emit        = "EMIT" event

chain       = action "->" action

input-block = "BEGIN INPUT" *set "END INPUT"

scope       = SESSION | REVIEW
mode        = PENDING | ACTIVE
gen-status  = DRAFT | INCOMPLETE | READY
exec-mode   = idle | processing
```

## 3 Runtime Execution Model

Execution Flow:

```text
1 parse DSL
2 validate semantics
3 execute command
4 produce canonical output
5 apply projection
```

State Model:

```text
ACCEPTANCE
  PENDING
  ACTIVE

EXEC_MODE
  idle
  processing

generation-status
  DRAFT
  INCOMPLETE
  READY
```

Rules:

```text
PENDING → no output
ACTIVE  → command allowed
processing → factual output only
```

## 4 Variable Scope

```text
SESSION
 lifetime = /exit

REVIEW
 lifetime = /begin
```

Example:

```text
:theme
:target
:goal
:link
:remark
```

## 5 Command Constraints

```text
/begin
 CLEAR :buffer
 ACCEPTANCE=PENDING

/review
 ACCEPTANCE=PENDING->ACTIVE
 EXEC_MODE idle->processing->idle

/write
 ACCEPTANCE=PENDING->ACTIVE

/exit
 CLEAR ALL
 ACCEPTANCE=PENDING
```

## 6 Canonical Output Contract

Authoritative machine schema:

```text
meta_state =
  none
  rejected
  generated
```

Output Variants:

```text
ReviewResult
ErrorResult
RejectResult
```

Finding:

```text
Finding
  CATEGORY
  PRIORITY
  identifier
  location
  message
  rationale
```

Proposal:

```text
Proposal
  identifier
  type
  before
  after
  rationale
```

## 7 Enumerations

Priority:

```text
A
B
C
D
E
```

Category:

```text
inaccuracy
inconsistency
readability
unknown
```

Violation:

```text
STYLE_OVERRIDE
INTENT_DISREGARD
SUBJECTIVE_BIAS
SCOPE_EXCESS
```

Status:

```text
QUESTION_REQUIRED
CLARIFICATION_NEEDED
```

## 8 Priority Resolution

```text
remark override
→ violation rule
→ category rule
→ default
```

Category mapping:

```text
inaccuracy + link → A
inaccuracy       → B
inconsistency    → B
readability      → C
unknown          → B
```

Violation override:

```text
STYLE_OVERRIDE   → D
INTENT_DISREGARD → D
SUBJECTIVE_BIAS  → E
SCOPE_EXCESS     → D
```

## 9 Projection Layer

Projection converts canonical output to view.

```text
canonical → projection → UI
```

Example:

```text
PROJECTION review_table

IssueID = auto
Importance = PRIORITY
Category = CATEGORY
Location = location
Message = message
```

Example:

```text
PROJECTION proofreading_diff

Before = original
After = revised
Reason = explanation
```
