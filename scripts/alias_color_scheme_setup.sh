#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"

_user_settings_dir="${HOME}/.config/bash-standard-aliases"
_user_settings_file="${_user_settings_dir}/settings.conf"
_scheme_block_start="# >>> _alias_setup_scheme managed >>>"
_scheme_block_end="# <<< _alias_setup_scheme managed <<<"
_override_block_start="# >>> _alias_setup_scheme user-overrides >>>"
_override_block_end="# <<< _alias_setup_scheme user-overrides <<<"

_text() {
  local key="$1"
  case "${key}" in
    err_mkdir) _alias_i18n_pick "Fehler: Konnte Verzeichnis nicht erstellen: %s" "Error: Could not create directory: %s" ;;
    err_not_writable) _alias_i18n_pick "Fehler: Datei ist nicht schreibbar: %s" "Error: File is not writable: %s" ;;
    err_create_file) _alias_i18n_pick "Fehler: Konnte Datei nicht erzeugen: %s" "Error: Could not create file: %s" ;;
    header_delta) _alias_i18n_pick "# User-Delta-Settings für bash-standard-aliases" "# User delta settings for bash-standard-aliases" ;;
    header_delta_hint) _alias_i18n_pick "# Nur Abweichungen von settings.conf / settings.local.conf" "# Store only deviations from settings.conf / settings.local.conf" ;;
    err_unknown_scheme) _alias_i18n_pick "Fehler: Unbekanntes Schema '%s'. Erlaubt: dark, bright" "Error: Unknown scheme '%s'. Allowed: dark, bright" ;;
    managed_comment) _alias_i18n_pick "# Von _alias_setup_scheme verwaltet." "# Managed by _alias_setup_scheme." ;;
    override_comment_1) _alias_i18n_pick "# Eigene Farb-Overrides. Diese Werte setzen sich immer gegen das Schema durch." "# Custom color overrides. These values always override the selected scheme." ;;
    override_comment_2) _alias_i18n_pick "# Zum Aktivieren '#' entfernen und Wert anpassen." "# To activate, remove '#' and adjust the value." ;;
    menu_title) _alias_i18n_pick "Farbschema auswählen (Speicherort: %s)" "Choose color scheme (target: %s)" ;;
    menu_current) _alias_i18n_pick "Aktuell: %s" "Current: %s" ;;
    menu_dark) _alias_i18n_pick "  1) dark   (für dunklen Terminal-Hintergrund)" "  1) dark   (for dark terminal backgrounds)" ;;
    menu_bright) _alias_i18n_pick "  2) bright (für hellen Terminal-Hintergrund)" "  2) bright (for bright terminal backgrounds)" ;;
    menu_quit) _alias_i18n_pick "  q) abbrechen" "  q) cancel" ;;
    menu_prompt) _alias_i18n_pick "Auswahl [1/2/q]: " "Choice [1/2/q]: " ;;
    canceled) _alias_i18n_pick "Abgebrochen." "Canceled." ;;
    invalid_choice) _alias_i18n_pick "Ungültige Auswahl." "Invalid choice." ;;
    saved) _alias_i18n_pick "Farbschema '%s' gespeichert in: %s" "Color scheme '%s' saved to: %s" ;;
    reload_hint) _alias_i18n_pick "Für die aktuelle Shell: _alias_reload" "For the current shell: _alias_reload" ;;
    *) printf '%s' "${key}" ;;
  esac
}

_escape_regex() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\/]/\\&/g'
}

_ensure_user_settings_file() {
  mkdir -p "${_user_settings_dir}" || {
    printf "$(_text err_mkdir)\n" "${_user_settings_dir}"
    exit 1
  }

  if [ -f "${_user_settings_file}" ]; then
    if [ ! -w "${_user_settings_file}" ]; then
      printf "$(_text err_not_writable)\n" "${_user_settings_file}"
      exit 1
    fi
    return 0
  fi

  {
    echo "$(_text header_delta)"
    echo "$(_text header_delta_hint)"
  } > "${_user_settings_file}" || {
    printf "$(_text err_create_file)\n" "${_user_settings_file}"
    exit 1
  }
}

_remove_block() {
  local start_marker="$1"
  local end_marker="$2"
  local start_regex=""
  local end_regex=""

  start_regex="$(_escape_regex "${start_marker}")"
  end_regex="$(_escape_regex "${end_marker}")"
  sed -i -E "/${start_regex}/,/${end_regex}/d" "${_user_settings_file}"
}

_write_scheme_block() {
  local scheme="$1"
  local detail_label=""
  local menu_title=""
  local menu_meta=""
  local menu_header=""
  local menu_setup=""
  local color_reset="'\\033[0m'"

  case "${scheme}" in
    dark)
      detail_label="'\\033[1;32m'"
      menu_title="'\\033[1;36m'"
      menu_meta="'\\033[0;36m'"
      menu_header="'\\033[1;96m'"
      menu_setup="'\\033[38;5;247m'"
      ;;
    bright)
      detail_label="'\\033[0;34m'"
      menu_title="'\\033[1;34m'"
      menu_meta="'\\033[0;30m'"
      menu_header="'\\033[1;30m'"
      menu_setup="'\\033[0;90m'"
      ;;
    *)
      printf "$(_text err_unknown_scheme)\n" "${scheme}"
      exit 1
      ;;
  esac

  _remove_block "${_scheme_block_start}" "${_scheme_block_end}"

  {
    echo ""
    echo "${_scheme_block_start}"
    echo "$(_text managed_comment)"
    echo "BASH_ALIAS_COLOR_SCHEME='${scheme}'"
    echo "BASH_ALIAS_HELP_COLOR_DETAIL_LABEL=${detail_label}"
    echo "BASH_ALIAS_HELP_COLOR_MENU_TITLE=${menu_title}"
    echo "BASH_ALIAS_HELP_COLOR_MENU_META=${menu_meta}"
    echo "BASH_ALIAS_HELP_COLOR_MENU_HEADER=${menu_header}"
    echo "BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP=${menu_setup}"
    echo "BASH_ALIAS_HELP_COLOR_RESET=${color_reset}"
    echo "${_scheme_block_end}"
  } >> "${_user_settings_file}"
}

_ensure_override_block() {
  local preserved_active=""

  preserved_active="$(awk -v start="${_override_block_start}" -v end="${_override_block_end}" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    in_block && $0 ~ /^[[:space:]]*BASH_ALIAS_HELP_COLOR_(DETAIL_LABEL|MENU_TITLE|MENU_META|MENU_HEADER|MENU_CATEGORY_SETUP|RESET)[[:space:]]*=/ {
      print $0
    }
  ' "${_user_settings_file}")"

  _remove_block "${_override_block_start}" "${_override_block_end}"

  {
    echo ""
    echo "${_override_block_start}"
    echo "$(_text override_comment_1)"
    echo "$(_text override_comment_2)"
    echo "# BASH_ALIAS_HELP_COLOR_DETAIL_LABEL='\\033[1;32m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_TITLE='\\033[1;36m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_META='\\033[0;36m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_HEADER='\\033[1;96m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP='\\033[38;5;247m'"
    echo "# BASH_ALIAS_HELP_COLOR_RESET='\\033[0m'"
    if [ -n "${preserved_active}" ]; then
      echo "${preserved_active}"
    fi
    echo "${_override_block_end}"
  } >> "${_user_settings_file}"
}

_print_menu() {
  local current_scheme="${BASH_ALIAS_COLOR_SCHEME:-dark}"
  echo ""
  printf "$(_text menu_title)\n" "${_user_settings_file}"
  printf "$(_text menu_current)\n" "${current_scheme}"
  echo "$(_text menu_dark)"
  echo "$(_text menu_bright)"
  echo "$(_text menu_quit)"
}

_select_scheme_interactive() {
  local answer=""

  while true; do
    _print_menu
    read -r -p "$(_text menu_prompt)" answer
    case "${answer}" in
      1|dark|DARK) REPLY="dark"; return 0 ;;
      2|bright|BRIGHT|light|LIGHT) REPLY="bright"; return 0 ;;
      q|Q|quit|QUIT|exit|EXIT) echo "$(_text canceled)"; exit 0 ;;
      *) echo "$(_text invalid_choice)" ;;
    esac
  done
}

main() {
  local scheme="${1:-}"

  _ensure_user_settings_file

  if [ -z "${scheme}" ]; then
    _select_scheme_interactive
    scheme="${REPLY}"
  fi

  _write_scheme_block "${scheme}"
  _ensure_override_block

  printf "$(_text saved)\n" "${scheme}" "${_user_settings_file}"
  echo "$(_text reload_hint)"
}

main "$@"
