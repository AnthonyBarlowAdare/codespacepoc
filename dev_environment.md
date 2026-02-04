# Development Environment

This document explains how our dev environment works, how credentials are managed, and how to get set up.

## How It Works

The `.devcontainer/` folder in the repo defines a complete, reproducible environment using the [Dev Containers](https://containers.dev/) spec. When you open the repo in GitHub Codespaces (or VS Code Dev Containers locally), it builds a container with everything pre-installed — Go, Node, Docker, AWS CLI, LocalStack, PostgreSQL client, Playwright, Claude Code, and all VS Code extensions.

New developers go from zero to coding in about 2 minutes with no local setup required.

### File Breakdown

| File | Purpose |
|------|---------|
| `devcontainer.json` | Main config — tools, extensions, ports, environment variables |
| `Dockerfile` | System-level dependencies (Playwright browsers, psql, build tools) |
| `post-create.sh` | Runs once on first build — installs Go/Node tooling, verifies everything works |
| `post-start.sh` | Runs on every start/restart — brings up Postgres and LocalStack containers |
| `.bashrc.append` | Shell aliases and welcome message |

### What Happens on Launch

1. GitHub builds the container image from `Dockerfile` + `devcontainer.json` features
2. `post-create.sh` installs additional tooling (golangci-lint, Playwright browsers, etc.)
3. `post-start.sh` starts the `db` and `localstack` Docker Compose services
4. VS Code opens with all extensions ready, ports forwarded, aliases loaded

## Credential Management

We use **GitHub Codespaces Secrets** for AWS credentials. Secrets are encrypted at rest, injected as environment variables on Codespace start, and never committed to the repo.

### The LocalStack vs Real AWS Problem

The devcontainer sets default environment variables pointing to LocalStack:

```
AWS_ENDPOINT_URL=http://localhost:4566
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
```

This means LocalStack works out of the box with zero config. But it also means these dummy values override any real AWS credentials you set via Codespaces Secrets.

**The solution:** When you need to hit real AWS, unset the LocalStack overrides:

```bash
# Temporarily use real AWS (picks up your Codespaces Secrets)
unset AWS_ENDPOINT_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
aws sts get-caller-identity   # should show your real IAM user

# Or use a profile (see "Setting Up Your Credentials" below)
aws --profile real s3 ls
```

For day-to-day development, you'll almost always be using LocalStack, so the defaults are correct 99% of the time.

### Setting Up Your Credentials

Each developer manages their own AWS credentials. There are two places to add them:

**Option A: User-level secrets (recommended for individual devs)**

1. Go to [github.com/settings/codespaces](https://github.com/settings/codespaces)
2. Under **Secrets**, click **New secret**
3. Add these secrets, scoping each to the engine repo:

| Secret Name | Value |
|-------------|-------|
| `AWS_REAL_ACCESS_KEY_ID` | Your IAM access key |
| `AWS_REAL_SECRET_ACCESS_KEY` | Your IAM secret key |
| `AWS_REAL_REGION` | `eu-west-1` |

We use the `AWS_REAL_` prefix to avoid clashing with the LocalStack defaults.

**Option B: Repo-level secrets (for shared dev/staging credentials)**

Repo admins can set these in the repo's **Settings → Secrets and Variables → Codespaces**. These are shared across all developers with access to the repo.

### Using Real AWS Credentials

Add an AWS CLI profile that references your Codespaces Secrets. Create or add to `~/.aws/config`:

```ini
[profile real]
region = eu-west-1
output = json
```

And `~/.aws/credentials`:

```ini
[profile real]
aws_access_key_id = ${AWS_REAL_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_REAL_SECRET_ACCESS_KEY}
```

Or, add this to your shell to create the profile automatically on Codespace start. You can put it in a personal [dotfiles repo](https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account#dotfiles) so it persists across rebuilds:

```bash
# ~/.bashrc or dotfiles install script
if [ -n "$AWS_REAL_ACCESS_KEY_ID" ]; then
  aws configure set aws_access_key_id "$AWS_REAL_ACCESS_KEY_ID" --profile real
  aws configure set aws_secret_access_key "$AWS_REAL_SECRET_ACCESS_KEY" --profile real
  aws configure set region "${AWS_REAL_REGION:-eu-west-1}" --profile real
fi
```

Then use it:

```bash
aws --profile real s3 ls
aws --profile real sts get-caller-identity
```

### Quick Reference

| I want to... | Command |
|---------------|---------|
| Use LocalStack (default) | `awslocal s3 ls` or just `aws s3 ls` |
| Use real AWS with profile | `aws --profile real s3 ls` |
| Temporarily switch to real AWS | `unset AWS_ENDPOINT_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY` |
| Check who I'm authenticated as | `aws sts get-caller-identity` (LocalStack) or `aws --profile real sts get-caller-identity` |
| Reset back to LocalStack defaults | Restart terminal or `source ~/.bashrc` |

## Claude Code Hooks

The repo includes project-level Claude Code hooks in `.claude/settings.json`. These run deterministically — they fire every time, not "when Claude remembers to." All developers get the same hooks automatically.

### What's Configured

| Hook | Event | Trigger | What It Does |
|------|-------|---------|--------------|
| `auto-format.sh` | PostToolUse | Edit\|Write | Runs `gofmt` on `.go` files, `prettier` on frontend files after every edit |
| `file-protection.sh` | PreToolUse | Edit\|Write | Blocks writes to `.env`, `.git/`, production configs, applied migrations, lock files |
| `architecture-check.sh` | PreToolUse | Edit\|Write | Enforces hexagonal architecture — no HTTP handlers in `domain/`, no concrete repos outside `adapters/` |
| `quality-gate.sh` | Stop | (always) | Runs `go vet` + `golangci-lint` + `eslint` on changed files when Claude finishes. Blocks stopping if issues found |

### How It Works

Hooks live in `.claude/hooks/` and are wired up in `.claude/settings.json`. Claude Code reads this config at session start. When an event fires (e.g. Claude writes a file), the matching hook scripts run and receive JSON on stdin with details about the operation. Exit code 0 means proceed, exit code 2 means block the action and show the error to Claude.

The Stop hook is special — it outputs `{"decision": "block", "reason": "..."}` as JSON, which feeds lint errors back to Claude so it fixes them automatically before finishing.

### Customising

To add personal hooks without affecting the team, create `.claude/settings.local.json` (gitignored). Claude Code merges settings from all three files: `~/.claude/settings.json` (user), `.claude/settings.json` (project, committed), `.claude/settings.local.json` (project, local).

You can also use the interactive `/hooks` command inside Claude Code to add or modify hooks.

## MCP Servers

The repo includes a `.mcp.json` at the project root that configures shared MCP (Model Context Protocol) servers for the team. These give Claude Code direct access to external tools and services.

### What's Configured

| Server | What It Does |
|--------|-------------|
| `postgres` | Direct database access — Claude can query, inspect schemas, debug data issues |
| `github` | PR management, issue tracking, CI/CD status — all from within Claude Code |
| `context7` | Up-to-date, version-specific library documentation — replaces stale training data |
| `playwright` | Browser automation — Claude can run E2E tests and interact with the portal UI |

### Setup

MCP servers in `.mcp.json` use `${ENV_VAR}` references for secrets. Each developer needs to set these environment variables (via Codespaces Secrets or their local shell):

| Environment Variable | Where to Get It |
|---------------------|----------------|
| `DATABASE_URL` | Set automatically by `post-start.sh` for local Postgres |
| `GITHUB_TOKEN` | [github.com/settings/tokens](https://github.com/settings/tokens) — needs `repo` scope |

`context7` and `playwright` don't need any credentials.

For Codespaces, add these as secrets the same way as the AWS credentials (see "Setting Up Your Credentials" above). For local development, export them in your shell profile.

### Adding Personal MCP Servers

To add servers just for yourself without affecting the team config:

```bash
# Local scope (default) — only for you in this project
claude mcp add --transport http my-server https://example.com/mcp

# User scope — for you across all projects
claude mcp add --transport http my-server --scope user https://example.com/mcp
```

Local-scoped servers are stored in `~/.claude.json` and take precedence over project-scoped servers with the same name.

## Security Rules

- **Never commit credentials** to the repo — not in code, `.env` files, or config
- **Never share access keys** between developers — each person gets their own IAM user
- **Use least-privilege IAM policies** — dev accounts shouldn't have admin access
- **Rotate keys** periodically — GitHub Codespaces Secrets make this painless (update the secret value, restart Codespace)
- **LocalStack for development** — only use real AWS when you specifically need to test against live services

## Useful Links

- [GitHub Codespaces Secrets docs](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces)
- [Dev Container spec](https://containers.dev/)
- [LocalStack docs](https://docs.localstack.cloud/)
- [AWS CLI named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
- [Claude Code hooks guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code hooks reference](https://code.claude.com/docs/en/hooks)
- [Claude Code MCP servers](https://code.claude.com/docs/en/mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
