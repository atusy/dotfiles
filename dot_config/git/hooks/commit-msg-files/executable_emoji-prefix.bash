#!/usr/bin/env bash
set -euo pipefail


# Check dependencies
if test ! $(command -v fzf)
then
  echo "fzf is required by $0" 1>&2
fi

readonly GREP="$( command -v ggrep || command -v grep )"
if "$GREP" --version | "$GREP" -qF "BSD"
then
  echo "ERROR: BSD grep is not supported by $0. Install GNU grep." 1>&2
  exit 1
fi


# CONSTANTS
readonly GIT_ROOT="$( git rev-parse --show-toplevel )"
readonly GIT_COMMIT_TEMPLATE="$(
  TEMPLATE="$( git config commit.template )"
  if [[ -z "$TEMPLATE" ]]
  then
    echo "${GIT_ROOT}/.gitmessage"
  else
    cd "$GIT_ROOT"
    realpath "$TEMPLATE"
  fi
)"
readonly EMOJI_RE="(:[a-zA-Z0-9]+:|[\x{1f300}-\x{1f5ff}\x{1f900}-\x{1f9ff}\x{1f600}-\x{1f64f}\x{1f680}-\x{1f6ff}\x{2600}-\x{26ff}\x{2700}-\x{27bf}\x{1f1e6}-\x{1f1ff}\x{1f191}-\x{1f251}\x{1f004}\x{1f0cf}\x{1f170}-\x{1f171}\x{1f17e}-\x{1f17f}\x{1f18e}\x{3030}\x{2b50}\x{2b55}\x{2934}-\x{2935}\x{2b05}-\x{2b07}\x{2b1b}-\x{2b1c}\x{3297}\x{3299}\x{303d}\x{00a9}\x{00ae}\x{2122}\x{23f3}\x{24c2}\x{23e9}-\x{23ef}\x{25b6}\x{23f8}-\x{23fa}])"
readonly EMOJI_CHOICE="$(
  if [[ ! -z "$GIT_COMMIT_TEMPLATE" ]]
  then
    "$GREP" -P "$EMOJI_RE" -- "$GIT_COMMIT_TEMPLATE"
  fi
)"


# Skip if emoji is not required
if [[ -z "$EMOJI_CHOICE" ]]
then
  exit 0
fi


# Skip if emoji is satisfied
# TODO: Actually requires valid emoji from $EMOJI_CHOICE
if head -n 1 -- "$1" | "$GREP" -Pq "^$EMOJI_RE"; then
  exit 0
fi


# Select emoji and preprend to commit message
readonly EMOJI="$(
  echo -e "${EMOJI_CHOICE}\n:SKIP:" \
    | fzf --prompt="Select an emoji prefix > "\
    | "$GREP" -Po "$EMOJI_RE" | head -n 1
)"

if [[ -z "$EMOJI" ]]
then
  exit 1
fi

if [[ ! "$EMOJI" == ":SKIP:" ]]
then
  echo -e "$EMOJI $1" > "$1"
fi
