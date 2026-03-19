# Type And Topic Guidelines

Use these rules to produce a consistent commit title:

`[TYPE][TOPIC] Summary`

## TYPE

Choose one:

- `ENHANCEMENT`: Improve existing behavior without changing core spec intent.
- `BUGFIX`: Fix an incorrect behavior or defect.
- `WORKAROUND`: Partial or temporary mitigation with known limits.
- `SPEC-CHANGE`: Behavior changed due to updated requirements/spec.
- `DOCS`: Documentation-only change.

Quick decision order:

1. If docs only -> `DOCS`
2. Else if requirement changed -> `SPEC-CHANGE`
3. Else if defect fixed -> `BUGFIX`
4. Else if temporary mitigation -> `WORKAROUND`
5. Else -> `ENHANCEMENT`

## TOPIC

Use a concise module/feature name:

- Prefer existing subsystem naming in the repo.
- Keep it short and specific (examples: `MSP-Dispatcher`, `Report-CDK`, `Manifest-Writer`).
- Avoid broad topics like `Update` or `Fix`.

## Summary Line

- One sentence.
- Include what changed and target surface.
- Avoid vague wording.

Example:

- `[BUGFIX][MSP-Dispatcher] Correct DB host injection for stage-specific RDS proxy`

## Body Sections

Fill all template sections with concrete, reviewable details:

- `Description`: What scenario is addressed.
- `Root Cause`: Why issue happened (use `N/A` if not applicable).
- `Solution`: What changed and user impact (use `N/A` if not applicable).
- `Issue ID`: Ticket ID or `N/A`.
- `Note`: Side effects, migration, rollout notes, or `N/A`.
