#!/usr/bin/env bash
set -euo pipefail
readonly HOOKDIR="$( cd "$( dirname "$0" )" && pwd )"
readonly HOOKNAME="$1"
shift 1

readonly GIT_HOOK_VERBOSE="${GIT_HOOK_VERBOSE:-0}"
readonly SKIP_GIT_HOOKS="${SKIP_GIT_HOOKS:-0}"
readonly SKIP_VARNAME="$(
  echo "SKIP_${HOOKNAME^^}" | sed -e 's/-/_/g'
)"

# Skip if requested by ENV var (e.g., SKIP_POST_COMMIT=1)
if [[ "$SKIP_GIT_HOOKS" -eq 1 ]] \
  || [[ "$( eval "echo \"\${${SKIP_VARNAME}:-0}\"" )" -eq 1 ]]
then
  exit 0
fi


# Functions
function hook() {
  # verbose message
  if [[ $GIT_HOOK_VERBOSE -eq 1 ]]
  then
    echo "${HOOKNAME}: ${1}" 1>&2
  fi

  # evaluate executable hook without recursing
  if [[ -x "$1" ]]
  then
    eval "${SKIP_VARNAME}=1" "$@"
  fi
}


## Run global hooks
if [[ -d "${HOOKDIR}/${HOOKNAME}-files" ]]
then
  command find "${HOOKDIR}/${HOOKNAME}-files" -type f -name '*.bash' \
    | while read -r fname
  do
    hook "${fname}" "$@"
  done
fi


## Run local hooks
hook "$( git rev-parse --git-common-dir )/.git/hooks/${HOOKNAME}" "$@"

