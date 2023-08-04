#!/bin/bash

if [[ -n "$2" ]] && [[ "$2" != "template" ]]; then
  exit 0
fi

TEMPLATE="$(git config commit.template)"
CLEANUP="$(git config commit.cleanup)"
PREFIX="$( [[ "$CLEANUP" == "scissors" ]] && echo ";" || echo "#" )"

{
  echo ""
  echo ""
  if [[ -n "$TEMPLATE" ]]; then
    echo "# ------------------------ >8 ------------------------"
    if [[ "$CLEANUP" == "scissors" ]]; then
      grep -v '^$' "$TEMPLATE" | sed -e "s/^#/${PREFIX}/"
    else
      grep -v '^$' "$TEMPLATE"
    fi
  fi
  echo "# ------------------------ >8 ------------------------"
  git status | sed -e "s/^/${PREFIX} /"
  echo "# ------------------------ >8 ------------------------"
  git log -n 10 --date-order -C -M --format="${PREFIX} * %h <%ad> [%an] %d %s" --date=short
  echo "# ------------------------ >8 ------------------------"
  git diff --staged
} > "$1"
