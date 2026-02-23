#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"

_user_settings_dir="${HOME}/.config/bash-standard-aliases"
_user_settings_file="${_user_settings_dir}/settings.conf"
_language_block_start="# >>> _alias_setup_language managed >>>"
_language_block_end="# <<< _alias_setup_language managed <<<"

_text() {
  _alias_i18n_text "language_setup.$1"
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

_write_language_block() {
  local locale="$1"

  case "${locale}" in
    de|en) ;;
    *)
      printf "$(_text err_unknown_language)\n" "${locale}"
      exit 1
      ;;
  esac

  _remove_block "${_language_block_start}" "${_language_block_end}"

  {
    echo ""
    echo "${_language_block_start}"
    echo "$(_text managed_comment)"
    echo "BASH_ALIAS_LOCALE='${locale}'"
    echo "${_language_block_end}"
  } >> "${_user_settings_file}"
}

_print_menu() {
  local current_locale="${BASH_ALIAS_LOCALE:-de}"
  echo ""
  printf "$(_text menu_title)\n" "${_user_settings_file}"
  printf "$(_text menu_current)\n" "${current_locale}"
  echo "$(_text menu_de)"
  echo "$(_text menu_en)"
  echo "$(_text menu_quit)"
}

_select_language_interactive() {
  local answer=""

  while true; do
    _print_menu
    read -r -p "$(_text menu_prompt)" answer
    case "${answer}" in
      1|de|DE) REPLY="de"; return 0 ;;
      2|en|EN) REPLY="en"; return 0 ;;
      q|Q|quit|QUIT|exit|EXIT) echo "$(_text canceled)"; exit 0 ;;
      *) echo "$(_text invalid_choice)" ;;
    esac
  done
}

main() {
  local locale="${1:-}"

  _ensure_user_settings_file

  if [ -z "${locale}" ]; then
    _select_language_interactive
    locale="${REPLY}"
  fi

  _write_language_block "${locale}"
  BASH_ALIAS_LOCALE="${locale}"

  printf "$(_text saved)\n" "${locale}" "${_user_settings_file}"
  echo "$(_text reload_hint)"
}

main "$@"
