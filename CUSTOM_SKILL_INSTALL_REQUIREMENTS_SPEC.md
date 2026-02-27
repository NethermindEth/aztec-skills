# Custom Skill Installation Requirements Spec (Codex + Claude Code)

Version: 1.0  
Last verified: February 27, 2026  
Scope: Installation and discovery requirements for custom/local skills in Codex and Claude Code.

## 1. Purpose

This document defines a single, implementation-ready requirements profile for installing custom skills in:

- Codex (OpenAI)
- Claude Code (Anthropic)

It is designed for distribution teams that need predictable, cross-tool behavior.

## 2. Compatibility Profile

Use this profile to avoid edge-case incompatibilities across docs/spec variants:

- Skill directory MUST contain `SKILL.md`.
- `SKILL.md` MUST include frontmatter with both:
  - `name`
  - `description`
- `name` SHOULD be lowercase kebab-case and <= 64 chars.
- Instructions SHOULD be concise and structured for LLM execution.

Rationale: Some Anthropic docs mark `name` as optional, while others/spec ecosystems require it. Requiring both fields is the safest portable baseline.

## 3. Codex Requirements (OpenAI)

### 3.1 Skill Format

- A skill is a directory with a `SKILL.md` entry file.
- `SKILL.md` frontmatter requires at least:
  - `name`
  - `description`

### 3.2 Install Locations

Codex discovers skills from these locations:

- Repository scope: `.agents/skills/`
- User scope: `~/.agents/skills`
- System scope: `/etc/codex/skills`

### 3.3 Installation Methods

- Manual: copy/create skill folder in one of the discovery paths above.
- Managed: use built-in `$skill-installer` to install curated or repository-hosted skills.

### 3.4 Discovery Behavior

- Codex auto-detects new/updated skills.
- If detection does not occur, restart the Codex session.

### 3.5 Operational Controls

- Skills can be disabled via `~/.codex/config.toml` using `[[skills.config]]` entries (`path`, `enabled=false`).

## 4. Claude Code Requirements (Anthropic)

### 4.1 Skill Format

- A skill is a directory containing `SKILL.md`.
- `SKILL.md` uses YAML frontmatter + markdown instructions.
- For portable installs, require both `name` and `description`.

### 4.2 Install Locations

Supported local install paths:

- Personal scope: `~/.claude/skills/<skill-name>/SKILL.md`
- Project scope: `.claude/skills/<skill-name>/SKILL.md`

Also documented in Anthropic skill docs (broader environments):

- Project: `.claude/skills/`
- User: `~/.claude/skills/`
- Plugin: `~/.claude/plugins/<plugin>/skills/`
- Enterprise policy-managed skill path (if configured by org admins)

### 4.3 Additional Directory Loading

- Claude Code supports extra skill roots via CLI (`--add-dir <path>`).
- Skills are recursively discovered under configured roots.

### 4.4 Discovery Behavior

- Skills are auto-loaded from configured paths.
- Changes are typically reflected without full reinstall; restart if runtime cache appears stale.

## 5. Minimal Portable `SKILL.md` Template

```markdown
---
name: your-skill-name
description: One-line trigger-focused description of when and why to use this skill.
---

# Skill Title

## When to use
- ...

## Inputs
- ...

## Steps
1. ...
2. ...

## Validation
- ...

## Output
- ...
```

## 6. Installation Checklist (Pass/Fail)

1. Directory contains `SKILL.md`.
2. Frontmatter includes `name` and `description`.
3. Skill placed in a valid scope path for target tool.
4. Tool can discover and invoke the skill.
5. Any required scripts/resources are relative, packaged, and distributable.

## 7. Distribution Rules

- Do not rely on machine-local absolute paths.
- Use repository-relative paths or remote URLs.
- Pin external references to stable tags/commits when reproducibility matters.

## 8. References

- OpenAI Codex skills docs: https://developers.openai.com/codex/skills
- OpenAI skills repository: https://github.com/openai/skills
- Claude Code skills docs: https://code.claude.com/docs/en/skills
- Anthropic agent skills docs: https://docs.claude.com/en/docs/agents-and-tools/agent-skills
- Agent Skills specification: https://agentskills.io/specification
- Agent Skills LLM-optimized spec: https://agentskills.io/specification.md
