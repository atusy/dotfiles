#!/usr/bin/env sh
set -eu

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_absent() {
  path=$1
  [ ! -e "$path" ] || fail "expected $path to be migrated away"
}

assert_contains() {
  path=$1
  text=$2
  grep -F "$text" "$path" >/dev/null || fail "expected $path to contain: $text"
}

assert_absent dot_claude/commands/tdd/red.md
assert_absent dot_claude/commands/tdd/green.md
assert_absent dot_claude/commands/tdd/refactor.md
assert_absent dot_claude/commands/tidy/first.md
assert_absent dot_claude/commands/tidy/after.md
assert_absent dot_claude/commands/tidy/later.md
assert_absent dot_claude/commands/git/commit.md

assert_contains dot_claude/skills/tdd/SKILL.md "Write ONE small failing test"
assert_contains dot_claude/skills/tdd/SKILL.md "Make minimal behavioral change"
assert_contains dot_claude/skills/tdd/SKILL.md "Improve structure without changing behavior"
assert_contains dot_claude/skills/tidying/SKILL.md "Tidy First"
assert_contains dot_claude/skills/tidying/SKILL.md "Tidy After"
assert_contains dot_claude/skills/tidying/SKILL.md "Tidy Later"
assert_contains dot_claude/skills/git-commit/SKILL.md "Conventional Commits"
assert_contains dot_claude/skills/git-commit/SKILL.md "Commit log describes WHY"
