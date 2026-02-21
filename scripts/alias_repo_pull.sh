#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

repo_dir="${1:-${BASH_ALIAS_REPO_DIR:-}}"

if [ -z "${repo_dir}" ]; then
  echo "Fehler: Repo-Pfad fehlt (Argument 1 oder BASH_ALIAS_REPO_DIR)." >&2
  exit 1
fi

if [ ! -d "${repo_dir}/.git" ]; then
  echo "Fehler: Kein Git-Repository gefunden unter ${repo_dir}" >&2
  exit 1
fi

cd "${repo_dir}"
git pull --ff-only