# shellcheck shell=bash

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/scripts/alias_self_setup.sh" ]; then
  alias _self_setup='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_self_setup.sh"'
  alias _self_setup_remove='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_self_setup.sh" --remove'
else
  alias _self_setup='echo "Fehler: scripts/alias_self_setup.sh nicht gefunden."'
  alias _self_setup_remove='echo "Fehler: scripts/alias_self_setup.sh nicht gefunden."'
fi

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/scripts/alias_category_setup.sh" ]; then
  alias _self_category_setup='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_category_setup.sh"'
else
  alias _self_category_setup='echo "Fehler: scripts/alias_category_setup.sh nicht gefunden."'
fi
