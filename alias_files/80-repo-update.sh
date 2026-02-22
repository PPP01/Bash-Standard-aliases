# shellcheck shell=bash

alias_repo_reload() {
  local loader_path=""

  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "Fehler: BASH_ALIAS_REPO_DIR ist nicht gesetzt."
    return 1
  fi

  loader_path="${BASH_ALIAS_REPO_DIR}/bash_alias_std.sh"
  if [ ! -f "${loader_path}" ]; then
    echo "Fehler: Loader nicht gefunden: ${loader_path}"
    return 1
  fi

  # Guard loesen, damit der Loader in derselben Session erneut geladen wird.
  unset BASH_ALIAS_STD_LOADED
  # shellcheck disable=SC1090
  source "${loader_path}" || return 1

  if declare -F alias_help_warm_cache >/dev/null 2>&1; then
    if ! alias_help_warm_cache >/dev/null 2>&1; then
      echo "Hinweis: Menue-Cache konnte beim Reload nicht vorab aufgebaut werden." >&2
    fi
  fi
}

alias_repo_update() {
  local mode="${1:-reload}"
  local pull_script=""

  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "Fehler: BASH_ALIAS_REPO_DIR ist nicht gesetzt."
    return 1
  fi

  pull_script="${BASH_ALIAS_REPO_DIR}/scripts/alias_repo_pull.sh"
  if [ ! -f "${pull_script}" ]; then
    echo "Fehler: Script nicht gefunden: ${pull_script}"
    return 1
  fi

  bash "${pull_script}" "${BASH_ALIAS_REPO_DIR}" || return 1

  case "${mode}" in
    --restart)
      echo "Update ok. Starte Login-Shell neu..."
      exec "${SHELL:-/bin/bash}" -l
      ;;
    ""|reload|--reload)
      alias_repo_reload || return 1
      echo "Update und Reload abgeschlossen."
      ;;
    *)
      echo "Usage: _self_update [--reload|--restart]"
      return 2
      ;;
  esac
}

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -w "${BASH_ALIAS_REPO_DIR}" ]; then
  alias _self_update='alias_repo_update'
else
  unalias _self_update 2>/dev/null || true
fi
