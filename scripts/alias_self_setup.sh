#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
_loader_path="${_repo_dir}/bash_alias_std.sh"
_category_setup_script="${_repo_dir}/scripts/alias_category_setup.sh"
_alias_setup_marker_start="# >>> bash_alias_std setup >>>"
_alias_setup_marker_end="# <<< bash_alias_std setup <<<"

_alias_setup_block() {
  local loader_path="$1"
  cat <<EOF
${_alias_setup_marker_start}
if [ -f "${loader_path}" ]; then
  source "${loader_path}"
fi
${_alias_setup_marker_end}
EOF
}

_alias_setup_add_to_file() {
  local target_file="$1"
  local loader_path="$2"

  if [ -z "${target_file}" ]; then
    echo "Fehler: Keine Zieldatei angegeben."
    return 1
  fi

  if [ -e "${target_file}" ] && ! [ -w "${target_file}" ]; then
    echo "Fehler: Datei ist nicht schreibbar: ${target_file}"
    return 1
  fi

  if [ -f "${target_file}" ] && grep -Fq "${_alias_setup_marker_start}" "${target_file}"; then
    echo "Bereits eingerichtet in ${target_file} (Marker gefunden)."
    return 0
  fi

  if [ -f "${target_file}" ] && grep -Fq "${loader_path}" "${target_file}"; then
    echo "Bereits eingerichtet in ${target_file} (Loader-Pfad gefunden)."
    return 0
  fi

  {
    echo ""
    _alias_setup_block "${loader_path}"
  } >> "${target_file}"

  echo "Eintrag hinzugefügt: ${target_file}"
}

_alias_setup_has_marker() {
  local target_file="$1"
  [ -f "${target_file}" ] || return 1
  grep -Fq "${_alias_setup_marker_start}" "${target_file}"
}

_alias_setup_detect_alias_file_from_bashrc() {
  local rc_file="$1"
  local match=""

  if [ ! -f "${rc_file}" ]; then
    return 0
  fi

  while IFS= read -r line; do
    case "${line}" in
      \#*|"") continue ;;
    esac

    if [[ "${line}" =~ ^[[:space:]]*(source|\.)[[:space:]]+([^[:space:];]+) ]]; then
      match="${BASH_REMATCH[2]}"
      match="${match/#\~/$HOME}"
      match="${match/#\$HOME/$HOME}"

      case "${match}" in
        */.bash_aliases|*/bash_aliases|*.aliases.sh|*/aliases.sh)
          printf "%s" "${match}"
          return 0
          ;;
      esac
    fi
  done < "${rc_file}"
}

_alias_setup_resolve_user_target() {
  local user_rc="${HOME}/.bashrc"
  local detected_alias_file=""

  detected_alias_file="$(_alias_setup_detect_alias_file_from_bashrc "${user_rc}")"
  if [ -n "${detected_alias_file}" ] && [ "${detected_alias_file}" != "${user_rc}" ]; then
    printf "%s" "${detected_alias_file}"
    return 0
  fi

  printf "%s" "${user_rc}"
}

_alias_setup_find_marker_target() {
  local user_target=""

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ] && _alias_setup_has_marker "/etc/bash.bashrc"; then
    REPLY="/etc/bash.bashrc"
    return 0
  fi

  user_target="$(_alias_setup_resolve_user_target)"
  if [ -n "${user_target}" ] && _alias_setup_has_marker "${user_target}"; then
    REPLY="${user_target}"
    return 0
  fi

  REPLY=""
  return 1
}

_alias_setup_prompt_yes_no() {
  local question="$1"
  local answer=""
  read -r -p "${question} [y/N]: " answer
  case "${answer}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_setup_prompt_choice_root_target() {
  local user_target="$1"
  local answer=""

  echo "Root-Setup Ziel wählen:" >&2
  echo "  1) ${user_target}" >&2
  echo "  2) /etc/bash.bashrc" >&2
  echo "  3) überspringen" >&2
  read -r -p "Auswahl [1/2/3]: " answer

  case "${answer}" in
    1) printf "%s" "${user_target}" ;;
    2) printf "/etc/bash.bashrc" ;;
    *) printf "" ;;
  esac
}

alias_setup() {
  local user_rc="${HOME}/.bashrc"
  local user_target=""
  local final_target=""

  if [ ! -f "${_loader_path}" ]; then
    echo "Fehler: Loader nicht gefunden: ${_loader_path}"
    return 1
  fi

  user_target="$(_alias_setup_resolve_user_target)"
  if [ -z "${user_target}" ]; then
    user_target="${user_rc}"
  fi

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ]; then
    final_target="$(_alias_setup_prompt_choice_root_target "${user_target}")"
    if [ -n "${final_target}" ]; then
      _alias_setup_add_to_file "${final_target}" "${_loader_path}" || return 1
    else
      echo "Root-Setup übersprungen."
    fi
  elif _alias_setup_prompt_yes_no "Setup in ${user_target} eintragen?"; then
    _alias_setup_add_to_file "${user_target}" "${_loader_path}" || return 1
  else
    echo "User-Setup übersprungen."
  fi

  echo "Setup abgeschlossen."
}

_alias_setup_remove_from_file() {
  local target_file="$1"
  local tmp_file=""
  local awk_rc=0

  if [ -z "${target_file}" ] || [ ! -f "${target_file}" ]; then
    echo "Fehler: Datei nicht gefunden: ${target_file}"
    return 1
  fi

  if [ ! -w "${target_file}" ]; then
    echo "Fehler: Datei ist nicht schreibbar: ${target_file}"
    return 1
  fi

  tmp_file="$(mktemp)" || return 1

  awk -v start="${_alias_setup_marker_start}" -v stop="${_alias_setup_marker_end}" '
    BEGIN { in_block=0; removed=0 }
    index($0, start) > 0 { in_block=1; removed=1; next }
    in_block == 1 {
      if (index($0, stop) > 0) {
        in_block=0
      }
      next
    }
    { print }
    END {
      if (in_block == 1) {
        exit 2
      }
      if (removed == 0) {
        exit 3
      }
    }
  ' "${target_file}" > "${tmp_file}" || awk_rc=$?

  case "${awk_rc}" in
    0)
      mv "${tmp_file}" "${target_file}" || {
        rm -f "${tmp_file}"
        return 1
      }
      echo "Marker-Block entfernt: ${target_file}"
      ;;
    2)
      rm -f "${tmp_file}"
      echo "Fehler: Marker-Block unvollständig in ${target_file} (End-Marker fehlt)."
      return 1
      ;;
    3)
      rm -f "${tmp_file}"
      echo "Kein Marker-Block gefunden in ${target_file}."
      return 1
      ;;
    *)
      rm -f "${tmp_file}"
      echo "Fehler: Marker konnte nicht entfernt werden aus ${target_file}."
      return 1
      ;;
  esac
}

alias_setup_remove() {
  local target_file=""
  local user_target=""
  local answer=""

  if _alias_setup_find_marker_target; then
    target_file="${REPLY}"
    _alias_setup_remove_from_file "${target_file}"
    return $?
  fi

  user_target="$(_alias_setup_resolve_user_target)"
  if [ -z "${user_target}" ]; then
    user_target="${HOME}/.bashrc"
  fi

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ]; then
    echo "Kein Marker gefunden."
    echo "Entfernung aus Datei wählen:"
    echo "  1) /etc/bash.bashrc"
    echo "  2) ${user_target}"
    echo "  3) Abbrechen"
    read -r -p "Auswahl [1/2/3]: " answer
    case "${answer}" in
      1) _alias_setup_remove_from_file "/etc/bash.bashrc" ;;
      2) _alias_setup_remove_from_file "${user_target}" ;;
      *) echo "Abgebrochen."; return 1 ;;
    esac
  else
    _alias_setup_remove_from_file "${user_target}"
  fi
}

_alias_setup_run_category_setup() {
  if [ -f "${_category_setup_script}" ]; then
    bash "${_category_setup_script}"
  else
    echo "Fehler: scripts/alias_category_setup.sh nicht gefunden."
    return 1
  fi
}

alias_self_setup() {
  echo "Starte Kategorie-Auswahl."
  _alias_setup_run_category_setup
}

alias_init() {
  alias_setup
}

_main() {
  case "${1:-}" in
    --remove|remove|rm)
      alias_setup_remove
      ;;
    --setup|setup|install|--init|init)
      alias_init
      ;;
    --category|category)
      alias_self_setup
      ;;
    ""|--run|run)
      alias_self_setup
      ;;
    *)
      echo "Verwendung: $0 [run|category|init|setup|install|remove]"
      return 1
      ;;
  esac
}

_main "${1:-}"
