# shellcheck shell=bash

_alias_repo_writable=0
if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -w "${BASH_ALIAS_REPO_DIR}" ]; then
  _alias_repo_writable=1
fi

if [ "${_alias_repo_writable}" -eq 1 ] && [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/scripts/alias_self_setup.sh" ]; then
  alias _alias_init='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_self_setup.sh" --init'
  alias _alias_setup_remove='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_self_setup.sh" --remove'
elif [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/scripts/alias_self_setup.sh" ]; then
  unalias _alias_init 2>/dev/null || true
  unalias _alias_setup_remove 2>/dev/null || true
else
  alias _alias_init='echo "Fehler: scripts/alias_self_setup.sh nicht gefunden."'
  alias _alias_setup_remove='echo "Fehler: scripts/alias_self_setup.sh nicht gefunden."'
fi

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/scripts/alias_category_setup.sh" ]; then
  alias _alias_setup='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_category_setup.sh"'
  alias _alias_category_setup='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_category_setup.sh"'
else
  alias _alias_setup='echo "Fehler: scripts/alias_category_setup.sh nicht gefunden."'
  alias _alias_category_setup='echo "Fehler: scripts/alias_category_setup.sh nicht gefunden."'
fi

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/scripts/alias_color_scheme_setup.sh" ]; then
  alias _alias_setup_scheme='bash "${BASH_ALIAS_REPO_DIR}/scripts/alias_color_scheme_setup.sh"'
else
  alias _alias_setup_scheme='echo "Fehler: scripts/alias_color_scheme_setup.sh nicht gefunden."'
fi

unset _alias_repo_writable
