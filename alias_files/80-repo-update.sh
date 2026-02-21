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
}

alias_repo_update() {
  local mode="${1:-reload}"

  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "Fehler: BASH_ALIAS_REPO_DIR ist nicht gesetzt."
    return 1
  fi

  if [ ! -d "${BASH_ALIAS_REPO_DIR}/.git" ]; then
    echo "Fehler: Kein Git-Repository gefunden unter ${BASH_ALIAS_REPO_DIR}"
    return 1
  fi

  (
    cd "${BASH_ALIAS_REPO_DIR}" || exit 1
    git pull --ff-only
  ) || return 1

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

alias _self_update='alias_repo_update'
