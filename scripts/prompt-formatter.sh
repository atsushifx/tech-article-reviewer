#!/usr/bin/env bash
# src: ./scripts/prompt-formatter.sh
# @(#) : Format prompt files using rumdl formatter
#
# Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file prompt-formatter.sh
# @brief Format .prompt files using rumdl
# @description
#   Formats .prompt files using rumdl.
#   Usage: ./prompt-formatter.sh [file1.prompt file2.prompt ...]
#   No arguments: formats all files in tech-articles-prompt/
#
# @exitcode 0 Success
# @exitcode 1 Formatting errors
# @exitcode 2 Missing dependencies or invalid files
#
# @author atsushifx
# @version 2.0.0
# @license MIT

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
PROMPT_DIR="${REPO_ROOT}/tech-articles-prompt"
RUMDL_CONFIG="${REPO_ROOT}/configs/.rumdl.toml"

# Check dependencies
if ! command -v rumdl &> /dev/null; then
  echo "Error: rumdl command not found" >&2
  exit 2
fi

# Get file list
if [[ $# -eq 0 ]]; then
  # No arguments: find all .prompt files
  files=$(find "$PROMPT_DIR" -type f -name "*.prompt" | sort)
  if [[ -z "$files" ]]; then
    echo "Error: No .prompt files found in $PROMPT_DIR" >&2
    exit 2
  fi
else
  # Arguments provided: validate each file
  files=""
  for arg in "$@"; do
    if [[ ! -f "$arg" ]]; then
      echo "Error: File not found: $arg" >&2
      exit 2
    fi
    if [[ ! "$arg" =~ \.prompt$ ]]; then
      echo "Error: File must have .prompt extension: $arg" >&2
      exit 2
    fi
    files+="$arg"$'\n'
  done
fi

# Format files
total=0
success=0
failed=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  total=$((total + 1))

  filename="$(basename "$file")"
  if rumdl fmt --config "$RUMDL_CONFIG" "$file" &> /dev/null; then
    echo "✓ $filename"
    success=$((success + 1))
  else
    echo "✗ $filename" >&2
    failed=$((failed + 1))
  fi
done <<< "$files"

# Summary
echo ""
echo "Total: $total, Success: $success, Failed: $failed"

[[ $failed -eq 0 ]] && exit 0 || exit 1
