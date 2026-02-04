#!/bin/bash
set -e

echo "============================================"
echo "🔧 Engine Dev Environment — Initial Setup"
echo "============================================"

# --------------------------------------------------
# 1. Install Go tooling (linters, debugger, etc.)
# --------------------------------------------------
echo "🔨 Installing Go tools..."
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest 2>/dev/null || true
go install golang.org/x/tools/gopls@latest 2>/dev/null || true
go install github.com/go-delve/delve/cmd/dlv@latest 2>/dev/null || true
go install gotest.tools/gotestsum@latest 2>/dev/null || true
echo "✅ Go tools installed"

# --------------------------------------------------
# 2. Install global Node.js packages
# --------------------------------------------------
echo "📦 Installing global npm packages..."
npm install -g @anthropic-ai/claude-code typescript 2>/dev/null || true
npm cache clean --force 2>/dev/null || true
echo "✅ Global npm packages installed"

# --------------------------------------------------
# 3. Install frontend dependencies
# --------------------------------------------------
if [ -f "frontend/package.json" ]; then
    echo "📦 Installing frontend dependencies..."
    cd frontend
    npm ci
    cd ..
    echo "✅ Frontend dependencies installed"
else
    echo "⏭️  No frontend/package.json found, skipping"
fi

# --------------------------------------------------
# 4. Install backend dependencies
# --------------------------------------------------
if [ -f "backend/go.mod" ]; then
    echo "📦 Downloading Go modules..."
    cd backend
    go mod download
    cd ..
    echo "✅ Go modules downloaded"
else
    echo "⏭️  No backend/go.mod found, skipping"
fi

# --------------------------------------------------
# 5. Install Playwright browsers (for E2E tests)
# --------------------------------------------------
if [ -f "frontend/package.json" ] && grep -q "playwright" frontend/package.json 2>/dev/null; then
    echo "🎭 Installing Playwright browsers..."
    cd frontend
    npx playwright install chromium
    npx playwright install-deps chromium
    cd ..
    echo "✅ Playwright ready"
else
    echo "🎭 Installing Playwright (standalone)..."
    npx playwright install chromium 2>/dev/null || true
    npx playwright install-deps chromium 2>/dev/null || true
fi

# --------------------------------------------------
# 6. Configure Git for GitHub
# --------------------------------------------------
echo "🔗 Configuring Git..."
git config --global pull.rebase false
git config --global init.defaultBranch main

# GitHub CLI auth — Codespaces auto-authenticates gh,
# but outside Codespaces you'll need: gh auth login
if command -v gh &>/dev/null; then
    echo "✅ GitHub CLI available"
    gh auth status 2>/dev/null || echo "ℹ️  Run 'gh auth login' to authenticate GitHub CLI"
fi

# --------------------------------------------------
# 7. Create .env from template if it doesn't exist
# --------------------------------------------------
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo "📝 Creating .env from .env.example..."
    cp .env.example .env
    echo "✅ .env created — review and update values"
fi

# --------------------------------------------------
# 8. Verify tooling
# --------------------------------------------------
echo ""
echo "============================================"
echo "🔍 Verifying installed tools"
echo "============================================"
echo -n "  Go:             " && go version 2>/dev/null || echo "NOT FOUND"
echo -n "  Node:           " && node --version 2>/dev/null || echo "NOT FOUND"
echo -n "  npm:            " && npm --version 2>/dev/null || echo "NOT FOUND"
echo -n "  Docker:         " && docker --version 2>/dev/null || echo "NOT FOUND"
echo -n "  Compose:        " && docker compose version 2>/dev/null || echo "NOT FOUND"
echo -n "  AWS CLI:        " && aws --version 2>/dev/null || echo "NOT FOUND"
echo -n "  LocalStack CLI: " && localstack --version 2>/dev/null || echo "NOT FOUND"
echo -n "  awslocal:       " && which awslocal 2>/dev/null || echo "NOT FOUND"
echo -n "  psql:           " && psql --version 2>/dev/null || echo "NOT FOUND"
echo -n "  golangci-lint:  " && golangci-lint --version 2>/dev/null || echo "NOT FOUND"
echo -n "  Claude Code:    " && claude --version 2>/dev/null || echo "NOT FOUND"
echo -n "  GitHub CLI:     " && gh --version 2>/dev/null || echo "NOT FOUND"
echo -n "  Git:            " && git --version 2>/dev/null || echo "NOT FOUND"
echo ""

echo "============================================"
echo "✅ Post-create setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Configure AWS credentials:    aws configure"
echo "  2. Start services:               docker compose up -d"
echo "  3. Start LocalStack:             localstack start -d"
echo "  4. Start developing:             claude"
echo ""
echo "Useful commands:"
echo "  awslocal s3 ls                   (LocalStack S3)"
echo "  pglocal                          (connect to local Postgres)"
echo "  gh issue list                    (GitHub Issues)"
echo "  gh pr create                     (create Pull Request)"
echo ""
