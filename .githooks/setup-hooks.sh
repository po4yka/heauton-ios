#!/bin/bash
#
# Setup Git Hooks
# This script installs the git hooks from .githooks directory
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"

echo "Setting up git hooks..."

# Copy pre-commit hook
if [ -f "$SCRIPT_DIR/pre-commit" ]; then
    cp "$SCRIPT_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo "✓ Pre-commit hook installed"
else
    echo "✗ Pre-commit hook not found"
fi

echo ""
echo "Git hooks setup complete!"
echo ""
echo "To bypass hooks during commit, use: git commit --no-verify"
