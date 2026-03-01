---
title: LCL — LLM Control Language
type: specification
domain: llm-control-language
version: 3.0.0

description: ><
  LCL (LLM Control Language) is a domain-specific language for controlling
  structured interactions between users and large language models. It defines
  a deterministic execution model composed of a DSL core, runtime contract,
  canonical output schema, and projection system. The specification enables
  reproducible prompt execution and compatibility with agent-based systems
  such as MCP.


architecture: >
  Layered architecture separating language definition, runtime execution,
  and output representation. The system consists of four layers: DSL Core,
  Runtime Contract, Canonical Output Contract, and Projection Contract.
  Canonical output provides a machine-consumable schema, while projections
  transform the canonical structure into human-readable views. This design
  ensures deterministic behavior and agent compatibility.

status: draft
author: atsushifx
update: 2026-03-01
---

## 1 Overview

LCL (LLM Control Language) is a deterministic prompt execution language.
designed to control structured interactions between users and LLM systems.

The language provides:

- DSL syntax
- macro extension
- event-driven runtime
- canonical machine output
- projection system for human views

Architecture:

```text
DSL Core
Macro System
Event System
Runtime Contract
Canonical Output
Projection
```

## 2 Design Principles

LCL follows five principles.

1. Deterministic execution
2. Explicit state machine
3. Event-driven runtime
4. Canonical machine output
5. Projection-based presentation

## 3 DSL Core

### 3.1 Commands

Commands trigger execution.

```text
/begin
/end
/review
/write
/chart
/appendix
/reset
/set
/exit
```

Command semantics are defined in the runtime section.

### 3.2 Variables

Variables configure prompt behavior.

Example:

```abnf
/set :theme = "..."
/set :target = "..."
/set :goal = "..."
/set :remark = "..."
```

Scopes:

```abnf
SESSION
REVIEW
```

### 3.3 Blocks

#### INPUT

```abnf
BEGIN INPUT
SET :buffer = "..."
END INPUT
```

#### META

```abnf
BEGIN DSL DEF
...
END DEF
```

Meta blocks are ignored by runtime execution.

## 4 Macro System

Macros extend DSL behavior.

```abnf
DEF COMMAND /review THEN
  EXECUTE validate_buffer
  EXECUTE apply_review_rules
END
```

Macro targets:

```abnf
COMMAND
VAR
EVENT
RULE
STATUS
OUTPUT
```

Supported actions:

```abnf
SET
CLEAR
EXECUTE
EMIT
```

Example:

```abnf
DEF RULE FAIL_FAST THEN
  IF structural_collapse
  THEN EMIT ProcessFailed
END
```

## 5 Event System

Events provide runtime notifications.

Definition:

```abnf
EVENT ProcessStarted WITH command:text
EVENT ProcessCompleted WITH result:object
EVENT ProcessFailed WITH error:text
EVENT ModeChanged WITH from:text,to:text
```

Emit:

```abnf
EMIT ProcessStarted WITH command="/review"
```

## 6 Handler System

Handlers react to events.

```abnf
ON ProcessFailed DO
  SET generation-status = INCOMPLETE
  SET ACCEPTANCE = PENDING
END
```

Handlers are primarily used for **runtime recovery**.

## 7 Runtime Contract

Runtime defines execution behavior.

Execution pipeline:

```text
command received
↓
macro resolution
↓
command execution
↓
event emission
↓
dispatch handler
↓
canonical output generation
↓
projection
↓
UI rendering
```

## 7.1 Input Acceptance

User input must appear between

```text
/begin
...
/end
```

Outside this range the runtime must ignore input.

### 7.2 Runtime State Machine

States:

```text
ACCEPTANCE = PENDING | ACTIVE
EXEC_MODE = idle | processing
generation-status = DRAFT | INCOMPLETE | READY
```

Initial values:

```text
ACCEPTANCE=PENDING
EXEC_MODE=idle
generation-status=DRAFT
```

## 8 Event Dispatch

Event dispatch connects emitted events to handlers.

Algorithm:

```abnf
when EMIT event:

  if handler exists:
     execute handler
  else:
     ignore
```

Dispatch occurs **during command execution**.

## 9 Canonical Output Contract

Canonical output is the authoritative machine structure.

```abnf
meta_state =
  generated
  rejected
  error
```

### 9.1 ReviewResult

```abnf
ReviewResult
  findings[]
  proposals[]
```

### 9.2 Finding Schema

```abnf
Finding
  CATEGORY
  PRIORITY
  identifier
  location
  message
  rationale
```

### 9.3 Proposal Schema

```abnf
Proposal
  location
  before
  after
  reason
```

## 10 Enumerations

### Priority

```text
A
B
C
D
E
```

### Category

```text
technical
structure
style
philosophy
suggestion
```

Enum extension is prohibited.

## 11 Projection Contract

Projection converts canonical output into UI views.

```text
canonical → projection → UI
```

Example:

```text
PROJECTION review_table

IssueID = identifier
Priority = PRIORITY
Category = CATEGORY
Location = location
Message = message
Proposal = proposal
```

## 12 Agent / MCP Compatibility

Canonical output is designed for machine agents.

```text
Agent
  → canonical output
```

Human readable output is generated via projection.

```text
canonical → projection → UI
```

## 13 Security Constraints

Runtime must enforce:

- canonical schema integrity
- deterministic output ordering
- enum extension prohibition
- projection isolation

## 14 Future Extensions

Possible future extensions:

- projection DSL
- LCL runtime engine
- compact compilation
- agent protocol integration
-
