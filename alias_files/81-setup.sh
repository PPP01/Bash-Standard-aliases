# shellcheck shell=bash

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/scripts/alias_category_setup.sh" ]; then
  alias _self_setup='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_category_setup.sh"'
else
  alias _self_setup='echo "Fehler: scripts/alias_category_setup.sh nicht gefunden."'
fi