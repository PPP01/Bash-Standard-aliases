#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"

repo_dir="${1:-${BASH_ALIAS_REPO_DIR:-}}"

if [ -z "${repo_dir}" ]; then
  echo "$(_alias_i18n_pick "Fehler: Repo-Pfad fehlt (Argument 1 oder BASH_ALIAS_REPO_DIR)." "Error: Repository path missing (arg 1 or BASH_ALIAS_REPO_DIR).")" >&2
  exit 1
fi

if [ ! -d "${repo_dir}/.git" ]; then
  printf '%s\n' "$(_alias_i18n_pick "Fehler: Kein Git-Repository gefunden unter ${repo_dir}" "Error: No Git repository found at ${repo_dir}")" >&2
  exit 1
fi

cd "${repo_dir}"
git pull --ff-only
