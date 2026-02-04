# Dev Container Configuration

This folder configures a reproducible development environment using [GitHub Codespaces](https://github.com/features/codespaces) or any Dev Container-compatible tool (VS Code Remote Containers, etc.).

## Quick Start (New Developer)

1. Go to the repo on GitHub
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait ~2 minutes for the environment to build
4. You're ready to code

## What's Included

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.22 | Backend development |
| Node.js | 20 LTS | Frontend (React) + tooling |
| Docker + Compose | Latest v2 | Container orchestration |
| AWS CLI v2 | Latest | AWS service interaction |
| LocalStack CLI + awslocal | Latest | Local AWS emulation |
| PostgreSQL client (psql) | Latest | Database queries (Aurora Postgres locally) |
| golangci-lint | Latest | Go linting |
| Playwright + Chromium | Latest | E2E browser testing |
| Claude Code | Latest | AI-assisted development |
| GitHub CLI (gh) | Latest | Issues, PRs, repo management |
| Git + Git LFS | Latest | Version control |

### VS Code Extensions (auto-installed)

- **Go** — Language support, debugging, testing
- **ESLint + Prettier** — JS/TS formatting and linting
- **Docker** — Container management
- **AWS Toolkit** — AWS service explorer
- **GitLens** — Git blame, history, comparison
- **GitHub Pull Requests** — Review and manage PRs from VS Code
- **PostgreSQL** — Database explorer and queries
- **Playwright Test** — E2E test runner
- **Tailwind CSS IntelliSense** — CSS utility autocomplete
- **Error Lens** — Inline error highlighting
- **Todo Tree** — Track TODOs across the codebase

## First-Time Setup

After your Codespace starts, you'll need to configure credentials:

```bash
# 1. AWS credentials (for real AWS, not LocalStack)
aws configure
# Enter your Access Key ID, Secret, region (eu-west-1), and output format (json)

# 2. GitHub CLI — auto-authenticated in Codespaces
# Outside Codespaces, run:
gh auth login

# 3. Claude Code authentication
claude  # Follow the URL to authenticate
```

**LocalStack requires no credentials** — it's pre-configured with test credentials.

## Helpful Aliases

The environment includes shortcuts in your terminal:

### Docker Compose
| Alias | Command | Description |
|-------|---------|-------------|
| `dc` | `docker compose` | Short compose command |
| `dcu` | `docker compose up -d` | Start all services |
| `dcd` | `docker compose down` | Stop all services |
| `dcl` | `docker compose logs -f` | Follow logs |
| `dps` | `docker ps --format ...` | Clean container list |

### Go (run from `backend/`)
| Alias | Command | Description |
|-------|---------|-------------|
| `gt` | `go test ./... -v` | Run all tests |
| `gtc` | `go test ./... -v -cover` | Tests with coverage |
| `gtd` | `go test ./internal/domain/...` | Domain layer tests |
| `lint` | `golangci-lint run` | Run linter |

### Frontend (run from `frontend/`)
| Alias | Command | Description |
|-------|---------|-------------|
| `nrd` | `npm run dev` | Start dev server |
| `nrt` | `npm run test` | Run tests |
| `nrb` | `npm run build` | Production build |
| `nrl` | `npm run lint` | Run ESLint |

### Git / GitHub
| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status` | Status |
| `gl` | `git log --oneline -20` | Recent log |
| `gcb` | `git checkout -b` | New branch |
| `gpr` | `gh pr create` | Create pull request |
| `gprl` | `gh pr list` | List pull requests |
| `giss` | `gh issue list` | List GitHub Issues |

### LocalStack
| Alias | Command | Description |
|-------|---------|-------------|
| `lsstart` | `localstack start -d` | Start LocalStack |
| `lsstop` | `localstack stop` | Stop LocalStack |
| `lss` | `localstack status` | Check status |
| `awsl` | `awslocal` | AWS CLI against LocalStack |

### PostgreSQL
| Alias | Command | Description |
|-------|---------|-------------|
| `pglocal` | `psql -h localhost -p 5432 -U postgres` | Connect to local DB |

## Ports

These ports are auto-forwarded when services start:

| Port | Service | Auto-forward |
|------|---------|-------------|
| 3000 | React dev server | Notify |
| 8080 | Go backend API | Notify |
| 5432 | PostgreSQL | Silent |
| 4566 | LocalStack gateway | Silent |
| 9222 | Chrome debugging | Silent |
| 9229 | Node.js debugging | Silent |

## LocalStack Usage

LocalStack emulates AWS services locally (Cognito, SES, S3, Lambda, DynamoDB, etc.) so you don't need a real AWS account for development.

```bash
# Start LocalStack
localstack start -d

# Use awslocal instead of aws (automatically targets localhost:4566)
awslocal s3 ls
awslocal cognito-idp list-user-pools --max-results 10
awslocal ses list-identities

# Or use standard AWS CLI with the endpoint override (set automatically)
aws --endpoint-url=http://localhost:4566 s3 ls
```

The environment pre-sets `AWS_ENDPOINT_URL=http://localhost:4566` and test credentials so `awslocal` works immediately.

## Customization

### Personal settings

Your personal VS Code theme, keybindings, and other preferences are handled through VS Code's **Settings Sync** — these won't affect other developers.

### Adding a tool

If the team needs a new tool:

1. Add it to `.devcontainer/Dockerfile` or as a feature in `devcontainer.json`
2. Test by rebuilding: **Ctrl+Shift+P** → "Codespaces: Rebuild Container"
3. PR the change — everyone gets it on their next rebuild

## Using Locally (without Codespaces)

You can use this same config with VS Code + Docker on your local machine:

1. Install **Dev Containers** extension in VS Code
2. Open the repo folder
3. **Ctrl+Shift+P** → "Dev Containers: Reopen in Container"

This requires Docker Engine running locally (you already have this in WSL2).

## Prebuilds (Optional — Faster Startup)

To make new Codespaces start in seconds instead of minutes:

1. Go to repo **Settings** → **Codespaces** → **Set up prebuild**
2. Select the branch(es) you want prebuilt
3. GitHub will pre-build the container image on each push

Recommended once the team is regularly using Codespaces.

## Troubleshooting

### Docker not starting
```bash
docker info
# If not running, wait a few seconds — it starts automatically.
```

### PostgreSQL connection issues
```bash
# Check if Postgres container is running
docker ps | grep postgres

# Connect manually
psql -h localhost -p 5432 -U postgres
```

### LocalStack not responding
```bash
# Check status
localstack status

# Restart
localstack stop && localstack start -d

# Check logs
localstack logs
```

### Playwright tests failing
```bash
npx playwright install chromium
npx playwright install-deps chromium
```

### Codespace running slowly
- Check machine type: **Ctrl+Shift+P** → "Codespaces: Change Machine Type"
- 4-core is fine for most work; use 8-core for heavy Docker usage
