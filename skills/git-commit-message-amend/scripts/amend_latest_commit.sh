#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  amend_latest_commit.sh context
  amend_latest_commit.sh amend <message_file> [--allow-pushed] [--dry-run]

Commands:
  context   Show latest commit context for message drafting.
  amend     Amend latest commit message from <message_file>.

Flags:
  --allow-pushed  Allow amend even if HEAD is already reachable from upstream.
  --dry-run       Print what would run without modifying git history.
EOF
}

ensure_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: not inside a git repository." >&2
    exit 1
  }
}

is_head_reachable_from_upstream() {
  local upstream
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
  if [[ -z "${upstream}" ]]; then
    return 1
  fi
  git merge-base --is-ancestor HEAD "${upstream}"
}

cmd_context() {
  local head_hash
  local head_subject
  local branch
  local upstream

  head_hash="$(git rev-parse HEAD)"
  head_subject="$(git log -1 --pretty=%s)"
  branch="$(git rev-parse --abbrev-ref HEAD)"
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"

  echo "HEAD: ${head_hash}"
  echo "Branch: ${branch}"
  if [[ -n "${upstream}" ]]; then
    echo "Upstream: ${upstream}"
  else
    echo "Upstream: (none)"
  fi
  echo "Subject: ${head_subject}"
  echo
  if is_head_reachable_from_upstream; then
    echo "Pushed: yes (HEAD is reachable from upstream)"
  else
    echo "Pushed: no (HEAD is not confirmed reachable from upstream)"
  fi
  echo
  echo "Latest commit details:"
  git log -1 --pretty=fuller
  echo
  echo "Changed files in latest commit:"
  git show -1 --name-only --pretty=""
  echo
  echo "Stat:"
  git show -1 --stat --pretty=""
}

cmd_amend() {
  if [[ $# -lt 1 ]]; then
    echo "Error: missing <message_file>." >&2
    usage
    exit 1
  fi

  local message_file="$1"
  shift
  local allow_pushed="false"
  local dry_run="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --allow-pushed)
        allow_pushed="true"
        ;;
      --dry-run)
        dry_run="true"
        ;;
      *)
        echo "Error: unknown flag '$1'." >&2
        usage
        exit 1
        ;;
    esac
    shift
  done

  if [[ ! -f "${message_file}" ]]; then
    echo "Error: message file not found: ${message_file}" >&2
    exit 1
  fi

  if is_head_reachable_from_upstream && [[ "${allow_pushed}" != "true" ]]; then
    if [[ "${dry_run}" == "true" ]]; then
      echo "Warning: HEAD appears already pushed. Dry-run only; actual amend would require --allow-pushed."
      echo "Dry run: git commit --amend -F ${message_file}"
      exit 0
    fi
    echo "Error: HEAD appears already pushed. Use --allow-pushed to proceed explicitly." >&2
    exit 1
  fi

  if [[ "${dry_run}" == "true" ]]; then
    echo "Dry run: git commit --amend -F ${message_file}"
    exit 0
  fi

  git commit --amend -F "${message_file}"
  echo
  echo "Amend completed. Latest commit:"
  git log -1 --pretty=fuller
}

main() {
  ensure_git_repo
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local command="$1"
  shift

  case "${command}" in
    context)
      cmd_context "$@"
      ;;
    amend)
      cmd_amend "$@"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      echo "Error: unknown command '${command}'." >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
