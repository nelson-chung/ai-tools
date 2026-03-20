---
name: git-squash-range
description: Squash a contiguous range of commits ending at HEAD into one commit using a non-interactive workflow. Use when asked to squash recent commits, rewrite local git history from HEAD back to a provided commit id, or guide a user through choosing which HEAD-ending commit range to squash one question at a time.
---

# Git Squash Range

Use this skill to squash a HEAD-ending commit range without opening an interactive rebase editor.

## Required Interaction

Ask exactly one question at a time and wait for the user's answer before asking the next question.

Required order:

1. `Target commit ID`
2. `Mode`
3. `Commit message strategy`
4. `Final confirmation`

Rules:

- Ask for the target commit ID first.
- Accept either a full commit SHA or a unique abbreviated SHA.
- Ask for at least 7 hexadecimal characters unless the user already provided a longer ID.
- If the provided ID is ambiguous or does not resolve, ask for a longer commit ID.
- After the user gives a commit ID, ask whether the squash should be:
  - `1. inclusive` (default): squash the target commit and every commit after it through `HEAD`
  - `2. exclusive`: keep the target commit as the base and squash only the commits after it through `HEAD`
- Present the mode question as a numbered selection and let the user answer with `1` or `2`.
- Default step 2 to `inclusive` if the user accepts the default or does not specify a mode after being prompted.
- Before asking for final confirmation, show the exact commits that would be rewritten by running the context command from the script.
- Ask for commit message strategy only after the range preview is shown.
  - `1. latest` (default): reuse the current `HEAD` commit message
  - `2. oldest`: reuse the oldest commit message inside the squashed range
  - `3. new`: collect a brand new commit message
  - `4. ai-summary`: draft a new commit message from the range preview, show it for review, and let the user reply `keep` to accept it or replace it with their own summary
- Present the commit message strategy as a numbered selection and let the user answer with `1`, `2`, `3`, or `4`.
- Default step 4 to `latest` if the user accepts the default or does not specify a strategy after being prompted.
- If the user chooses `3`, ask for the full new commit message after the strategy question and before final confirmation.
- If the user chooses `4`, draft a commit message from the commits in the selected range and show it before final confirmation.
- In `ai-summary` mode, generate the draft primarily from the selected range contents and changed files; use commit subjects only as supporting context.
- In `ai-summary` mode, always include a one-line subject. Add a short bullet body when the range spans multiple files, multiple themes, or weak commit subjects where a title alone would be too lossy.
- In `ai-summary` mode, ask exactly one follow-up question for the summary review: tell the user to reply `keep` if the draft is okay, or type a replacement summary if it is not.
- If the user replies `keep` in `ai-summary` mode, keep the generated summary exactly as shown.
- If the user types a replacement summary in `ai-summary` mode, use that replacement as the final commit message.
- Do not run the squash until the user gives an explicit confirmation after seeing the preview.

## Files

- `scripts/squash_range.sh`

## Workflow

1. Preview the requested range.
   - Run:
     - `bash scripts/squash_range.sh context <target_commit> --mode <inclusive|exclusive>`
2. Show the user the commits that would be squashed and confirm the meaning of the selected mode.
3. Ask how to set the resulting commit message.
   - `1. latest` (default): reuse the current `HEAD` commit message
   - `2. oldest`: reuse the oldest commit message inside the squashed range
   - `3. new`: collect a new multi-line commit message from the user and save it to a temp file
   - `4. ai-summary`: draft a commit message from the selected range, preview it, and let the user reply `keep` to accept it or replace it with a new summary
4. If the user selects `ai-summary`, prepare the draft before final confirmation.
   - Generate a commit message draft from the commits in the selected range.
   - Base the draft on the range preview and changed files, using commit subjects only as supporting context.
   - Always include a one-line subject.
   - Add a short bullet body when the range covers multiple meaningful changes or the subject alone would be too vague.
   - Show the full draft message in chat.
   - Ask exactly one question: reply `keep` keeps the draft; any other non-empty reply replaces it.
   - Save the accepted or replaced summary to a temp message file.
5. Perform the squash.
   - Reuse an existing message:
     - `bash scripts/squash_range.sh squash <target_commit> --mode <inclusive|exclusive> --message-source <latest|oldest>`
   - Use a new message file:
     - `bash scripts/squash_range.sh squash <target_commit> --mode <inclusive|exclusive> --message-file <message_file>`
6. Verify the result.
   - Run:
     - `git log -1 --pretty=fuller`
     - `git log --oneline -n 5`

## Safety

- Keep the flow non-interactive. Do not use `git rebase -i`.
- The script blocks squashing when the worktree or index is dirty.
- The script blocks squashing ranges that appear reachable from upstream unless `--allow-pushed` is passed explicitly.
- The script creates a local backup branch before rewriting history.
- If the target commit is the repository root, do not use `inclusive`; the helper script rejects that case.
