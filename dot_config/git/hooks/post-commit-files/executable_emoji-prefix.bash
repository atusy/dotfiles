#!/bin/env bash
set -euo pipefail

readonly GIT_ROOT="$( git rev-parse --show-toplevel )"
readonly GIT_MESSAGE="${GIT_MESSAGE:-${GIT_ROOT}/.gitmessage}"

if [[ ! -f "$GIT_MESSAGE" ]]; then exit 0; fi

readonly GIT_COMMIT_TITLE="$( git log -n 1 --format=format:"%s" )"
readonly REGEX_EMOJI="(:[a-zA-Z0-9]+:|[\x{1f300}-\x{1f5ff}\x{1f900}-\x{1f9ff}\x{1f600}-\x{1f64f}\x{1f680}-\x{1f6ff}\x{2600}-\x{26ff}\x{2700}-\x{27bf}\x{1f1e6}-\x{1f1ff}\x{1f191}-\x{1f251}\x{1f004}\x{1f0cf}\x{1f170}-\x{1f171}\x{1f17e}-\x{1f17f}\x{1f18e}\x{3030}\x{2b50}\x{2b55}\x{2934}-\x{2935}\x{2b05}-\x{2b07}\x{2b1b}-\x{2b1c}\x{3297}\x{3299}\x{303d}\x{00a9}\x{00ae}\x{2122}\x{23f3}\x{24c2}\x{23e9}-\x{23ef}\x{25b6}\x{23f8}-\x{23fa}])"

if echo "$GIT_COMMIT_TITLE" | grep -Pq "^$REGEX_EMOJI"; then
  exit 0
fi

readonly EMOJI="$(
  (
    grep -P "$REGEX_EMOJI" -- "$GIT_MESSAGE"
    echo "SKIP"
  ) | fzf | grep -Po "$REGEX_EMOJI" | head -n 1
)"

if [[ -z "$EMOJI" ]]
then
  exit 1
fi

if [[ ! "$EMOJI" == "SKIP" ]]
then
  echo -e "$EMOJI $( git log -n 1 --format=format:"%B")" | git commit --amend --file=-
fi
