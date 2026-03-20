# AI Tools

This repository stores repository-local AI assistant assets.

## Layout

- `skills/`: Custom skills and their bundled resources
- `AGENTS.md`: Session-facing instructions and skill discovery notes

## Available Skills

- `git-commit-message-amend`: Amend the latest commit message using either the repository template or a short generic summary format
- `git-squash-range`: Squash a contiguous range of commits ending at `HEAD` with a non-interactive helper script and safety checks
- `commit-cleanup-and-jira`: Clean up recent development history and prepare short Jira update drafts without auto-posting

## Jira MCP Prerequisite

The `commit-cleanup-and-jira` skill can draft Jira updates without Jira access, but posting to Jira requires the Jira MCP server to be configured first.

Recommended setup:

1. Install `uv` so `uvx` is available.
2. Add the Jira MCP server to Codex.
3. Verify that Codex can see the `jira` MCP entry.

Example setup command:

```bash
codex mcp add jira \
  --env JIRA_URL=https://your-company.atlassian.net/ \
  --env JIRA_USERNAME=your.email@company.com \
  --env JIRA_API_TOKEN=your_api_token \
  -- uvx mcp-atlassian
```

Verify with:

```bash
codex mcp get jira
```

If MCP startup fails with `No such file or directory`, `uvx` is usually not on `PATH`. In that case, point the Jira MCP command at the absolute `uvx` path in your Codex config, for example:

```toml
[mcp_servers.jira]
command = "/root/.local/bin/uvx"
args = ["mcp-atlassian"]
```

## How To Invoke A Skill

You can invoke a skill in either of these ways:

1. Explicitly by name
   - Example: `$commit-cleanup-and-jira`
   - Example: `$git-commit-message-amend`
   - Example: `$git-squash-range`
   - Example: `use commit-cleanup-and-jira`
   - Example: `use git-commit-message-amend`
   - Example: `use git-squash-range`

2. Implicitly by describing the task
   - Example: `squash these recent commits and draft a Jira update`
   - Example: `amend the latest commit message and prepare a Jira comment`
   - Example: `rewrite my latest commit message using the repo template`
   - Example: `rewrite my latest commit message for a private project without the repo format`
   - Example: `squash recent commits from HEAD back to this commit`

Explicit invocation is the most reliable way to force a specific skill.

## Skill Documentation

Do not add a `README.md` inside a skill folder.

Skill documentation should live in:
- `SKILL.md` for the core workflow and trigger description
- `references/` for optional deeper documentation
- `scripts/` for reusable deterministic helpers
- `agents/skill.yaml` for UI metadata
