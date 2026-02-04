FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# System dependencies
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    make \
    # Networking & utilities
    curl \
    wget \
    unzip \
    jq \
    httpie \
    # Python (for LocalStack CLI)
    python3-pip \
    # Git
    git \
    git-lfs \
    # PostgreSQL client tools (psql, pg_dump, pg_restore)
    postgresql-client \
    # Playwright / headless browser dependencies
    libnss3 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Go tooling (linters, debugger, test runner)
# ============================================================
# Note: Go itself is installed via the devcontainer feature.
# These tools are installed once the Go feature sets up GOPATH.
# We handle this in post-create.sh instead to ensure Go is available.

# ============================================================
# Global Node.js packages
# Note: Node itself is installed via the devcontainer feature.
# Claude Code and TypeScript installed in post-create.sh.
# ============================================================

# ============================================================
# Shell config
# ============================================================
COPY .bashrc.append /tmp/.bashrc.append
RUN cat /tmp/.bashrc.append >> /home/vscode/.bashrc \
    && chown vscode:vscode /home/vscode/.bashrc \
    || true

# ============================================================
# LocalStack CLI + awslocal wrapper
# We install localstack-core (the CLI) directly, skipping the
# broken localstack meta-package which has a dependency on
# localstack-ext with broken metadata.
# ============================================================
RUN pip3 install --no-cache-dir localstack-core awscli-local[ver2] \
    && localstack --version \
    && echo "✅ LocalStack CLI installed"

USER vscode
