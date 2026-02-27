# Standardized Skill Specification

This document defines the standard format for skills in this repository, based on:

- Agent Skills specification: https://agentskills.io/specification
- Agent Skills specification (LLM-optimized page): https://agentskills.io/specification.md
- Agent Skills LLM index: https://agentskills.io/llms.txt
- Agent Skills LLM full docs: https://agentskills.io/llms-full.txt
- Anthropic PDF skill reference: https://github.com/anthropics/skills/tree/main/skills/pdf

## 0. Canonical source policy

- Treat `https://agentskills.io/specification` as the source of truth.
- Prefer `https://agentskills.io/specification.md` for LLM-friendly parsing of the same page.
- Use `https://agentskills.io/llms-full.txt` for machine-friendly retrieval/parsing.
- If this document conflicts with the live spec, follow the live spec.

## 1. Required directory layout

Each skill must live in its own directory and include `SKILL.md`:

```text
<skill-name>/
|- SKILL.md            # required
|- LICENSE.txt         # recommended when license text is bundled
|- reference.md        # optional long-form reference
|- forms.md            # optional, for form-centric workflows
|- patterns.md         # optional reusable patterns
`- scripts/            # optional executable helpers
```

## 2. `SKILL.md` frontmatter requirements

`SKILL.md` must begin with YAML frontmatter followed by Markdown instructions.

Required fields:

- `name`
- `description`

Optional fields:

- `license`
- `compatibility`
- `metadata`
- `allowed-tools` (experimental)

Canonical field summary:

| Field | Required | Constraints |
| --- | --- | --- |
| `name` | Yes | Max 64 chars. Lowercase letters/numbers/hyphens. Must not start/end with hyphen. |
| `description` | Yes | Max 1024 chars. Non-empty. Must say what and when to use. |
| `license` | No | License name or reference to bundled license file. |
| `compatibility` | No | Max 500 chars. Environment requirements only. |
| `metadata` | No | Key/value map for extra metadata. |
| `allowed-tools` | No | Space-delimited tool allowlist. Experimental support. |

Constraints:

- `name`: 1-64 chars; unicode lowercase alphanumeric and hyphens; cannot start/end with `-`; cannot contain `--`; must match the parent directory name.
- `description`: 1-1024 chars; must say what the skill does and when to use it; include trigger keywords for activation.
- `compatibility` (if present): 1-500 chars; use only for explicit environment requirements.
- `metadata` (if present): key/value map for additional fields.
- `allowed-tools` (if present): space-delimited pre-approved tool list.

`name` examples:

- valid: `pdf-processing`
- valid: `code-review`
- invalid: `PDF-Processing` (uppercase)
- invalid: `-pdf` (starts with hyphen)
- invalid: `pdf--processing` (consecutive hyphens)

`description` quality bar:

- good: includes capabilities + activation context
- poor: vague one-liners like "Helps with PDFs."

`compatibility` guidance:

- include only when there are strict runtime constraints
- most skills should omit this field

Frontmatter template:

```yaml
---
name: skill-name
description: Clear description of what this skill does and when to activate it.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Optional runtime/tooling requirements
metadata:
  owner: team-name
  version: "1.0"
allowed-tools: Bash(git:*) Bash(jq:*) Read
---
```

## 3. Standard `SKILL.md` body structure

Use this section order unless the domain needs a different shape:

1. `# <Skill Name>`
2. `## Overview`
3. `## Operating Rules`
4. `## Quick Start` (minimal examples)
5. `## Core Workflows` (task-by-task procedures)
6. `## Tooling / Commands`
7. `## Edge Cases and Failure Handling`
8. `## Next Steps / Related Files`

Body rules:

- Keep core instructions concise and procedural.
- Put heavy detail in `reference.md`/other referenced files.
- Prefer concrete commands and runnable snippets over abstract guidance.
- Explicitly call out safety and correctness constraints for risky actions.
- Include examples of inputs/outputs and common edge cases.

## 4. Progressive disclosure standard

- Metadata (`name` + `description`) should stay concise; typical startup budget is ~100 tokens per skill.
- Keep active instructions under ~5000 tokens where possible.
- Keep `SKILL.md` under 500 lines where possible.
- Keep frequently needed guidance in `SKILL.md`.
- Move deep references to separate files that are loaded on demand.
- Use shallow relative links from `SKILL.md` (for example `reference.md`, `scripts/run.sh`).

## 5. Repository conventions

- Use `LICENSE.txt` when license terms are included in the skill directory.
- Include `compatibility` when a skill depends on pinned versions or special runtime constraints.
- Use lowercase file names for companion docs (`reference.md`, `forms.md`, `patterns.md`) for consistency with existing skills.
- Keep scripts in `scripts/` and make expected dependencies explicit in comments or file headers.
- If using a `references/` directory, keep referenced docs focused and avoid deep dependency chains.

## 6. File reference rules

- Use relative paths from the skill root.
- Keep references one level deep from `SKILL.md` when possible.
- Avoid deeply nested "reference file points to reference file" chains.

Example:

```markdown
See [the reference guide](references/REFERENCE.md) for details.

Run the extraction script:
scripts/extract.py
```

## 7. Validation

Validate every skill directory before publishing:

```bash
skills-ref validate ./my-skill
```

Reference implementation:

- https://github.com/agentskills/agentskills/tree/main/skills-ref

## 8. Copy/paste starter

````markdown
---
name: my-skill-name
description: What this skill does and when to use it.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Optional requirements
---

# My Skill Name

## Overview
- Scope:
- When to use:

## Operating Rules
- Rule 1
- Rule 2

## Quick Start
```bash
# example command
```

## Core Workflows
### Workflow 1
1. Step 1
2. Step 2

## Edge Cases and Failure Handling
- Case:
- Mitigation:

## Next Steps / Related Files
- See `reference.md`
- See `scripts/`
````
