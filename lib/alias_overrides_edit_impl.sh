# shellcheck shell=bash

_alias_self_edit_target_help_file() {
  local target_file="$1"
  REPLY="${target_file}.md"
}

_alias_self_edit_ensure_help_file() {
  local help_file="$1"

  [ -f "${help_file}" ] && return 0

  {
    printf '# Eigene Alias-Hilfe\n'
    printf '\n'
    printf '## Alias-Hilfe (de)\n'
    printf '| alias | kurzbeschreibung | beschreibung | befehl |\n'
    printf '|---|---|---|---|\n'
  } >> "${help_file}" || return 1
}

_alias_self_edit_append_help_entry() {
  local help_file="$1"
  local alias_name="$2"
  local alias_desc="$3"
  local alias_cmd="$4"
  local short_text=""
  local desc_text=""
  local cmd_text=""

  short_text="${alias_desc//|/\\|}"
  desc_text="${alias_desc//|/\\|}"
  cmd_text="${alias_cmd//|/\\|}"

  if grep -Eq "^[[:space:]]*\\|[[:space:]]*${alias_name}[[:space:]]*\\|" "${help_file}"; then
    echo "Fehler: Hilfetext fuer '${alias_name}' ist in ${help_file} bereits vorhanden."
    echo "Bitte Eintrag dort manuell anpassen."
    return 1
  fi

  printf '| %s | %s | %s | %s |\n' "${alias_name}" "${short_text}" "${desc_text}" "${cmd_text}" >> "${help_file}" || return 1
}

_alias_self_edit_resolve_target_file() {
  local home_file="${HOME}/.bash_aliases_specific"
  local repo_file=""
  local choice=""

  if [ "$(id -u)" -ne 0 ]; then
    REPLY="${home_file}"
    return 0
  fi

  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "Fehler: BASH_ALIAS_REPO_DIR ist nicht gesetzt."
    return 1
  fi
  repo_file="${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific"

  echo ""
  echo "_self_edit: Ziel-Datei wählen"
  echo "  1) ${home_file} (root-eigen)"
  echo "  2) ${repo_file} (projektweit)"
  printf 'Auswahl [1/2, Enter=1]: '
  IFS= read -r choice

  case "${choice}" in
    ""|1) REPLY="${home_file}" ;;
    2) REPLY="${repo_file}" ;;
    *)
      echo "Ungueltige Auswahl."
      return 1
      ;;
  esac
}

alias_self_edit() {
  local target_file=""
  local help_file=""
  local alias_name=""
  local alias_desc=""
  local alias_cmd=""
  local escaped_cmd=""

  _alias_self_edit_resolve_target_file || return 1
  target_file="${REPLY}"

  echo ""
  echo "=== Alias-Assistent ==="

  while true; do
    printf 'Alias-Name: '
    IFS= read -r alias_name
    if [ -z "${alias_name}" ]; then
      echo "Alias-Name darf nicht leer sein."
      continue
    fi
    if [[ ! "${alias_name}" =~ ^[^[:space:]=]+$ ]]; then
      echo "Alias-Name darf keine Leerzeichen oder '=' enthalten."
      continue
    fi
    break
  done

  printf 'Beschreibung: '
  IFS= read -r alias_desc
  [ -z "${alias_desc}" ] && alias_desc="(ohne Beschreibung)"

  while true; do
    printf 'Befehl fuer %s: ' "${alias_name}"
    IFS= read -r alias_cmd
    if [ -z "${alias_cmd}" ]; then
      echo "Befehl darf nicht leer sein."
      continue
    fi
    break
  done

  if [ -f "${target_file}" ] && grep -Eq "^alias[[:space:]]+${alias_name}=" "${target_file}"; then
    echo "Fehler: Alias '${alias_name}' ist in ${target_file} bereits vorhanden."
    echo "Bitte Datei manuell anpassen oder anderen Alias-Namen verwenden."
    return 1
  fi

  _alias_self_edit_target_help_file "${target_file}"
  help_file="${REPLY}"

  _alias_self_edit_ensure_help_file "${help_file}" || {
    echo "Fehler: Konnte ${help_file} nicht anlegen."
    return 1
  }

  escaped_cmd="$(printf '%q' "${alias_cmd}")"
  {
    printf '\n# Alias: %s\n' "${alias_name}"
    printf '# Beschreibung: %s\n' "${alias_desc}"
    printf 'alias %s=%s\n' "${alias_name}" "${escaped_cmd}"
  } >> "${target_file}" || {
    echo "Fehler: Konnte ${target_file} nicht schreiben."
    return 1
  }

  _alias_self_edit_append_help_entry "${help_file}" "${alias_name}" "${alias_desc}" "${alias_cmd}" || return 1

  echo "Alias '${alias_name}' wurde in ${target_file} gespeichert."
  echo "Hilfetext wurde in ${help_file} gespeichert."

  if declare -F alias_repo_reload >/dev/null 2>&1; then
    alias_repo_reload || return 1
  elif [ -f "${HOME}/.bashrc" ]; then
    # shellcheck disable=SC1090
    source "${HOME}/.bashrc" || return 1
  fi

  echo "Reload abgeschlossen."
}

alias _self_edit='alias_self_edit'
