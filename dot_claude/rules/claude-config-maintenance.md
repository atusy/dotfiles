---
paths: "**/{.,dot_}claude/**"
---

# Claude Code Configuration Maintenance Guide

When creating or modifying Claude Code configuration files, follow these context-optimization principles.

## Configuration Selection Framework

Choose configuration type based on **when context should load** and **how context should be shared**:

| Need | Configuration | Reason |
|------|---------------|--------|
| Always-needed, project-agnostic | `CLAUDE.md` | Loaded at startup |
| Always-needed, path-filtered | `rules/` | Delays loading until path match |
| User-triggered actions | `commands/` | Zero context until `/command` invoked |
| Auto-triggered, shared context | `skills/` | Only description loaded initially |
| Auto-triggered, isolated context | `agents/` | Independent context, returns results only |

## Anti-Patterns to Avoid

1. **Context bloat in CLAUDE.md**: Move task-specific procedures to slash commands
2. **Duplicated content**: If skill and command overlap, have skill invoke the command
3. **Shared rules in multiple agents**: Extract to CLAUDE.md (always-needed) or skill (conditional)
4. **Heavyweight tasks in main context**: Use subagent when trial-and-error would pollute context
5. **User-level path rules leaking**: Path-filtered rules at user level may apply unintentionally (e.g., `*.ts` frontend rules activating in CLI projects)—prefer skills/commands for user-level task-specific guidance

## File Structure Standards

### Skills (`skills/{name}/SKILL.md`)

```yaml
---
name: kebab-case-name
description: Third person, what + when + trigger terms. Max 1024 chars.
---
```

- Body under 50 lines; use reference files for details
- Invoke slash commands for reusable procedures

#### Skills + Commands Integration Pattern

For tasks needing both auto-detection AND manual invocation:

```yaml
---
# skills/git-commit/SKILL.md
name: git-commit
description: Stage meaningful diffs and create commits with WHY-focused messages. Use when agent needs to commit code changes.
---

Use `/git:commit` slash command to stage meaningful diffs and create commits with WHY-focused messages.
```

Benefits:
- Auto-triggers when Claude detects commit intent
- Allows explicit `/git:commit` for manual control
- Eliminates duplication between skill and command

### Slash Commands (`commands/{namespace}/{action}.md`)

```yaml
---
description: Brief action description
---
```

- Contain complete, self-contained instructions
- No context loaded until user invokes

### Subagents (`agents/{name}.md`)

```yaml
---
name: descriptive-name
description: Capabilities + when to delegate
tools: [list, of, tools]
---
```

- Use for tasks benefiting from isolated context
- Good for: error investigation, large refactors, exploratory research

### Rules (`rules/{domain}.md`)

```yaml
---
paths:
  - "pattern/**/*.ext"
---
```

- Use for path-specific guidance that should auto-apply
- Content hidden until matching path is accessed

## Refactoring Checklist

When reviewing configurations:

- [ ] Is CLAUDE.md content truly always-needed? Move conditional content elsewhere
- [ ] Are there duplications between skills and commands? Consolidate
- [ ] Would a subagent's isolated context benefit this task?
- [ ] Is the skill description specific enough for auto-discovery?
- [ ] Are commands self-contained without requiring other context?
- [ ] Are user-level path rules leaking into unintended project types?
