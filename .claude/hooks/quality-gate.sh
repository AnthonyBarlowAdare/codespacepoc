#!/usr/bin/env bash
# .claude/hooks/quality-gate.sh
# Stop hook: run linters on files changed in the current git working tree.
# If lint errors are found, output JSON to block Claude from stopping,
# feeding the errors back so Claude can fix them.
#
# Stop hooks use top-level JSON: { "decision": "block", "reason": "..." }
# Exit 0 always — we use JSON decision control, not exit codes.

set -uo pipefail

# Collect changed Go and frontend files from git
GO_FILES=$(git diff --name-only --diff-filter=d HEAD 2>/dev/null | grep '\.go$' || true)
TS_FILES=$(git diff --name-only --diff-filter=d HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' || true)

# Also include untracked new files
GO_FILES_UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep '\.go$' || true)
TS_FILES_UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' || true)

GO_FILES=$(echo -e "${GO_FILES}\n${GO_FILES_UNTRACKED}" | sort -u | grep -v '^$' || true)
TS_FILES=$(echo -e "${TS_FILES}\n${TS_FILES_UNTRACKED}" | sort -u | grep -v '^$' || true)

ERRORS=""

# --- Go linting ---
if [[ -n "$GO_FILES" ]]; then
  # go vet (fast, always available)
  if command -v go &>/dev/null; then
    GO_PACKAGES=$(echo "$GO_FILES" | xargs -I{} dirname {} | sort -u | sed 's|^|./|')
    VET_OUTPUT=$(go vet $GO_PACKAGES 2>&1 || true)
    if [[ -n "$VET_OUTPUT" ]]; then
      ERRORS="${ERRORS}go vet errors:\n${VET_OUTPUT}\n\n"
    fi
  fi

  # golangci-lint (more thorough, may not be installed)
  if command -v golangci-lint &>/dev/null; then
    LINT_OUTPUT=$(echo "$GO_FILES" | tr '\n' ' ' | xargs golangci-lint run --new-from-rev=HEAD --timeout=60s 2>&1 || true)
    if [[ -n "$LINT_OUTPUT" ]] && ! echo "$LINT_OUTPUT" | grep -q "no go files"; then
      ERRORS="${ERRORS}golangci-lint errors:\n${LINT_OUTPUT}\n\n"
    fi
  fi
fi

# --- Frontend linting ---
if [[ -n "$TS_FILES" ]]; then
  # ESLint
  if command -v npx &>/dev/null && [[ -f ".eslintrc.json" || -f ".eslintrc.js" || -f ".eslintrc.yml" || -f "eslint.config.js" || -f "eslint.config.mjs" ]]; then
    ESLINT_OUTPUT=$(echo "$TS_FILES" | xargs npx eslint --no-error-on-unmatched-pattern 2>&1 || true)
    if echo "$ESLINT_OUTPUT" | grep -qE '(error|warning)'; then
      ERRORS="${ERRORS}ESLint errors:\n${ESLINT_OUTPUT}\n\n"
    fi
  fi
fi

# --- Decision ---
if [[ -n "$ERRORS" ]]; then
  # Truncate to avoid overwhelming Claude (keep first 2000 chars)
  TRUNCATED=$(echo -e "$ERRORS" | head -c 2000)

  # Use jq to safely escape the error text into JSON
  jq -n --arg reason "Quality gate failed. Fix these issues before finishing:\n\n${TRUNCATED}" \
    '{ "decision": "block", "reason": $reason }'
  exit 0
fi

# All clean — let Claude stop
exit 0
