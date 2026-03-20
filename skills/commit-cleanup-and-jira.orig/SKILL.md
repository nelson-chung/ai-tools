---
name: commit-cleanup-and-jira
description: Clean up recent development history and prepare Jira updates. Use when the user wants to squash recent commits, amend the latest commit message using either the repository template or a short generic summary format, or draft a short Jira comment after coding without posting it immediately.
---

# Commit Cleanup And Jira

Use this skill for the user's post-coding cleanup flow.

This skill coordinates existing git cleanup skills and a cautious Jira update workflow:
- clean commit history now
- keep Jira wording short and accurate
- never post Jira text before the user confirms the draft
- ask first whether to follow the repository commit template, defaulting to yes

## Modes

Choose one of these modes:

1. `cleanup only`
   - Use when the user wants clean git history without any Jira update.
   - Squash recent commits if needed.
   - Amend the latest commit message.
   - Default to the repository format unless the user asks for a private-project or non-template message.
   - Do not draft or post a Jira comment.

2. `cleanup + draft`
   - Use when the user wants clean git history and a Jira-ready update.
   - Squash recent commits if needed.
   - Amend the latest commit message.
   - Default to the repository format unless the user asks for a private-project or non-template message.
   - Draft the Jira comment in chat first.
   - Only post to Jira after explicit confirmation from the user.

Default to `cleanup only` unless the user clearly asks for a Jira draft or Jira update.

## Workflow

1. Inspect the recent commit history.
   - Review the latest commits and changed files.
   - Decide whether squashing is needed.

2. If squashing is needed, use the `git-squash-range` skill.
   - Follow that skill exactly.
   - Ask only the questions required by that skill.
   - Do not rewrite pushed history without explicit user approval.

3. Amend the final commit message with the `git-commit-message-amend` skill.
   - Follow that skill exactly.
   - Use repository-template mode by default.
   - Ask first whether to follow the repository template.
   - Use short-summary mode when the user asks not to use the repository format.

4. If the mode is `cleanup + draft`, prepare a Jira comment draft.
   - Use the final amended commit and the actual changed files as evidence.
   - Keep the draft short and structured.
   - Show the draft before posting.

5. If the user confirms the draft, post that exact draft to Jira.
   - Prefer the `Issue ID` from the final commit message.
   - If the final commit message does not contain an issue key, ask the user for the Jira issue.

## Jira Draft Style

Always use this style for Jira drafts unless the user asks otherwise:
- use `-` bullets
- keep it to `2-4` bullets
- keep each bullet to one complete result
- keep wording clear, short, and easy to scan
- focus on current truth, not planned future work
- prefer action verbs such as `Added`, `Updated`, `Refined`, `Validated`
- avoid vague wording such as `worked on`, `handled`, or `did changes`

## Conservative Wording Rule

When the work may still be experimental or subject to change:
- prefer `Investigated`, `Tested`, `Prototyped`, `Validated initial`
- avoid `Completed`, `Finished`, or `Implemented` unless clearly true
- do not overstate certainty based only on intermediate commits

When the outcome is already stable and reflected in the final commit:
- prefer `Added`, `Updated`, `Refined`, `Validated`

## Posting Rule

For any Jira-writing flow:
- draft first
- post only after explicit user confirmation

Do not auto-post a Jira comment just because the git cleanup is complete.

## Boundaries

- This skill is for commit cleanup and Jira comment updates only.
- Do not log Jira work time unless the user explicitly asks.
- Do not assume every commit deserves a Jira update.
- Keep Jira comments meeting-friendly rather than overly technical.
