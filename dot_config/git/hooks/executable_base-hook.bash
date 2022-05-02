#!/bin/env bash
set -euo pipefail
readonly HOOKDIR="$( cd "$( dirname "$0" )" && pwd )"
readonly HOOKNAME="$1"
shift 1


# Skip if requested by ENV var (e.g., SKIP_POST_COMMIT=1)
SKIP_VARNAME="$(
  echo "SKIP_${HOOKNAME^^}" | sed -e 's/-/_/g'
)"
SKIP_HOOK="$(
  eval "echo \"\${${SKIP_VARNAME}:-0}\""
)"
if [[ $SKIP_HOOK -eq 1 ]]
then
  exit 0
fi


# Run hooks but without recursing git hooks
function nonrecursive() {
  eval "${SKIP_VARNAME}=1" "$@"
}


## Run global hooks
if [[ -d "${HOOKDIR}/${HOOKNAME}-files" ]]
then
  command find "${HOOKDIR}/${HOOKNAME}-files" -type f -name '*.bash' \
    | while read -r fname
  do
    if [[ -x "${fname}" ]]
    then
      echo "${HOOKNAME}: $fname" 1>&2
      nonrecursive "${fname}" "$@"
    fi
  done
fi


## Run local hooks
readonly GIT_DIR="$( git rev-parse --git-common-dir )"
readonly LOCAL_HOOK="${GIT_DIR}/.git/hooks/${HOOKNAME}"
if [[ -x "${LOCAL_HOOK}" ]]
then
  echo "${HOOKNAME}: ${LOCAL_HOOK}" 1>&2
  nonrecursive "${LOCAL_HOOK}" "$@"
fi

