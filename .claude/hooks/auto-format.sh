#!/usr/bin/env bash
# .claude/hooks/auto-format.sh
# PostToolUse hook: auto-format files after Edit or Write operations.
# Runs gofmt for Go files, prettier for frontend files.
# Exit 0 always — formatting failures are non-blocking.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Nothing to do if no file path
if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

case "$FILE_PATH" in
  *.go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.css|*.scss|*.json)
    if command -v npx &>/dev/null; then
      npx --yes prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
