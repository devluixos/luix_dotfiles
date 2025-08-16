#!/usr/bin/env bash
set -euo pipefail

# Usage: push-configs.sh "commit message"
# If no message is given, a timestamped default is used.

COMMIT_MSG="${1:-update: $(date -Iseconds)}"

info()  { printf "\033[1;34m[INFO]\033[0m %s\n"  "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n"  "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n"  "$*" >&2; }

ensure_repo() {
  local dir="$1"
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  else
    error "Not a git repo: $dir"
    return 1
  fi
}

push_normal() {
  local dir="$1"
  info "Committing & pushing $dir (as current user)…"
  git -C "$dir" add -A
  # Only commit if there are changes
  if ! git -C "$dir" diff --cached --quiet; then
    git -C "$dir" commit -m "$COMMIT_MSG"
  else
    info "No staged changes in $dir; skipping commit."
  fi
  # Push current branch to origin
  current_branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD)"
  git -C "$dir" push -u origin "$current_branch"
}

push_with_sudo() {
  local dir="$1"
  info "Committing & pushing $dir via sudo (preserving SSH agent)…"
  # Ensure SSH agent socket is passed through sudo; if sudoers doesn't keep it, this may fail.
  if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    warn "SSH_AUTH_SOCK not set; your SSH key may not be available under sudo."
  fi

  sudo env "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-}" git -C "$dir" add -A
  if ! sudo env "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-}" git -C "$dir" diff --cached --quiet; then
    sudo env "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-}" git -C "$dir" commit -m "$COMMIT_MSG"
  else
    info "No staged changes in $dir; skipping commit."
  fi
  current_branch="$(sudo env "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-}" git -C "$dir" rev-parse --abbrev-ref HEAD)"
  sudo env "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-}" git -C "$dir" push -u origin "$current_branch"
}

push_repo() {
  local dir="$1"
  ensure_repo "$dir" || return 0

  # Fail early if no 'origin' remote set
  if ! git -C "$dir" remote get-url origin >/dev/null 2>&1; then
    warn "No 'origin' remote in $dir. Set it, e.g.:"
    warn "  git -C $dir remote add origin git@github.com:<you>/<repo>.git"
    return 0
  fi

  # If .git or its config is writable by current user, do it normally; else try sudo with SSH agent.
  if [[ -w "$dir/.git" || -w "$dir/.git/config" ]]; then
    push_normal "$dir"
  else
    push_with_sudo "$dir"
  fi
}

main() {
  # 1) dotfiles in $HOME
  DOTS="$HOME/dotfiles"
  if [[ -d "$DOTS" ]]; then
    push_repo "$DOTS"
  else
    warn "Missing: $DOTS"
  fi

  # 2) /etc/nixos
  NIXDIR="/etc/nixos"
  if [[ -d "$NIXDIR" ]]; then
    push_repo "$NIXDIR"
  else
    warn "Missing: $NIXDIR"
  fi

  info "Done."
}

main "$@"

