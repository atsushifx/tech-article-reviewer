---
title: tech-article-reviewer
description: article review/proofreading framework for tech blog.
---

English | [日本語](README.ja.md)

## tech-article-reviewer

A review and proofreading framework for Japanese technical blogs.

Provides a structured prompt system for use with ChatGPT.

## Quick Start

### Installation

1. Fork this repository on GitHub (create your own copy)

### Usage

#### 1. Clone the repository locally

```bash
git clone https://github.com/<YOUR_USERNAME>/tech-article-reviewer.git
cd tech-article-reviewer
```

By forking, you can manage your own custom prompt configurations.

#### 2. Configure prompt variables

Open the `.prompt` files in `tech-articles-prompt/` and edit the variable sections.

Example configuration (`article-review.prompt`):

```markdown
:theme Securing GitHub Actions using GHALint
:target Beginners to intermediate users of GitHub Actions
:goal Enable vulnerability scanning of GitHub Actions using GHALint
:link <GHALint official website>
:remark Include many specific examples
```

Configuration variables:

| Variable  | Description                              | Example                                       |
| --------- | ---------------------------------------- | --------------------------------------------- |
| `:theme`  | Blog theme                               | Securing GitHub Actions using GHALint         |
| `:target` | Target audience                          | Beginners, intermediates, advanced users      |
| `:goal`   | Goal for readers to achieve with article | Improve article quality, prioritize clarity   |
| `:link`   | Reference links                          | Style guide URL, writing guidelines           |
| `:remark` | Special notes                            | Include many examples, code examples required |

Note:
Do not modify variables other than these.

#### 3. Paste the prompt into ChatGPT

1. Open the desired prompt file from `tech-articles-prompt/`
2. Copy the entire file
3. Paste into ChatGPT conversation
4. Follow the prompt instructions to input and review your article

## Available Prompts

| File                          | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| `article-review.prompt`       | Article review and improvement suggestions |
| `article-proofreading.prompt` | Proofreading and consistency check         |
| `article-writer.prompt`       | Article writing assistance                 |

## Basic Prompt Operations

Each prompt operates in 3 modes:

### Command Mode (Initial State)

| Command  | Description                                 |
| -------- | ------------------------------------------- |
| `/begin` | Start input mode (prepare to paste article) |

### Input Mode

- Paste article content
- Use `/end` to complete input and transition to review/writer mode

### Review Mode

| Command             | Description                           |
| ------------------- | ------------------------------------- |
| `/review`           | Display full review results           |
| `/review [section]` | Display specific section only         |
| `/write [section]`  | Write body text for specified section |
| `/exit`             | Exit mode, return to beginning        |

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx

## Developer Information

For prompt improvements or framework contributions, refer to **[CLAUDE.md](./CLAUDE.md)**.

- Technical stack
- Repository structure
- Development workflow
- Coding conventions
- CI/CD configuration
