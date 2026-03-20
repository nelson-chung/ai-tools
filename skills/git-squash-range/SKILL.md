---
name: git-squash-range
description: Squash a contiguous range of commits ending at HEAD into one commit using a non-interactive workflow. Use when asked to squash recent commits, rewrite local git history from HEAD back to a provided commit id, choose whether the squashed message follows the repository template, choose how the title after `[TYPE][TOPIC]` is set, or guide a user through choosing which HEAD-ending commit range to squash one question at a time.
---

# Git Squash Range

Use this skill to squash a HEAD-ending commit range without opening an interactive rebase editor.

## Required Interaction

Ask exactly one question at a time and wait for the user's answer before asking the next question.

Required order:

1. `Target commit ID`
2. `Mode`
3. `Commit message strategy`
4. `Template preference` if step 3 is `ai-summary`
5. `Title source` if steps 3 and 4 are `ai-summary` + `repository-template`
6. `Final confirmation`

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
- Default the commit message strategy to `latest` if the user accepts the default or does not specify a strategy after being prompted.
- If the user chooses `3`, ask for the full new commit message after the strategy question and before final confirmation.
- If the user chooses `4`, ask whether the generated summary should follow the repository template.
  - `1. yes` (default): use the structured `[TYPE][TOPIC]` format
  - `2. no`: use a short summary format
- Present the template question as a numbered selection and let the user answer with `1` or `2`.
- Default the template question to `yes` unless the user clearly asks not to use the template.
- In `ai-summary` mode, generate the draft primarily from the selected range contents and changed files; use commit subjects only as supporting context.
- In `ai-summary` + `repository-template` mode:
  - Ask exactly one question at a time for `TYPE`, `TOPIC`, title source, `Issue ID`, and `Reviewer` before drafting.
  - Offer `ENFORCEMENT`, `ENHANCEMENT`, `BUGFIX`, or another user-provided type.
  - Normalize `bug`, `fix bug`, or `defect` to `BUGFIX`.
  - Normalize `enforce`, `enforcement`, `validate`, `validation`, or `guard` to `ENFORCEMENT`.
  - Correct obvious casing or spelling mistakes in known types before drafting.
  - Present title-source options as a numbered selection:
    - `1. keep-current`: reuse the current `HEAD` subject as the title text after `[TYPE][TOPIC]`
    - `2. ai-summary`: generate a concise title from the selected range contents
    - `3. type-one`: ask the user to type the exact title text
  - If the current `HEAD` subject already starts with a `[TYPE][TOPIC]` prefix, strip that prefix before reusing the rest as the title text.
  - Do not infer `TYPE`, `TOPIC`, title text, `Issue ID`, or `Reviewer` unless the user explicitly asks for a suggestion.
  - Derive `Description` from the selected range contents and changed files.
  - Format `Description` as an ordered list when there are multiple concrete changes.
  - Default `Root Cause`, `Solution`, `Related To`, `Merged From`, and `Note` to `N/A` unless the user explicitly provides content.
  - Show the full draft message in chat before final confirmation.
  - Ask exactly one review question: reply `keep` to use the draft, or type a replacement title to replace only the drafted title text after `[TYPE][TOPIC]`.
  - If the user replies `keep`, keep the generated draft exactly as shown.
  - If the user types a replacement title, keep the template structure and replace only the drafted title text after `[TYPE][TOPIC]`.
- In `ai-summary` + `short-summary` mode:
  - Always include a one-line subject.
  - Add a short bullet body when the range spans multiple files, multiple themes, or weak commit subjects where a title alone would be too lossy.
  - Do not arbitrarily stop at `2-4` bullets when the selected range contains more material changes.
  - Prefer `3-6` bullets when the range covers multiple meaningful updates.
  - Include all material changes; only collapse trivial, repetitive, or low-signal items.
  - Ask exactly one follow-up question for the summary review: tell the user to reply `keep` if the draft is okay, or type a replacement summary if it is not.
  - If the user replies `keep`, keep the generated summary exactly as shown.
  - If the user types a replacement summary, use that replacement as the final commit message.
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
4. If the user selects `ai-summary`, ask whether the draft should follow the repository template.
   - `1. yes` (default): use the structured `[TYPE][TOPIC]` format
   - `2. no`: use a short summary format
5. If the user selects `ai-summary` + repository-template, collect `TYPE`, `TOPIC`, title source, `Issue ID`, and `Reviewer` one question at a time before drafting.
   - Normalize `bug`, `fix bug`, or `defect` to `BUGFIX`.
   - Normalize `enforce`, `enforcement`, `validate`, `validation`, or `guard` to `ENFORCEMENT`.
   - Ask for title-source choice after `TOPIC`:
     - `1` -> keep the current `HEAD` subject as title text
     - `2` -> generate an AI summary title from the selected range contents
     - `3` -> ask the user for the exact title text
6. If the user selects `ai-summary`, prepare the draft before final confirmation.
   - Generate a commit message draft from the commits in the selected range.
   - Base the draft on the range preview and changed files, using commit subjects only as supporting context.
   - In repository-template mode:
     - Fill the title after `[TYPE][TOPIC]` according to the selected title source.
     - For `keep-current`, reuse the current `HEAD` subject and strip any leading `[TYPE][TOPIC]` prefix before insertion.
     - For `ai-summary`, generate a concise title from the selected range contents.
     - For `type-one`, use the exact title text provided by the user.
     - Fill `Description` from the selected range contents and changed files.
     - Default `Root Cause`, `Solution`, `Related To`, `Merged From`, and `Note` to `N/A` unless the user provides content.
     - Show the full template draft in chat.
     - Ask exactly one review question: reply `keep` keeps the draft; any other non-empty reply replaces only the drafted title text after `[TYPE][TOPIC]`.
   - In short-summary mode:
     - Always include a one-line subject.
     - Add a short bullet body when the range covers multiple meaningful changes or the subject alone would be too vague.
     - Prefer `3-6` bullets when the range has multiple meaningful updates.
     - Do not arbitrarily stop at `2-4` bullets if that would omit material changes.
     - Collapse only trivial, repetitive, or low-signal items.
     - Show the full draft message in chat.
     - Ask exactly one review question: reply `keep` keeps the draft; any other non-empty reply replaces the full message.
   - Save the accepted or updated draft to a temp message file.
7. Perform the squash.
   - Reuse an existing message:
     - `bash scripts/squash_range.sh squash <target_commit> --mode <inclusive|exclusive> --message-source <latest|oldest>`
   - Use a new message file:
     - `bash scripts/squash_range.sh squash <target_commit> --mode <inclusive|exclusive> --message-file <message_file>`
8. Verify the result.
   - Run:
     - `git log -1 --pretty=fuller`
     - `git log --oneline -n 5`

## Safety

- Keep the flow non-interactive. Do not use `git rebase -i`.
- The script blocks squashing when the worktree or index is dirty.
- The script blocks squashing ranges that appear reachable from upstream unless `--allow-pushed` is passed explicitly.
- If the target commit is the repository root, do not use `inclusive`; the helper script rejects that case.
