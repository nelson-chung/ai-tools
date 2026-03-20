# Type And Topic Guidelines

Use these rules to produce a consistent commit title:

`[TYPE][TOPIC] Title`

## TYPE

Choose one:

- `ENFORCEMENT`: Enforce an existing rule, validation, policy, or constraint without changing the intended requirement.
- `ENHANCEMENT`: Improve existing behavior without changing core spec intent.
- `BUGFIX`: Fix an incorrect behavior or defect.
- `WORKAROUND`: Partial or temporary mitigation with known limits.
- `SPEC-CHANGE`: Behavior changed due to updated requirements/spec.
- `DOCS`: Documentation-only change.

Quick decision order:

1. If docs only -> `DOCS`
2. Else if requirement changed -> `SPEC-CHANGE`
3. Else if enforcing an existing rule or validation -> `ENFORCEMENT`
4. Else if defect fixed -> `BUGFIX`
5. Else if temporary mitigation -> `WORKAROUND`
6. Else -> `ENHANCEMENT`

Alias normalization:

- Normalize `bug`, `fix bug`, `defect`, or close variants to `BUGFIX`.
- Normalize `enforce`, `enforcement`, `validate`, `validation`, `guard`, or close variants to `ENFORCEMENT`.
- Normalize obvious casing or spelling mistakes in known types to the canonical uppercase form.

## TOPIC

Use a concise module/feature name:

- Prefer existing subsystem naming in the repo.
- Keep it short and specific (examples: `MSP-Dispatcher`, `Report-CDK`, `Manifest-Writer`).
- Avoid broad topics like `Update` or `Fix`.

## Title Line

- One sentence.
- Include what changed and target surface.
- Avoid vague wording.
- In template workflows, ask whether to keep the current title, generate an AI summary title, or use an exact user-provided title.
- If reusing a current subject that already starts with a `[TYPE][TOPIC]` prefix, keep only the text after that prefix.

Example:

- `[BUGFIX][MSP-Dispatcher] Correct DB host injection for stage-specific RDS proxy`

## Body Sections

Fill all template sections with concrete, reviewable details:

- `Description`: Use an ordered list when there are multiple concrete outcomes. Keep each line to one result.
- `Root Cause`: Why issue happened, or `N/A` when there is no defect/root-cause framing.
- `Solution`: What changed and why it resolves the need, or `N/A` when the description is sufficient.
- `Issue ID`: Ticket ID or `N/A`.
- `Reviewer`: Reviewer name or `N/A`.
- `Related To`: Related ticket, dependency, or `N/A`.
- `Merged From`: Source branch, stacked change, or `N/A`.
- `Note`: Side effects, migration, rollout notes, or `N/A`.
