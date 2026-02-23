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
  _alias_i18n_text "color_scheme.$1"
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
  local menu_category_header=""
  local menu_setup=""
  local menu_highlight_line=""
  local menu_highlight_marker=""
  local color_reset="'\\033[0m'"

  case "${scheme}" in
    dark)
      detail_label="'\\033[1;32m'"
      menu_title="'\\033[1;36m'"
      menu_meta="'\\033[0;36m'"
      menu_header="'\\033[1;96m'"
      menu_category_header="'\\033[1;32m'"
      menu_setup="'\\033[38;5;247m'"
      menu_highlight_line="'\\033[1;97;44m'"
      menu_highlight_marker="'\\033[1;96m'"
      ;;
    bright)
      detail_label="'\\033[0;34m'"
      menu_title="'\\033[1;34m'"
      menu_meta="'\\033[0;30m'"
      menu_header="'\\033[1;30m'"
      menu_setup="'\\033[0;90m'"
      menu_category_header="'\\033[1;38;5;22m'"
      menu_highlight_line="'\\033[1;30;47m'"
      menu_highlight_marker="'\\033[1;37m'"
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
    echo "BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_HEADER=${menu_category_header}"
    echo "BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP=${menu_setup}"
    echo "BASH_ALIAS_HELP_COLOR_MENU_HIGHLIGHT_LINE=${menu_highlight_line}"
    echo "BASH_ALIAS_HELP_COLOR_MENU_HIGHLIGHT_MARKER=${menu_highlight_marker}"
    echo "BASH_ALIAS_HELP_COLOR_RESET=${color_reset}"
    echo "${_scheme_block_end}"
  } >> "${_user_settings_file}"
}

_ensure_override_block() {
  local preserved_active=""

  preserved_active="$(awk -v start="${_override_block_start}" -v end="${_override_block_end}" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    in_block && $0 ~ /^[[:space:]]*BASH_ALIAS_HELP_COLOR_(DETAIL_LABEL|MENU_TITLE|MENU_META|MENU_HEADER|MENU_CATEGORY_HEADER|MENU_CATEGORY_SETUP|MENU_HIGHLIGHT_LINE|MENU_HIGHLIGHT_MARKER|RESET)[[:space:]]*=/ {
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
    echo "# BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_HEADER='\\033[1;32m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP='\\033[38;5;247m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_HIGHLIGHT_LINE='\\033[1;97;44m'"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_HIGHLIGHT_MARKER='\\033[1;96m'"
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
