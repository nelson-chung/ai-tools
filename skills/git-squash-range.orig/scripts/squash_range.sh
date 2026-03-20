#!/usr/bin/env bash
set -euo pipefail

TMP_SQUASH_MESSAGE_FILE=""

cleanup_temp_message() {
  if [[ -n "${TMP_SQUASH_MESSAGE_FILE:-}" ]]; then
    rm -f "${TMP_SQUASH_MESSAGE_FILE}"
  fi
}

trap cleanup_temp_message EXIT

usage() {
  cat <<'EOF'
Usage:
  squash_range.sh context <target_commit> [--mode inclusive|exclusive]
  squash_range.sh squash <target_commit> [--mode inclusive|exclusive] [--message-source latest|oldest | --message-file <path>] [--allow-pushed] [--dry-run]

Commands:
  context   Show the HEAD-ending commit range that would be squashed.
  squash    Squash the selected range into one commit.

Flags:
  --mode            Squash mode. inclusive squashes <target_commit>..HEAD.
                    exclusive keeps <target_commit> and squashes only commits after it.
  --message-source  Reuse the latest or oldest commit message in the squashed range.
  --message-file    Use a custom commit message file.
  --allow-pushed    Allow squashing commits that appear reachable from upstream.
  --dry-run         Print what would happen without modifying git history.
EOF
}

ensure_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: not inside a git repository." >&2
    exit 1
  }
}

ensure_clean_worktree() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: worktree or index is dirty. Commit or stash changes before squashing." >&2
    exit 1
  fi
}

resolve_commit() {
  local commit_ref="$1"
  git rev-parse --verify "${commit_ref}^{commit}" 2>/dev/null || {
    echo "Error: commit not found: ${commit_ref}" >&2
    exit 1
  }
}

ensure_target_is_ancestor() {
  local target_commit="$1"
  git merge-base --is-ancestor "${target_commit}" HEAD || {
    echo "Error: target commit is not an ancestor of HEAD." >&2
    exit 1
  }
}

upstream_ref() {
  git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true
}

worktree_state() {
  if git diff --quiet && git diff --cached --quiet; then
    echo "clean"
  else
    echo "dirty"
  fi
}

reset_point_for_mode() {
  local target_commit="$1"
  local mode="$2"

  case "${mode}" in
    inclusive)
      git rev-parse --verify "${target_commit}^" 2>/dev/null || {
        echo "Error: inclusive mode cannot start at the root commit." >&2
        exit 1
      }
      ;;
    exclusive)
      printf '%s\n' "${target_commit}"
      ;;
    *)
      echo "Error: unsupported mode: ${mode}" >&2
      exit 1
      ;;
  esac
}

range_spec_for_mode() {
  local target_commit="$1"
  local mode="$2"

  case "${mode}" in
    inclusive)
      printf '%s..HEAD\n' "$(git rev-parse --verify "${target_commit}^" 2>/dev/null || {
        echo "Error: inclusive mode cannot start at the root commit." >&2
        exit 1
      })"
      ;;
    exclusive)
      printf '%s..HEAD\n' "${target_commit}"
      ;;
    *)
      echo "Error: unsupported mode: ${mode}" >&2
      exit 1
      ;;
  esac
}

range_commit_count() {
  local target_commit="$1"
  local mode="$2"
  git rev-list --count "$(range_spec_for_mode "${target_commit}" "${mode}")"
}

oldest_commit_in_range() {
  local target_commit="$1"
  local mode="$2"
  git rev-list --reverse "$(range_spec_for_mode "${target_commit}" "${mode}")" | head -n 1
}

range_touches_upstream() {
  local target_commit="$1"
  local mode="$2"
  local upstream
  local total_count
  local local_only_count

  upstream="$(upstream_ref)"
  if [[ -z "${upstream}" ]]; then
    return 1
  fi

  total_count="$(range_commit_count "${target_commit}" "${mode}")"
  local_only_count="$(git rev-list --count "$(range_spec_for_mode "${target_commit}" "${mode}")" --not "${upstream}")"

  [[ "${local_only_count}" != "${total_count}" ]]
}

ensure_meaningful_range() {
  local target_commit="$1"
  local mode="$2"
  local count

  count="$(range_commit_count "${target_commit}" "${mode}")"
  if [[ "${count}" -lt 2 ]]; then
    echo "Error: need at least two commits in the selected range to squash." >&2
    exit 1
  fi
}

render_context() {
  local target_commit="$1"
  local mode="$2"
  local upstream
  local range_spec
  local oldest_commit

  upstream="$(upstream_ref)"
  range_spec="$(range_spec_for_mode "${target_commit}" "${mode}")"
  oldest_commit="$(oldest_commit_in_range "${target_commit}" "${mode}")"

  echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
  if [[ -n "${upstream}" ]]; then
    echo "Upstream: ${upstream}"
  else
    echo "Upstream: (none)"
  fi
  echo "Worktree: $(worktree_state)"
  echo "Mode: ${mode}"
  echo "Target: ${target_commit}"
  echo "Oldest in range: ${oldest_commit}"
  echo "Newest in range: $(git rev-parse HEAD)"
  echo "Commit count: $(range_commit_count "${target_commit}" "${mode}")"
  echo
  if range_touches_upstream "${target_commit}" "${mode}"; then
    echo "Pushed range: yes (one or more commits in the range appear reachable from upstream)"
  else
    echo "Pushed range: no (the range is not confirmed reachable from upstream)"
  fi
  echo
  echo "Commits that would be squashed:"
  git log --reverse --format='%h %s' "${range_spec}"
  echo
  echo "Message options:"
  echo "latest: $(git log -1 --format=%s HEAD)"
  echo "oldest: $(git log -1 --format=%s "${oldest_commit}")"
}

backup_branch_name() {
  local base
  local candidate
  local suffix=1

  base="backup/git-squash-range-$(date -u +%Y%m%d%H%M%S)-$(git rev-parse --short HEAD)"
  candidate="${base}"

  while git show-ref --verify --quiet "refs/heads/${candidate}"; do
    candidate="${base}-${suffix}"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "${candidate}"
}

cmd_context() {
  if [[ $# -lt 1 ]]; then
    echo "Error: missing <target_commit>." >&2
    usage
    exit 1
  fi

  local target_commit mode

  target_commit="$(resolve_commit "$1")"
  shift
  mode="inclusive"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        if [[ $# -lt 2 ]]; then
          echo "Error: --mode requires a value." >&2
          exit 1
        fi
        mode="$2"
        shift
        ;;
      *)
        echo "Error: unknown flag '$1'." >&2
        usage
        exit 1
        ;;
    esac
    shift
  done

  ensure_target_is_ancestor "${target_commit}"
  ensure_meaningful_range "${target_commit}" "${mode}"
  render_context "${target_commit}" "${mode}"
}

cmd_squash() {
  if [[ $# -lt 1 ]]; then
    echo "Error: missing <target_commit>." >&2
    usage
    exit 1
  fi

  local target_commit mode message_source message_file allow_pushed dry_run
  local message_source_set message_file_set
  local reset_point range_oldest backup_branch

  target_commit="$(resolve_commit "$1")"
  shift
  mode="inclusive"
  message_source="latest"
  message_file=""
  allow_pushed="false"
  dry_run="false"
  message_source_set="false"
  message_file_set="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        if [[ $# -lt 2 ]]; then
          echo "Error: --mode requires a value." >&2
          exit 1
        fi
        mode="$2"
        shift
        ;;
      --message-source)
        if [[ $# -lt 2 ]]; then
          echo "Error: --message-source requires a value." >&2
          exit 1
        fi
        message_source="$2"
        message_source_set="true"
        shift
        ;;
      --message-file)
        if [[ $# -lt 2 ]]; then
          echo "Error: --message-file requires a value." >&2
          exit 1
        fi
        message_file="$2"
        message_file_set="true"
        shift
        ;;
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

  if [[ "${message_file_set}" == "true" && "${message_source_set}" == "true" ]]; then
    echo "Error: use either --message-file or --message-source, not both." >&2
    exit 1
  fi

  if [[ -n "${message_file}" && ! -f "${message_file}" ]]; then
    echo "Error: message file not found: ${message_file}" >&2
    exit 1
  fi

  if [[ "${message_source}" != "latest" && "${message_source}" != "oldest" ]]; then
    echo "Error: --message-source must be 'latest' or 'oldest'." >&2
    exit 1
  fi

  ensure_target_is_ancestor "${target_commit}"
  ensure_meaningful_range "${target_commit}" "${mode}"
  ensure_clean_worktree

  if range_touches_upstream "${target_commit}" "${mode}" && [[ "${allow_pushed}" != "true" ]]; then
    if [[ "${dry_run}" == "true" ]]; then
      echo "Warning: the selected range appears reachable from upstream. Actual squash would require --allow-pushed."
    else
      echo "Error: the selected range appears reachable from upstream. Use --allow-pushed to proceed explicitly." >&2
      exit 1
    fi
  fi

  reset_point="$(reset_point_for_mode "${target_commit}" "${mode}")"
  range_oldest="$(oldest_commit_in_range "${target_commit}" "${mode}")"

  if [[ -z "${message_file}" ]]; then
    TMP_SQUASH_MESSAGE_FILE="$(mktemp)"

    case "${message_source}" in
      latest)
        git log -1 --format=%B HEAD > "${TMP_SQUASH_MESSAGE_FILE}"
        ;;
      oldest)
        git log -1 --format=%B "${range_oldest}" > "${TMP_SQUASH_MESSAGE_FILE}"
        ;;
    esac

    message_file="${TMP_SQUASH_MESSAGE_FILE}"
  fi

  backup_branch="$(backup_branch_name)"

  if [[ "${dry_run}" == "true" ]]; then
    echo "Dry run summary:"
    render_context "${target_commit}" "${mode}"
    echo
    echo "Dry run: git branch ${backup_branch} HEAD"
    echo "Dry run: git reset --soft ${reset_point}"
    echo "Dry run: git commit -F ${message_file}"
    exit 0
  fi

  git branch "${backup_branch}" HEAD
  git reset --soft "${reset_point}"
  git commit -F "${message_file}"

  echo
  echo "Squash completed."
  echo "Backup branch: ${backup_branch}"
  echo
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
    squash)
      cmd_squash "$@"
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
