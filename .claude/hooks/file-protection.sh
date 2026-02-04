#!/usr/bin/env bash
# .claude/hooks/file-protection.sh
# PreToolUse hook: block modifications to sensitive files and directories.
# Exit 2 = block the action (stderr is shown to Claude as feedback).
# Exit 0 = allow.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# --- Blocked patterns ---

# .env files (secrets should never be edited by Claude)
if [[ "$FILE_PATH" =~ \.env($|\.) ]]; then
  echo "BLOCKED: .env files contain secrets and must be edited manually. Use .env.example to document required variables." >&2
  exit 2
fi

# .git internals
if [[ "$FILE_PATH" == *".git/"* ]]; then
  echo "BLOCKED: Direct modification of .git/ internals is not allowed." >&2
  exit 2
fi

# Production configs
if [[ "$FILE_PATH" =~ (docker-compose\.prod|\.production\.) ]]; then
  echo "BLOCKED: Production configuration files must be modified through a reviewed PR, not by Claude Code." >&2
  exit 2
fi

# Applied database migrations (only block if the migration directory exists and file is not new)
if [[ "$FILE_PATH" =~ migrations/[0-9] && -f "$FILE_PATH" ]]; then
  echo "BLOCKED: This migration has already been applied. Create a new migration instead of modifying an existing one." >&2
  exit 2
fi

# Lock files
if [[ "$FILE_PATH" =~ (package-lock\.json|go\.sum|yarn\.lock|pnpm-lock\.yaml)$ ]]; then
  echo "BLOCKED: Lock files are auto-generated. Run the appropriate install command instead of editing directly." >&2
  exit 2
fi

exit 0
