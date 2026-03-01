---
title: LLM Control Language Specification
type: specification
domain: llm-control-language

description: ><
  LCL (LLM Control Language) is a domain-specific language for controlling
  structured interactions between users and large language models. It defines
  a deterministic execution model composed of a DSL core, runtime contract,
  canonical output schema, and projection system. The specification enables
  reproducible prompt execution and compatibility with agent-based systems
  such as MCP.

version: 2.0
update: 2026-01-27

architecture: >
  Layered architecture separating language definition, runtime execution,
  and output representation. The system consists of four layers: DSL Core,
  Runtime Contract, Canonical Output Contract, and Projection Contract.
  Canonical output provides a machine-consumable schema, while projections
  transform the canonical structure into human-readable views. This design
  ensures deterministic behavior and agent compatibility.

status: draft
author: atsushifx
---

## 1 Overview

LCL (LLM Control Language) defines a structured interaction protocol between
a user and an LLM.

The language defines:

- DSL syntax
- runtime execution rules
- canonical output schema
- projection mechanism

The goal is to enable deterministic LLM execution and compatibility with
Agent / MCP environments.

## 2 Design Principles

The specification separates three concerns.

```text
DSL Core
Runtime Contract
Output Contract
```

Output contract itself separates:

```text
canonical output
projection
```

Canonical output is the **machine authoritative structure**.

Projection is a **human presentation transformation**.

---

## 3 DSL Core

### 3.1 Commands

Commands define execution triggers.

```text
/begin
/end
/review
/write
/chart
/appendix
```

Command behavior is defined in the Runtime section.

---

### 3.2 Variables

Variables configure prompt behavior.

Example:

```text
/set :theme = "..."
/set :target = "..."
/set :goal = "..."
/set :link = |
 - reference1
 - reference2
/set :remark = "..."
```

Variables are interpreted by runtime policies.

---

### 3.3 Execution Modes

Execution modes control generation behavior.

```text
AUTO
FORCE
OFF
```

Used primarily for proposal generation.

## 4 Runtime Contract

Runtime defines how commands are executed.

Execution flow:

```text
1 validate input
2 execute DSL command
3 generate canonical output
4 apply projection
5 render result
```

### 4.1 Input Acceptance Model

Input is processed between

```text
/begin
...
/end
```

The system must ignore input outside this range.

### 4.2 Fail Fast

Runtime may abort generation if:

- invalid DSL syntax
- invalid output structure
- prohibited output modification

Fail fast returns `meta_state = rejected`.

## 5 Canonical Output Contract

This section defines the **single authoritative output schema**.

All projections derive from this schema.

### 5.1 Meta State

```text
meta_state =
  generated
  rejected
  error
```

### 5.2 Review Result

```text
ReviewResult
  findings[]
  proposals[]
```

### 5.3 Finding Schema

Field order MUST be preserved.

```text
Finding
  CATEGORY
  PRIORITY
  identifier
  location
  message
  rationale
```

### 5.4 Proposal Schema

```text
Proposal
  location
  before
  after
  reason
```

### 5.5 Enumerations

#### Priority

```text
A
B
C
D
E
```

A = critical
E = optional suggestion

Enum extension is prohibited.

#### Category

Example categories:

```text
technical
structure
style
philosophy
suggestion
```

## 6 Projection Contract

Projection transforms canonical output into presentation formats.
Projection MUST NOT modify canonical semantics.
Projection is defined as:

```text
canonical → view
```

Projection definitions are optional.
Prompts may define custom projections.

### 6.1 Review Table Projection

Example projection.

```text
PROJECTION review_table

IssueID = auto_increment
Importance = PRIORITY
Category = CATEGORY
Location = location
Message = message
Proposal = proposal
```

## 6.2 Proofreading Diff Projection

```text
PROJECTION proofreading_diff

Before = original
After = revised
Reason = explanation
```

## 7 Prompt Integration

Prompts may select projection using variables.

Example:

```text
/set :output_view = review_table
```

If projection is not defined, canonical output is returned.

## 8 Agent / MCP Compatibility

Canonical output is designed for machine consumption.

```text
Agent
  → canonical output
```

Human readable format is generated through projection.

```text
canonical → projection → UI
```

## 9 Compact Compilation

The specification may be compiled into a compact runtime block.

Compilation removes:

- explanatory text
- extended examples
- heuristics

Retained sections:

```text
DSL syntax
runtime contract
canonical output schema
enumerations
projection rules
```

---

## 10 Security Constraints

The runtime MUST enforce:

- enum extension prohibition
- canonical schema integrity
- deterministic field ordering

## 11 Future Extensions

Planned extensions:

- automated compact compiler
- projection DSL
- agent runtime protocol
- LCL execution engine

## End of Specification
