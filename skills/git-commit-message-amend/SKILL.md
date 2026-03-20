---
name: git-commit-message-amend
description: Amend the latest git commit message using either the repository template or a short generic summary format. Use when asked to rewrite or improve the most recent commit message, enforce [TYPE][TOPIC] format, choose how the title after `[TYPE][TOPIC]` is set, or run non-interactive git commit --amend flows with safety checks for already-pushed commits and a draft review step before amending.
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
3. `Title source`
4. `Issue ID`
5. `Reviewer`

Rules:

- Ask for `TYPE` first.
- Offer `ENFORCEMENT`, `ENHANCEMENT`, `BUGFIX`, or another user-provided type.
- Normalize known types to their canonical uppercase spelling.
- Normalize short intent words to the canonical type before drafting.
- Treat `bug`, `fix bug`, or `defect` as `BUGFIX`.
- Treat `enforce`, `enforcement`, `validate`, `validation`, or `guard` as `ENFORCEMENT`.
- If the user provides another type, normalize it to uppercase and confirm it if the intent is unclear.
- Correct obvious casing or spelling mistakes in known types before drafting the message.
- Ask for the title source immediately after `TOPIC`.
- Present title-source options as a numbered selection:
  - `1. keep-current`: reuse the current latest commit subject as the title text after `[TYPE][TOPIC]`
  - `2. ai-summary`: generate a concise title from the latest commit context
  - `3. type-one`: ask the user to type the exact title text
- If the current latest commit subject already starts with a `[TYPE][TOPIC]` prefix, strip that prefix before reusing the rest as the title text.
- Do not infer the title source without asking in repository-template mode.
- Derive `Description` by summarizing the latest commit context and changed files.
- Format `Description` as an ordered list when there are multiple concrete changes.
- Default `Root Cause` to `N/A` unless the user explicitly provides one.
- Default `Solution` to `N/A` unless the user explicitly provides content.
- Default `Related To` to `N/A` unless the user explicitly provides content.
- Default `Merged From` to `N/A` unless the user explicitly provides content.
- Default `Note` to `N/A` unless the user explicitly provides content.
- Do not skip ahead or combine questions.
- Do not amend the commit message until `TYPE`, `TOPIC`, title source, `Issue ID`, and `Reviewer` are answered and the draft review step is complete.
- If `Issue ID` is unknown, ask the user to confirm `N/A`.
- If `Reviewer` is unknown, ask the user to confirm `N/A`.
- Do not infer `TYPE`, `TOPIC`, title text, `Issue ID`, or `Reviewer` unless the user explicitly asks for a suggestion.

### short-summary

Required order:

1. `Draft review`

Rules:

- Draft the summary from the latest commit context before asking the user to review it.
- Do not ask for `TYPE`, `TOPIC`, `Issue ID`, or `Reviewer` in this mode.
- Do not use the repository template.
- The final commit message should be short and optimized for reading.
- Use bullet-point style in the message body.
- Keep the body concise, but do not arbitrarily stop at `2-4` bullets when more material changes need to be represented.
- Prefer `3-6` bullets when the change set covers multiple meaningful updates.
- Include all material changes; only collapse items that are trivial, repetitive, or too low-signal to deserve their own bullet.
- Use the first line as a short subject derived from the drafted summary and commit context.
- Keep each bullet to one concrete change or result.
- Before amending, show the proposed subject and body, then ask whether the summary should be replaced.

## Draft Review

After the skill prepares a draft message in either mode, show a short review and ask exactly one question at a time.

Rules:

- Show the proposed title or summary line before the amend step.
- In `repository-template` mode, show the full first line as `[TYPE][TOPIC] Title`.
- In `short-summary` mode, show the proposed subject and concise bullet body.
- Tell the user they can type a replacement title or summary if they want to override the drafted one.
- Tell the user that an empty reply means to keep the drafted title or summary.
- If the client cannot easily send an empty reply, accept `keep`, `default`, `use yours`, or equivalent as "use the drafted title or summary".
- If the user provides a new title in `repository-template` mode, replace only the title text after `[TYPE][TOPIC]` before amending.
- If the user provides a new summary in `short-summary` mode, replace the drafted subject and regenerate the concise body if needed.
- If the user keeps the drafted title or summary, amend using the generated draft without further changes.

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
5. If mode is `repository-template`, validate `TYPE` and collect title-source choice.
   - Prefer `ENFORCEMENT`, `ENHANCEMENT`, or `BUGFIX` when they fit the change.
   - If the user supplies another type, convert it to uppercase.
   - If the user misspells a known type, correct it to the canonical uppercase form.
   - Normalize `bug`, `fix bug`, or `defect` to `BUGFIX`.
   - Normalize `enforce`, `enforcement`, `validate`, `validation`, or `guard` to `ENFORCEMENT`.
   - Use `references/type-topic-guidelines.md` when mapping the requested type to the final title.
   - Ask for title-source choice after `TOPIC`:
     - `1` -> keep the current latest commit subject as title text
     - `2` -> generate an AI summary title from the latest commit context
     - `3` -> ask the user for the exact title text
6. Prepare a draft message file with a generated title or summary in both modes.
   - In `repository-template` mode:
     - Copy `templates/commit-message.template` to a temp file.
     - Fill the title after `[TYPE][TOPIC]` according to the selected title source.
     - For `keep-current`, reuse the current latest commit subject and strip any leading `[TYPE][TOPIC]` prefix before insertion.
     - For `ai-summary`, generate a concise title from the latest commit context.
     - For `type-one`, use the exact title text provided by the user.
     - Fill `Description` from a concise summary of the latest commit context.
     - Use an ordered list for `Description` when there are multiple concrete outcomes.
     - Use `N/A` for `Root Cause` unless the user provided one.
     - Use `N/A` for `Solution` unless the user provided one.
     - Fill `Issue ID` from the user's answer.
     - Fill `Reviewer` from the user's answer.
     - Use `N/A` for `Related To` unless the user provided one.
     - Use `N/A` for `Merged From` unless the user provided one.
     - Use `N/A` for `Note` unless the user provided one.
   - In `short-summary` mode:
     - Create a temp file with a short generated subject on the first line.
     - Add a blank line.
     - Add a short bullet list derived from the generated summary and the latest commit context.
     - Prefer `3-6` bullets when the change set has multiple meaningful updates.
     - Do not arbitrarily stop at `2-4` bullets if that would omit material changes.
     - Collapse only trivial, repetitive, or low-signal items.
     - Keep wording concrete and easy to scan.
7. Review the draft with the user before amending.
   - Show the proposed title or summary line and the rest of the message in a compact preview.
   - In `repository-template` mode, hint clearly that they can type a new title to replace only the text after `[TYPE][TOPIC]`, or send an empty reply / `keep` to use the drafted title as-is.
   - In `short-summary` mode, hint clearly that they can type a new summary to override it, or send an empty reply / `keep` to use the drafted summary as-is.
8. If the user provides a replacement title or summary, regenerate the message file with that replacement.
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
- In both modes, the skill drafts the title or summary first and lets the user override it during review.
