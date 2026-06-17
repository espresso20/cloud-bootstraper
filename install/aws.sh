#!/usr/bin/env bash
# install/aws.sh — install the AWS CLI v2. macOS uses Homebrew; elsewhere we
# point at the official installer rather than guess a package manager.
set -euo pipefail

if command -v aws >/dev/null 2>&1; then
  echo "aws already installed: $(aws --version 2>/dev/null | head -1)"
  exit 0
fi

OS="$(uname -s)"
case "$OS" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      echo "» brew install awscli"
      brew install awscli
    else
      echo "✗ Homebrew not found. Install brew (https://brew.sh), or use the macOS pkg:" >&2
      echo "  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" >&2
      exit 1
    fi
    ;;
  Linux)
    if command -v brew >/dev/null 2>&1; then
      brew install awscli
    else
      echo "✗ No brew on PATH. Use the official installer:" >&2
      echo "  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" >&2
      exit 1
    fi
    ;;
  *)
    echo "✗ Unsupported OS '${OS}'. See https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" >&2
    exit 1
    ;;
esac

command -v aws >/dev/null 2>&1 && echo "✓ aws installed: $(aws --version 2>/dev/null | head -1)"
