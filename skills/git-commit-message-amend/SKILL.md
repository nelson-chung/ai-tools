---
name: git-commit-message-amend
description: Amend the latest git commit message using either the repository template or a short generic summary format. Use when asked to rewrite or improve the most recent commit message, enforce [TYPE][TOPIC] format, or run non-interactive git commit --amend flows with safety checks for already-pushed commits and a draft review step before amending.
---

# Git Commit Message Amend

Use this skill to amend the latest commit message in a consistent and non-interactive way.

## First Question

Before collecting any commit fields, ask whether to follow the repository template.

Ask with numeric options:

1. `Yes`
2. `No`

Rules:

- Ask this question first.
- Default is `1` (`Yes`) when the user does not explicitly ask to avoid the template.
- Accept integer-style answers such as `1` or `2`.
- If the user answers in words, map clear intent to the matching option.
- If the user explicitly says this is a private project or says not to use the template, use `2`.

## Modes

After the first question, use one of these modes:

1. `repository-template`
   - Chosen when the answer is `1`.
   - Use the structured `[TYPE][TOPIC]` format.

2. `short-summary`
   - Chosen when the answer is `2`.
   - Do not enforce `[TYPE][TOPIC]`.
   - Produce a short, easy-to-read summary message.

## Required Interaction

Before drafting the commit message, collect only the fields that must come from the user in chat.

Ask exactly one question at a time and wait for the user's answer before asking the next question.

### repository-template

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
- Derive the title `Summary` from the latest commit context before review.
- Derive `Description` by summarizing the latest commit context and changed files.
- Default `Root Cause` to `N/A` unless the user explicitly provides one.
- Leave `Solution` blank unless the user explicitly provides content.
- Leave `Note` blank unless the user explicitly provides content.
- Do not skip ahead or combine questions.
- Do not amend the commit message until `TYPE`, `TOPIC`, and `Issue ID` are answered and the draft review step is complete.
- If `Issue ID` is unknown, ask the user to confirm `N/A`.
- Do not infer `TYPE`, `TOPIC`, or `Issue ID` unless the user explicitly asks for a suggestion.

### short-summary

Required order:

1. `Draft review`

Rules:

- Draft the summary from the latest commit context before asking the user to review it.
- Do not ask for `TYPE`, `TOPIC`, or `Issue ID` in this mode.
- Do not use the repository template.
- The final commit message should be short and optimized for reading.
- Use bullet-point style in the message body.
- Keep the body concise, preferably `2-4` bullets.
- Use the first line as a short subject derived from the drafted summary and commit context.
- Keep each bullet to one concrete change or result.
- Before amending, show the proposed subject and body, then ask whether the summary should be replaced.

## Draft Review

After the skill prepares a draft message in either mode, show a short review and ask exactly one question at a time.

Rules:

- Show the proposed summary line before the amend step.
- In `repository-template` mode, show the full first line as `[TYPE][TOPIC] Summary`.
- In `short-summary` mode, show the proposed subject and concise bullet body.
- Tell the user they can type a replacement summary if they want to override the drafted one.
- Tell the user that an empty reply means to keep the drafted summary.
- If the client cannot easily send an empty reply, accept `keep`, `default`, `use yours`, or equivalent as "use the drafted summary".
- If the user provides a new summary, replace the drafted summary with the user's text before amending.
- If the user keeps the drafted summary, amend using the generated draft without further summary changes.

## Files

- `scripts/amend_latest_commit.sh`
- `references/type-topic-guidelines.md`
- `templates/commit-message.template`

## Workflow

1. Collect latest commit context.
   - Run:
     - `bash scripts/amend_latest_commit.sh context`
2. Ask whether to follow the repository template.
   - Use numeric options: `1` for yes, `2` for no.
   - Default to `1` unless the user explicitly asks not to use the template.
3. Select mode from the first answer.
   - `1` -> `repository-template`
   - `2` -> `short-summary`
4. Collect required user fields one at a time for the selected mode.
5. If mode is `repository-template`, validate `TYPE`.
   - Prefer `ENHANCEMENT` or `BUGFIX`.
   - If the user supplies another type, convert it to uppercase.
   - If the user misspells a known type, correct it to the canonical uppercase form.
   - Use `references/type-topic-guidelines.md` when mapping the requested type to the final title.
6. Prepare a draft message file with a generated summary in both modes.
   - In `repository-template` mode:
     - Copy `templates/commit-message.template` to a temp file.
     - Fill the title `Summary` from a concise summary of the latest commit context.
     - Fill `Description` from a concise summary of the latest commit context.
     - Use `N/A` for `Root Cause` unless the user provided one.
     - Leave `Solution` blank unless the user provided one.
     - Fill `Issue ID` from the user's answer.
     - Leave `Note` blank unless the user provided one.
   - In `short-summary` mode:
     - Create a temp file with a short generated subject on the first line.
     - Add a blank line.
     - Add a short bullet list derived from the generated summary and the latest commit context.
     - Keep the bullet list to `2-4` bullets when possible.
     - Keep wording concrete and easy to scan.
7. Review the draft with the user before amending.
   - Show the proposed summary and the rest of the message in a compact preview.
   - Hint clearly: they can type a new summary to override it, or send an empty reply / `keep` to use the drafted summary as-is.
8. If the user provides a replacement summary, regenerate the message file with that summary.
9. Amend latest commit message.
   - Run:
     - `bash scripts/amend_latest_commit.sh amend <message_file>`
10. Verify final result.
   - Confirm output from:
     - `git log -1 --pretty=fuller`

## Safety

- If latest commit is already reachable from upstream, the script blocks amend by default.
- Only bypass with explicit intent:
  - `bash scripts/amend_latest_commit.sh amend <message_file> --allow-pushed`

## Notes

- Keep execution non-interactive. Do not use interactive editors.
- Do not amend commits older than `HEAD` with this skill.
- In `short-summary` mode, do not force repository-specific structure onto the user.
- In both modes, the skill drafts the summary first and lets the user override it during review.
