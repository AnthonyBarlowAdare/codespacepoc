#!/usr/bin/env bash
# .claude/hooks/architecture-check.sh
# PreToolUse hook: enforce hexagonal architecture / DDD package structure.
# Blocks file creation in wrong packages and provides guidance.
# Exit 2 = block with feedback. Exit 0 = allow.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only check Go files
if [[ "$FILE_PATH" != *.go ]]; then
  exit 0
fi

# Skip test files — tests can live anywhere
if [[ "$FILE_PATH" == *_test.go ]]; then
  exit 0
fi

# ----- Hexagonal Architecture Rules -----
#
# Expected package layout:
#
#   internal/
#     domain/           <- Entities, value objects, domain services, repository interfaces
#     application/      <- Use cases / application services (orchestrate domain)
#     ports/            <- Port interfaces (inbound + outbound)
#       inbound/        <- Driving ports (e.g. API handler interfaces)
#       outbound/       <- Driven ports (e.g. repository, messaging interfaces)
#     adapters/         <- Concrete implementations
#       inbound/        <- HTTP handlers, gRPC servers, CLI
#       outbound/       <- Postgres repos, S3 clients, SES adapters
#     infrastructure/   <- Config, DI wiring, middleware
#
# Rules:
#   1. Domain must not import from adapters, infrastructure, or application
#   2. HTTP/handler code belongs in adapters/inbound, not domain or application
#   3. Repository implementations belong in adapters/outbound, not domain
#   4. Port interfaces belong in ports/, not adapters/

# Rule: No handler/HTTP code in domain/
if [[ "$FILE_PATH" =~ /domain/ ]] && [[ "$FILE_PATH" =~ (handler|controller|router|http|server|middleware) ]]; then
  echo "BLOCKED: HTTP/handler code does not belong in the domain package. Place it in internal/adapters/inbound/ instead. The domain layer must have zero infrastructure dependencies." >&2
  exit 2
fi

# Rule: No concrete repository implementations in domain/
if [[ "$FILE_PATH" =~ /domain/ ]] && [[ "$FILE_PATH" =~ (postgres|mysql|sqlite|dynamo|redis|_repo\.go|_repository\.go) ]] && [[ ! "$FILE_PATH" =~ (interface|port|contract) ]]; then
  echo "BLOCKED: Repository implementations do not belong in the domain package. Place the interface in internal/ports/outbound/ and the implementation in internal/adapters/outbound/." >&2
  exit 2
fi

# Rule: No adapter code in ports/
if [[ "$FILE_PATH" =~ /ports/ ]] && [[ "$FILE_PATH" =~ (postgres|mysql|http_client|ses_|s3_|sqs_) ]]; then
  echo "BLOCKED: Concrete implementations do not belong in ports/. Ports define interfaces only. Place implementations in internal/adapters/outbound/." >&2
  exit 2
fi

# Rule: No domain logic in adapters/
if [[ "$FILE_PATH" =~ /adapters/ ]] && [[ "$FILE_PATH" =~ (entity|value_object|aggregate|domain_service|domain_event) ]]; then
  echo "BLOCKED: Domain entities/value objects/services do not belong in adapters/. Place them in internal/domain/." >&2
  exit 2
fi

# Rule: No direct infrastructure imports in domain (check file content if it exists)
if [[ "$FILE_PATH" =~ /domain/ ]] && [[ -f "$FILE_PATH" ]]; then
  if grep -qE 'import.*"(net/http|database/sql|github\.com/.*/gin|github\.com/.*/echo|github\.com/.*/fiber|github\.com/aws)' "$FILE_PATH" 2>/dev/null; then
    echo "BLOCKED: Domain package must not import infrastructure libraries (net/http, database/sql, AWS SDK, web frameworks). Define interfaces in ports/ and inject implementations from adapters/." >&2
    exit 2
  fi
fi

exit 0
