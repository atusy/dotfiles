---
paths: "**/{.,dot_}claude/**"
---

# Claude Code Configuration Maintenance Guide

When creating or modifying Claude Code configuration files, follow these context-optimization principles.

## Configuration Selection Framework

Choose configuration type based on **when context should load** and **how context should be shared**:

| Type        | Trigger      | Context |
|-------------|--------------|---------|
| `CLAUDE.md` | Startup      | Shared, always loaded |
| `rules/`    | Startup/Path | Shared, lazy if paths specified |
| `commands/` | User         | Shared, on invocation |
| `skills/`   | Auto         | Shared, description only until triggered |
| `agents/`   | Auto/User    | Isolated, returns results only |

## Anti-Patterns to Avoid

1. **Context bloat in CLAUDE.md**: Move task-specific procedures to slash commands
2. **Duplicated content**: If skill and command overlap, have skill invoke the command
3. **Shared rules in multiple agents**: Extract to CLAUDE.md (always-needed) or skill (conditional)
4. **Heavyweight tasks in main context**: Use subagent when trial-and-error would pollute context
5. **User-level path rules leaking**: Path-filtered rules at user level may apply unintentionally (e.g., `*.ts` frontend rules activating in CLI projects)—prefer skills/commands for user-level task-specific guidance

## Best Practices Examples

### Skills + Commands Integration Pattern

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

### Path-specific Rules

To lazy load rules that should only apply to certain file paths.
Use glob patterns to specify paths:

```yaml
---
paths: "{src,lib}/**/*.ts, tests/**/*.test.ts"
---
```

## Refactoring Checklist

When reviewing configurations:

- [ ] Is CLAUDE.md content truly always-needed? Move conditional content elsewhere
- [ ] Are there duplications between skills and commands? Consolidate
- [ ] Would a subagent's isolated context benefit this task?
- [ ] Is the skill description specific enough for auto-discovery?
- [ ] Are commands self-contained without requiring other context?
- [ ] Are user-level path rules leaking into unintended project types?
