# shellcheck shell=bash

alias_repo_update() {
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
  )
}

alias alias_update='alias_repo_update'
