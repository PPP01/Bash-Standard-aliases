#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_menu_engine.sh"

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

_select_language_interactive() {
  local answer=""
  local current_locale=""
  local selected=1
  local status=1
  local feedback=""
  local marker_de=" "
  local marker_en=" "
  local render_lines=0

  _alias_menu_session_begin
  while true; do
    _alias_menu_was_interrupted && {
      status=130
      break
    }

    _alias_menu_refresh_begin
    current_locale="${BASH_ALIAS_LOCALE:-de}"
    marker_de=" "
    marker_en=" "
    [ "${selected}" -eq 1 ] && marker_de=">"
    [ "${selected}" -eq 2 ] && marker_en=">"

    echo ""
    printf "$(_text menu_title)\n" "${_user_settings_file}"
    printf "$(_text menu_current)\n" "${current_locale}"
    printf ' %s %s\n' "${marker_de}" "$(_text menu_de)"
    printf ' %s %s\n' "${marker_en}" "$(_text menu_en)"
    echo "   $(_text menu_quit)"
    if [ -n "${feedback}" ]; then
      echo "${feedback}"
    fi
    render_lines=6
    if [ -n "${feedback}" ]; then
      render_lines=$((render_lines + 1))
    fi
    _alias_menu_redraw_set_lines $((render_lines + 1))

    _alias_menu_read_input "$(_text menu_prompt)"
    case "$?" in
      130)
        status=130
        break
        ;;
      0) ;;
      *)
        status=1
        break
        ;;
    esac
    answer="${REPLY:-}"

    if _alias_menu_is_quit_input "${answer}" || _alias_menu_is_back_input "${answer}"; then
      status=2
      break
    fi

    case "${answer}" in
      up)
        if [ "${selected}" -le 1 ]; then
          selected=2
        else
          selected=$((selected - 1))
        fi
        feedback=""
        ;;
      down)
        if [ "${selected}" -ge 2 ]; then
          selected=1
        else
          selected=$((selected + 1))
        fi
        feedback=""
        ;;
      right|'')
        if [ "${selected}" -eq 1 ]; then
          REPLY="de"
        else
          REPLY="en"
        fi
        status=0
        break
        ;;
      1|de|DE)
        REPLY="de"
        status=0
        break
        ;;
      2|en|EN)
        REPLY="en"
        status=0
        break
        ;;
      *)
        feedback="$(_text invalid_choice)"
        ;;
    esac
  done

  _alias_menu_session_end
  if [ "${status}" -eq 0 ]; then
    return 0
  fi
  if [ "${status}" -eq 2 ]; then
    echo "$(_text canceled)"
    return 2
  fi
  if [ "${status}" -eq 130 ]; then
    echo "$(_text canceled)"
    return 130
  fi
  return 1
}

main() {
  local locale="${1:-}"
  local select_rc=0

  _ensure_user_settings_file

  if [ -z "${locale}" ]; then
    _select_language_interactive
    select_rc=$?
    case "${select_rc}" in
      0) ;;
      2) return 0 ;;
      130) return 130 ;;
      *) return 1 ;;
    esac
    locale="${REPLY}"
  fi

  _write_language_block "${locale}"
  BASH_ALIAS_LOCALE="${locale}"

  printf "$(_text saved)\n" "${locale}" "${_user_settings_file}"
  echo "$(_text reload_hint)"
}

main "$@"
