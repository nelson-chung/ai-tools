---
name: git-commit-message-amend
description: Amend the latest git commit message using a strict repository template. Use when asked to rewrite or improve the most recent commit message, enforce [TYPE][TOPIC] format, or run non-interactive git commit --amend flows with safety checks for already-pushed commits.
---

# Git Commit Message Amend

Use this skill to amend the latest commit message in a consistent and non-interactive way.

## Required Interaction

Before drafting the commit message, collect only the fields that must come from the user in chat.

Ask exactly one question at a time and wait for the user's answer before asking the next question.

Required order:

1. `TYPE`
2. `TOPIC`
3. `Issue ID`

Rules:

- Ask for `TYPE` first.
- Offer `ENHANCEMENT`, `BUGFIX`, or another user-provided type.
- Normalize known types to their canonical uppercase spelling.
- If the user provides another type, normalize it to uppercase and confirm it if the intent is unclear.
- Correct obvious casing or spelling mistakes in known types before drafting the message.
- Derive `Description` by summarizing the latest commit context and changed files.
- Default `Root Cause` to `N/A` unless the user explicitly provides one.
- Leave `Solution` blank unless the user explicitly provides content.
- Leave `Note` blank unless the user explicitly provides content.
- Do not skip ahead or combine questions.
- Do not draft or amend the commit message until `TYPE`, `TOPIC`, and `Issue ID` are answered.
- If `Issue ID` is unknown, ask the user to confirm `N/A`.
- Do not infer `TYPE`, `TOPIC`, or `Issue ID` unless the user explicitly asks for a suggestion.

## Files

- `scripts/amend_latest_commit.sh`
- `references/type-topic-guidelines.md`
- `templates/commit-message.template`

## Workflow

1. Collect latest commit context.
   - Run:
     - `bash scripts/amend_latest_commit.sh context`
2. Ask the user for `TYPE`, then `TOPIC`, then `Issue ID`, one at a time.
3. Validate `TYPE`.
   - Prefer `ENHANCEMENT` or `BUGFIX`.
   - If the user supplies another type, convert it to uppercase.
   - If the user misspells a known type, correct it to the canonical uppercase form.
   - Use `references/type-topic-guidelines.md` when mapping the requested type to the final title.
4. Prepare a message file from template.
   - Copy `templates/commit-message.template` to a temp file.
   - Fill `Description` from a concise summary of the latest commit context.
   - Use `N/A` for `Root Cause` unless the user provided one.
   - Leave `Solution` blank unless the user provided one.
   - Fill `Issue ID` from the user's answer.
   - Leave `Note` blank unless the user provided one.
5. Amend latest commit message.
   - Run:
     - `bash scripts/amend_latest_commit.sh amend <message_file>`
6. Verify final result.
   - Confirm output from:
     - `git log -1 --pretty=fuller`

## Safety

- If latest commit is already reachable from upstream, the script blocks amend by default.
- Only bypass with explicit intent:
  - `bash scripts/amend_latest_commit.sh amend <message_file> --allow-pushed`

## Notes

- Keep execution non-interactive. Do not use interactive editors.
- Do not amend commits older than `HEAD` with this skill.
