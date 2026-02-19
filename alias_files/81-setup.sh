# shellcheck shell=bash

_alias_setup_block() {
  local loader_path="$1"
  cat <<EOF
# >>> bash_alias_std setup >>>
if [ -f "${loader_path}" ]; then
  source "${loader_path}"
fi
# <<< bash_alias_std setup <<<
EOF
}

_alias_setup_add_to_file() {
  local target_file="$1"
  local loader_path="$2"
  local marker_start="# >>> bash_alias_std setup >>>"

  if [ -z "${target_file}" ]; then
    echo "Fehler: Keine Zieldatei angegeben."
    return 1
  fi

  if [ -e "${target_file}" ] && ! [ -w "${target_file}" ]; then
    echo "Fehler: Datei ist nicht schreibbar: ${target_file}"
    return 1
  fi

  if [ -f "${target_file}" ] && grep -Fq "${marker_start}" "${target_file}"; then
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

  echo "Eintrag hinzugefuegt: ${target_file}"
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

  echo "Root-Setup Ziel waehlen:" >&2
  echo "  1) ${user_target}" >&2
  echo "  2) /etc/bash.bashrc" >&2
  echo "  3) ueberspringen" >&2
  read -r -p "Auswahl [1/2/3]: " answer

  case "${answer}" in
    1) printf "%s" "${user_target}" ;;
    2) printf "/etc/bash.bashrc" ;;
    *) printf "" ;;
  esac
}

alias_setup() {
  local loader_path="${BASH_ALIAS_REPO_DIR}/bash_alias_std.sh"
  local user_rc="${HOME}/.bashrc"
  local user_target="${user_rc}"
  local final_target=""
  local detected_alias_file=""

  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "Fehler: BASH_ALIAS_REPO_DIR ist nicht gesetzt."
    return 1
  fi

  if [ ! -f "${loader_path}" ]; then
    echo "Fehler: Loader nicht gefunden: ${loader_path}"
    return 1
  fi

  detected_alias_file="$(_alias_setup_detect_alias_file_from_bashrc "${user_rc}")"
  if [ -n "${detected_alias_file}" ] && [ "${detected_alias_file}" != "${user_rc}" ]; then
    if _alias_setup_prompt_yes_no "Alias-Datei erkannt (${detected_alias_file}). Dort eintragen statt in ${user_rc}?"; then
      user_target="${detected_alias_file}"
    fi
  fi

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ]; then
    final_target="$(_alias_setup_prompt_choice_root_target "${user_target}")"
    if [ -n "${final_target}" ]; then
      _alias_setup_add_to_file "${final_target}" "${loader_path}" || return 1
    else
      echo "Root-Setup uebersprungen."
    fi
  elif _alias_setup_prompt_yes_no "Setup in ${user_target} eintragen?"; then
    _alias_setup_add_to_file "${user_target}" "${loader_path}" || return 1
  else
    echo "User-Setup uebersprungen."
  fi

  echo "Setup abgeschlossen."
}

alias _self_setup='alias_setup'
