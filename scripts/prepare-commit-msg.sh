#!/usr/bin/env bash
# src: ./scripts/prepare-code-msg.sh
# @(#) : prepare commit message using codegpt if no message exists
#
# Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

set -euCo pipefail

## Constants
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

## Default message file
MSG_FILE=".git/COMMIT_EDITMSG"

## Allow custom message file as first argument
if [[ $# -ge 1 && -n "$1" ]]; then
  MSG_FILE="$1"
fi

## Check if the message was prefilled by Git (e.g. rebase/merge/cherry-pick)
if grep -vE '^\s*(#|$)' "$MSG_FILE" | grep -q '.'; then
  echo "✦ Detected existing Git-generated commit message. Skipping codegpt."
  exit 0
fi

## Generate commit message via codegpt
cd "$REPO_ROOT"
dotenvx run -- \
  codegpt \
  commit \
  --no_confirm --preview \
  --file "$MSG_FILE"
