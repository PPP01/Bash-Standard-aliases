#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_user_settings_dir="${HOME}/.config/bash-standard-aliases"
_user_settings_file="${_user_settings_dir}/settings.conf"
_scheme_block_start="# >>> _alias_setup_scheme managed >>>"
_scheme_block_end="# <<< _alias_setup_scheme managed <<<"
_override_block_start="# >>> _alias_setup_scheme user-overrides >>>"
_override_block_end="# <<< _alias_setup_scheme user-overrides <<<"

_escape_regex() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\/]/\\&/g'
}

_ensure_user_settings_file() {
  mkdir -p "${_user_settings_dir}" || {
    echo "Fehler: Konnte Verzeichnis nicht erstellen: ${_user_settings_dir}"
    exit 1
  }

  if [ -f "${_user_settings_file}" ]; then
    if [ ! -w "${_user_settings_file}" ]; then
      echo "Fehler: Datei ist nicht schreibbar: ${_user_settings_file}"
      exit 1
    fi
    return 0
  fi

  {
    echo "# User-Delta-Settings für bash-standard-aliases"
    echo "# Nur Abweichungen von settings.conf / settings.local.conf"
  } > "${_user_settings_file}" || {
    echo "Fehler: Konnte Datei nicht erzeugen: ${_user_settings_file}"
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
      menu_setup="'\\033[0;37m'"
      ;;
    bright)
      detail_label="'\\033[0;34m'"
      menu_title="'\\033[1;34m'"
      menu_meta="'\\033[0;30m'"
      menu_header="'\\033[1;30m'"
      menu_setup="'\\033[0;30m'"
      ;;
    *)
      echo "Fehler: Unbekanntes Schema '${scheme}'. Erlaubt: dark, bright"
      exit 1
      ;;
  esac

  _remove_block "${_scheme_block_start}" "${_scheme_block_end}"

  {
    echo ""
    echo "${_scheme_block_start}"
    echo "# Von _alias_setup_scheme verwaltet."
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
    echo "# Eigene Farb-Overrides. Diese Werte setzen sich immer gegen das Schema durch."
    echo "# Zum Aktivieren '#' entfernen und Wert anpassen."
    echo "# BASH_ALIAS_HELP_COLOR_DETAIL_LABEL='\\033[1;32m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_TITLE='\\033[1;36m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_META='\\033[0;36m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_HEADER='\\033[1;96m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP='\\033[0;37m'"
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
  echo "Farbschema auswählen (Speicherort: ${_user_settings_file})"
  echo "Aktuell: ${current_scheme}"
  echo "  1) dark   (für dunklen Terminal-Hintergrund)"
  echo "  2) bright (für hellen Terminal-Hintergrund)"
  echo "  q) abbrechen"
}

_select_scheme_interactive() {
  local answer=""

  while true; do
    _print_menu
    read -r -p "Auswahl [1/2/q]: " answer
    case "${answer}" in
      1|dark|DARK) REPLY="dark"; return 0 ;;
      2|bright|BRIGHT|light|LIGHT) REPLY="bright"; return 0 ;;
      q|Q|quit|QUIT|exit|EXIT) echo "Abgebrochen."; exit 0 ;;
      *) echo "Ungültige Auswahl." ;;
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

  echo "Farbschema '${scheme}' gespeichert in: ${_user_settings_file}"
  echo "Für die aktuelle Shell: _alias_reload"
}

main "$@"
