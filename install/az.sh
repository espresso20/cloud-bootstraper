#!/usr/bin/env bash
# install/az.sh — install the Azure CLI. macOS uses Homebrew; elsewhere we point
# at the official docs rather than guess a package manager.
set -euo pipefail

if command -v az >/dev/null 2>&1; then
  echo "az already installed: $(az --version 2>/dev/null | head -1)"
  exit 0
fi

OS="$(uname -s)"
case "$OS" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      echo "» brew install azure-cli"
      brew install azure-cli
    else
      echo "✗ Homebrew not found. Install brew (https://brew.sh), or install the" >&2
      echo "  Azure CLI manually: https://learn.microsoft.com/cli/azure/install-azure-cli-macos" >&2
      exit 1
    fi
    ;;
  Linux)
    if command -v brew >/dev/null 2>&1; then
      brew install azure-cli
    else
      echo "✗ No brew on PATH. Use your distro's instructions:" >&2
      echo "  https://learn.microsoft.com/cli/azure/install-azure-cli-linux" >&2
      exit 1
    fi
    ;;
  *)
    echo "✗ Unsupported OS '${OS}'. See https://learn.microsoft.com/cli/azure/install-azure-cli" >&2
    exit 1
    ;;
esac

command -v az >/dev/null 2>&1 && echo "✓ az installed: $(az --version 2>/dev/null | head -1)"
