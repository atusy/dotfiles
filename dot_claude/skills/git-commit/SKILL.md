---
name: git-commit
description: Stage meaningful diffs and create Conventional Commits with WHY-focused messages. Use whenever making git commits, grouping changes, choosing commit types, or separating structural and behavioral work.
---

# INSTRUCTIONS

Create small, cohesive commits that explain why the change exists.

## Commit Discipline

- Only commit when:
  1. ALL tests are passing
  2. ALL compiler/linter warnings have been resolved
  3. The change represents a single logical unit of work
  4. Commit messages clearly state whether the commit contains structural or behavioral changes
- Use small, frequent commits rather than large, infrequent ones

## Workflow

1. Inspect context:
   - `git status --short`
   - `git diff --stat`
   - `git diff --cached --stat`
   - `git log --oneline -10`
2. Review detailed diffs for files being considered.
3. Identify logical groups. Keep unrelated changes in separate commits.
4. Stage intentionally with `git add <file>` or `git add -p <file>`.
5. Verify staged content with `git diff --cached`.
6. Choose the commit type from the staged diff.
7. Commit with a message whose body explains WHY.

## Conventional Commits

Use Conventional Commits 1.0.0:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Common types:

- `fix:` bug fix
- `feat:` user-visible feature
- `build:` build system or dependency change
- `chore:` maintenance without production-code behavior
- `ci:` CI configuration
- `docs:` documentation only
- `style:` formatting or whitespace only
- `refactor:` structural change without behavior change
- `perf:` performance improvement
- `test:` adding or correcting tests

Use `feat!:` or `fix!:` for breaking changes. If behavior changes, do not label
the commit as `refactor:`, `style:`, `docs:`, or `chore:`.

## WHY-Focused Messages

Follow t-wada's division of responsibility:

- Code describes HOW
- Tests describe WHAT happens
- Commit log describes WHY
- Code comments describe WHY NOT

The body should explain motivation and reasoning instead of repeating the diff:

- What problem does this solve?
- Why is this change needed now?
- Why this approach over plausible alternatives?

Keep the subject imperative and concise, ideally under 50 characters.
