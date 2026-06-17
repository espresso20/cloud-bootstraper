#!/usr/bin/env bash
# =============================================================================
#  cloud-preflight.sh — make sure a cloud CLI is installed and authenticated
#  before Terraform runs. Called by the Makefiles in our cloud stacks
#  (aws-stack-*, azure-tf-project-*) via a BOOTSTRAPER path.
#
#    cloud-preflight.sh aws   [profile]            # AWS SSO profile to verify/login
#    cloud-preflight.sh azure [subscription_id]    # subscription to select after login
#
#  Steps:
#    1. Detect the cloud CLI. If missing, offer to install it (delegates to
#       install/<cli>.sh — Homebrew on macOS).
#    2. Detect a live session. If absent/expired, log in (az login / aws sso login).
#
#  No arrays / bashisms beyond bash 3.2 — macOS ships an old bash.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUD="${1:-}"
IDENT="${2:-}"   # aws: profile ; azure: subscription_id  (both optional)

c_red=$'\033[31m'; c_grn=$'\033[32m'; c_cyn=$'\033[36m'; c_bld=$'\033[1m'; c_rst=$'\033[0m'
ok()   { printf "${c_grn}✓${c_rst} %s\n" "$*"; }
info() { printf "${c_cyn}»${c_rst} %s\n" "$*"; }
err()  { printf "${c_red}${c_bld}✗${c_rst} %s\n" "$*" >&2; }

case "$CLOUD" in
  aws)   CLI=aws; INSTALLER="${SCRIPT_DIR}/install/aws.sh" ;;
  azure) CLI=az;  INSTALLER="${SCRIPT_DIR}/install/az.sh"  ;;
  *) err "usage: $0 <aws|azure> [profile|subscription_id]"; exit 1 ;;
esac

# ── 1. CLI installed? ─────────────────────────────────────────────────────────
if ! command -v "$CLI" >/dev/null 2>&1; then
  err "${CLI} CLI not found."
  if [ -t 0 ]; then
    printf "  Install it now via %s? [y/N] " "$(basename "$INSTALLER")"
    read -r ans
  else
    ans=n   # non-interactive: don't silently install
  fi
  case "$ans" in
    [yY] | [yY][eE][sS])
      info "Installing ${CLI}..."
      "$INSTALLER"
      ;;
    *)
      err "Cannot continue without the ${CLI} CLI. Installer: ${INSTALLER}"
      exit 1
      ;;
  esac
  command -v "$CLI" >/dev/null 2>&1 || { err "${CLI} still not on PATH after install — open a new shell?"; exit 1; }
fi
ok "${CLI} CLI present ($("$CLI" --version 2>/dev/null | head -1))"

# ── 2. Authenticated session? ─────────────────────────────────────────────────
case "$CLOUD" in
  azure)
    # get-access-token actually exercises/refreshes the token — a truer liveness
    # check than `az account show`, which happily reads a stale cache.
    if az account get-access-token >/dev/null 2>&1; then
      ok "Azure session active."
    else
      info "No active Azure session — launching 'az login'..."
      az login >/dev/null
      ok "Logged in to Azure."
    fi
    if [ -n "$IDENT" ] && [ "$IDENT" != "00000000-0000-0000-0000-000000000000" ]; then
      info "Selecting subscription: ${IDENT}"
      az account set --subscription "$IDENT"
    fi
    ;;
  aws)
    if [ -n "$IDENT" ]; then
      if aws sts get-caller-identity --profile "$IDENT" >/dev/null 2>&1; then
        ok "AWS session active (profile: ${IDENT})."
      else
        info "No active AWS session — launching 'aws sso login --profile ${IDENT}'..."
        aws sso login --profile "$IDENT"
        if aws sts get-caller-identity --profile "$IDENT" >/dev/null 2>&1; then
          ok "Logged in to AWS (profile: ${IDENT})."
        else
          err "Still not authenticated after login."
          exit 1
        fi
      fi
    else
      if aws sts get-caller-identity >/dev/null 2>&1; then
        ok "AWS session active (default credentials)."
      else
        err "No active AWS session and no profile given to log in with."
        err "Set aws_profile in your tfvars, or run: aws sso login --profile <profile>"
        exit 1
      fi
    fi
    ;;
esac
