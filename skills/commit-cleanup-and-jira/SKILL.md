---
name: commit-cleanup-and-jira
description: Clean up recent development history and prepare Jira updates. Use when the user wants to squash recent commits, amend the latest commit message using either the repository template or a short generic summary format, choose how the `[TOPIC]` and title are set in template mode, or draft a Jira update comment and optionally sync the Jira title/topic.
---

# Commit Cleanup And Jira

Use this skill for the user's post-coding cleanup flow.

Ask exactly one question at a time and wait for the user's answer before asking the next question.

This skill coordinates existing git cleanup skills and a cautious Jira update workflow:
- clean commit history now
- keep Jira wording short and accurate
- never post Jira text before the user confirms the draft
- ask first whether to follow the repository commit template, defaulting to yes
- when Jira is involved, ask which of the four local/remote sync modes to use for content-only or content-and-title sync
- first read `Issue ID` from the final commit message and use it as the Jira lookup key
- if that Jira ID exists, update it; if it does not exist, create a Jira issue first
- in `content-and-title` modes, treat title sync as a real update action, not just a drafting hint

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
   - Draft the Jira update in chat first.
   - Only post to Jira after explicit confirmation from the user.

Default to `cleanup only` unless the user clearly asks for a Jira draft or Jira update.

## Jira Sync Scenario

Only ask this question when the mode is `cleanup + draft`.

Use this exact prompt shape when Jira is in scope:

`Choose the Jira sync mode. Reply with 1, 2, 3, or 4. Default is 1: local-to-remote content-only.`

Ask with numeric options:

1. `local-to-remote content-only`
2. `local-to-remote content-and-title`
3. `remote-to-local content-only`
4. `remote-to-local content-and-title`

Rules:

- Ask the sync-scenario question before finalizing the local commit message when Jira is in scope.
- Do not skip this question when the mode is `cleanup + draft`.
- Do not silently assume a non-default mode.
- Present all four options together in one numbered selection.
- Tell the user to reply with an integer `1`, `2`, `3`, or `4`.
- Default to `1` (`local-to-remote content-only`) unless the user clearly asks to align Jira title/topic fields or to use Jira naming as the source of truth.
- If the user accepts the default or does not specify a mode after being prompted, use `1`.
- If the user answers in words instead of an integer, map clear intent to the matching option.
- In this section, `content` means the Jira update comment content.
- `local-to-remote content-only`:
  - Treat the final local commit content as the source of truth for the Jira update comment only.
  - Do not propose changing the Jira issue title or topic/summary fields.
  - Keep local commit metadata independent from current Jira title/topic wording.
- `local-to-remote content-and-title`:
  - Treat the final local commit `TOPIC` and title as the source of truth for both the Jira update comment and the proposed Jira title/topic values.
  - In this mode, the remote Jira title/topic should actually be updated after approval; do not treat this as comment-only.
  - Show the proposed Jira title/topic update and the Jira update comment together before applying either one.
  - Do not silently change Jira fields; still draft and confirm first.
- `remote-to-local content-only`:
  - Treat the current Jira issue content as the source of truth for the Jira update comment framing only.
  - Use Jira wording to shape the Jira draft comment, but do not rewrite the local commit `TOPIC` or title from Jira.
  - Keep local commit metadata based on the actual local change set unless the user separately asks to align it.
- `remote-to-local content-and-title`:
  - Treat the Jira title/topic as the source of truth for both the Jira update comment framing and the final local commit `TOPIC` and title.
  - If the Jira title/topic are not already available from the user or current context, ask for them before the squash/amend flow is finalized.
  - Reuse the Jira title/topic when answering template-mode questions in the squash/amend skills.
  - Keep the final Jira update comment aligned with that same Jira title/topic framing.
- Sync scenario controls both direction and scope. It does not bypass the usual review and confirmation steps.

## Jira Lookup And Action

For any Jira-writing flow, determine the Jira action before asking for sync mode.

Rules:

- Read `Issue ID` from the final commit message first.
- Treat `Issue ID` as the Jira lookup key.
- Do not continue into Jira sync unless the final commit message contains `Issue ID`.
- If `Issue ID` is missing from the final commit message, stop and ask the user to provide it or amend the commit message first.
- Check whether that Jira ID already exists.
- If the Jira ID exists, continue in `update` mode.
- If the Jira ID does not exist, continue in `create` mode.
- Ask for the 4-way Jira sync scenario after the create-vs-update decision is known.
- In `create` mode:
  - Ask how to set the Jira description before drafting it.
  - Present description-source options as a numbered selection:
    - `1. ai-summary` (default): generate the Jira description from the final commit, changed files, and selected sync scenario
    - `2. type-one`: ask the user to type the exact Jira description
  - Tell the user to reply with `1` or `2`.
  - If the user accepts the default or does not choose, use `1`.
  - Always prepare a Jira issue description draft.
  - The final approved remote write should create the Jira issue with the approved title/topic framing and description.
  - If the selected scenario is `remote-to-local content-only` or `remote-to-local content-and-title`, there is no existing remote issue content to pull from, so ask the user for the desired remote title/content framing before drafting.
- In `update` mode:
  - Update only the fields implied by the selected 4-way sync scenario.

## Workflow

1. Inspect the recent commit history and choose the overall mode.
   - Review the latest commits and changed files.
   - Decide whether squashing is needed.
   - Default to `cleanup only` unless the user clearly asks for a Jira draft or Jira update.

2. If squashing is needed, use the `git-squash-range` skill.
   - Follow that skill exactly.
   - Ask only the questions required by that skill.
   - Do not rewrite pushed history without explicit user approval.

3. Amend the final commit message with the `git-commit-message-amend` skill.
   - Follow that skill exactly.
   - Use repository-template mode by default.
   - Ask first whether to follow the repository template.
   - Use short-summary mode when the user asks not to use the repository format.
   - In repository-template mode, that skill now asks how to set the title after `[TYPE][TOPIC]`.

4. If the mode is `cleanup + draft`, inspect the final commit message and determine the Jira action.
   - Read `Issue ID` from the final amended commit message.
   - If `Issue ID` is missing, stop and ask the user for it before continuing.
   - Check whether that Jira ID already exists.
   - If it exists, continue in `update` mode.
   - If it does not exist, continue in `create` mode.

5. If the mode is `cleanup + draft`, ask for the Jira sync scenario after the Jira action is known.
   - Ask this explicitly before any Jira draft or Jira-driven local metadata alignment work.
   - Use this prompt shape:
     - `Choose the Jira sync mode. Reply with 1, 2, 3, or 4. Default is 1: local-to-remote content-only.`
   - `1. local-to-remote content-only` (default)
   - `2. local-to-remote content-and-title`
   - `3. remote-to-local content-only`
   - `4. remote-to-local content-and-title`
   - Ask the user to choose by replying with `1`, `2`, `3`, or `4`.
   - If the user accepts the default or does not choose a mode, use `1`.
   - If the Jira action is `update` and scenario `4` is selected, and the Jira title/topic are not already known, ask for them before proceeding.
   - If the Jira action is `create` and scenario `3` or `4` is selected, ask the user for the desired remote title/content framing before proceeding because there is no existing remote issue to pull from.

6. If the Jira action is `create`, ask how to set the Jira description before drafting it.
   - Use numeric options:
     - `1. ai-summary` (default)
     - `2. type-one`
   - Ask the user to choose by replying with `1` or `2`.
   - If the user accepts the default or does not choose a mode, use `1`.
   - If `1` is selected, generate the Jira description from the final commit context, changed files, and selected sync scenario.
   - If `2` is selected, ask the user to type the exact Jira description and use that text as-is.

7. If the mode is `cleanup + draft` and the selected scenario is `remote-to-local content-and-title`, use the Jira topic/title as the default answers for any later local `TOPIC` and title decisions.
   - If the local commit metadata is already finalized and conflicts with the approved Jira source-of-truth framing, amend the local commit message again before the final Jira write.

8. If the mode is `cleanup + draft`, prepare the Jira draft for confirmation.
   - Use the final amended commit and the actual changed files as evidence.
   - Keep the draft short and structured.
   - Show the proposed remote update before applying it.
   - If Jira action is `create`:
     - Always show the proposed Jira title/topic value.
     - Always show the proposed Jira description.
     - The proposed Jira description must come from either the selected `ai-summary` path or the exact user-provided `type-one` text.
     - Also show the proposed Jira update comment if the workflow intends to add one immediately after creation.
   - If Jira action is `update`:
     - In `local-to-remote content-only`, draft the Jira update comment from the final local changes without proposing Jira title/topic changes.
     - In `local-to-remote content-and-title`, draft the Jira update comment from the final local `TOPIC` and title, and also prepare the Jira title/topic update from those same local values.
     - In `remote-to-local content-only`, draft the Jira update comment to match Jira framing while keeping local title/topic independent.
     - In `remote-to-local content-and-title`, keep both the Jira update comment framing and the final local `TOPIC`/title aligned with the Jira source title/topic.
   - In `content-and-title` update modes, show two artifacts for review:
     - the proposed Jira title/topic value
     - the proposed Jira update comment
   - Do not collapse `content-and-title` into comment-only behavior.

9. If the user confirms the draft, apply the Jira action.
   - Prefer the `Issue ID` from the final commit message as the Jira lookup key.
   - If Jira action is `create`, create the Jira issue using the approved draft and include the approved description.
   - If Jira action is `update` and the selected mode is `content-only`, update the Jira comment only.
   - If Jira action is `update` and the selected mode is `local-to-remote content-and-title`, update both the Jira comment and the Jira title/topic using the approved draft.
   - If Jira action is `update` and the selected mode is `remote-to-local content-and-title`, keep the local commit metadata aligned to Jira and post the approved Jira comment; if remote Jira field updates are also requested, confirm and apply them explicitly.

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
- determine Jira `create` vs `update` from the final commit message `Issue ID` before asking for sync mode
- if the selected mode is `content-and-title`, do not update only the comment; apply the approved title/topic update as well

Do not auto-post a Jira comment just because the git cleanup is complete.

## Boundaries

- This skill is for commit cleanup, Jira comment updates, and Jira title/topic sync when the selected mode requires it.
- Do not skip the Jira existence check based on `Issue ID`.
- Do not log Jira work time unless the user explicitly asks.
- Do not assume every commit deserves a Jira update.
- Keep Jira comments meeting-friendly rather than overly technical.
- Do not rewrite local commit metadata or propose Jira field changes without first asking for the sync scenario when Jira is in scope.
