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

_collect_active_color_overrides_outside_managed() {
  awk -v managed_start="${_scheme_block_start}" -v managed_end="${_scheme_block_end}" '
    BEGIN { in_managed=0 }
    $0 == managed_start { in_managed=1; next }
    $0 == managed_end { in_managed=0; next }
    !in_managed && $0 ~ /^[[:space:]]*BASH_ALIAS_HELP_COLOR_(DETAIL_LABEL|MENU_TITLE|MENU_META|MENU_HEADER|MENU_CATEGORY_HEADER|MENU_CATEGORY_SETUP|MENU_HIGHLIGHT_LINE|MENU_HIGHLIGHT_MARKER|RESET)[[:space:]]*=/ {
      print $0
    }
  ' "${_user_settings_file}"
}

_dedupe_color_override_lines_keep_last() {
  awk '
    /^[[:space:]]*BASH_ALIAS_HELP_COLOR_(DETAIL_LABEL|MENU_TITLE|MENU_META|MENU_HEADER|MENU_CATEGORY_HEADER|MENU_CATEGORY_SETUP|MENU_HIGHLIGHT_LINE|MENU_HIGHLIGHT_MARKER|RESET)[[:space:]]*=/ {
      key=$1
      sub(/[[:space:]]*=.*/, "", key)
      if (!(key in seen)) {
        order[++count]=key
        seen[key]=1
      }
      values[key]=$0
      next
    }
    { next }
    END {
      for (i=1; i<=count; i++) {
        key=order[i]
        if (key in values) {
          print values[key]
        }
      }
    }
  '
}

_strip_active_color_overrides_outside_managed() {
  local tmp_file=""
  tmp_file="$(mktemp)" || return 1

  awk -v managed_start="${_scheme_block_start}" -v managed_end="${_scheme_block_end}" '
    BEGIN { in_managed=0 }
    $0 == managed_start { in_managed=1; print; next }
    $0 == managed_end { in_managed=0; print; next }
    !in_managed && $0 ~ /^[[:space:]]*BASH_ALIAS_HELP_COLOR_(DETAIL_LABEL|MENU_TITLE|MENU_META|MENU_HEADER|MENU_CATEGORY_HEADER|MENU_CATEGORY_SETUP|MENU_HIGHLIGHT_LINE|MENU_HIGHLIGHT_MARKER|RESET)[[:space:]]*=/ {
      next
    }
    { print }
  ' "${_user_settings_file}" > "${tmp_file}" && mv "${tmp_file}" "${_user_settings_file}"
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
      menu_highlight_line="'\\033[1;97;100m'"
      menu_highlight_marker="'\\033[1;34m'"
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
  local scheme="${1:-dark}"
  local preserved_active=""
  local sample_detail_label=""
  local sample_menu_title=""
  local sample_menu_meta=""
  local sample_menu_header=""
  local sample_menu_category_header=""
  local sample_menu_category_setup=""
  local sample_menu_highlight_line=""
  local sample_menu_highlight_marker=""
  local sample_color_reset="'\\033[0m'"

  case "${scheme}" in
    dark)
      sample_detail_label="'\\033[1;32m'"
      sample_menu_title="'\\033[1;36m'"
      sample_menu_meta="'\\033[0;36m'"
      sample_menu_header="'\\033[1;96m'"
      sample_menu_category_header="'\\033[1;32m'"
      sample_menu_category_setup="'\\033[38;5;247m'"
      sample_menu_highlight_line="'\\033[1;97;44m'"
      sample_menu_highlight_marker="'\\033[1;96m'"
      ;;
    bright)
      sample_detail_label="'\\033[0;34m'"
      sample_menu_title="'\\033[1;34m'"
      sample_menu_meta="'\\033[0;30m'"
      sample_menu_header="'\\033[1;30m'"
      sample_menu_category_header="'\\033[1;38;5;22m'"
      sample_menu_category_setup="'\\033[0;90m'"
      sample_menu_highlight_line="'\\033[1;97;100m'"
      sample_menu_highlight_marker="'\\033[1;34m'"
      ;;
    *)
      sample_detail_label="'\\033[1;32m'"
      sample_menu_title="'\\033[1;36m'"
      sample_menu_meta="'\\033[0;36m'"
      sample_menu_header="'\\033[1;96m'"
      sample_menu_category_header="'\\033[1;32m'"
      sample_menu_category_setup="'\\033[38;5;247m'"
      sample_menu_highlight_line="'\\033[1;97;44m'"
      sample_menu_highlight_marker="'\\033[1;96m'"
      ;;
  esac

  preserved_active="$(_collect_active_color_overrides_outside_managed | _dedupe_color_override_lines_keep_last)"

  _remove_block "${_override_block_start}" "${_override_block_end}"
  _strip_active_color_overrides_outside_managed

  {
    echo ""
    echo "${_override_block_start}"
    echo "$(_text override_comment_1)"
    echo "$(_text override_comment_2)"
    echo "# BASH_ALIAS_HELP_COLOR_DETAIL_LABEL=${sample_detail_label}"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_TITLE=${sample_menu_title}"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_META=${sample_menu_meta}"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_HEADER=${sample_menu_header}"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_HEADER=${sample_menu_category_header}"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP=${sample_menu_category_setup}"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_HIGHLIGHT_LINE=${sample_menu_highlight_line}"
    echo "# BASH_ALIAS_HELP_COLOR_MENU_HIGHLIGHT_MARKER=${sample_menu_highlight_marker}"
    echo "# BASH_ALIAS_HELP_COLOR_RESET=${sample_color_reset}"
    if [ -n "${preserved_active}" ]; then
      echo "${preserved_active}"
    fi
    echo "${_override_block_end}"
  } >> "${_user_settings_file}"
}

_select_scheme_interactive() {
  local answer=""
  local current_scheme="${BASH_ALIAS_COLOR_SCHEME:-dark}"
  local selected=1
  local status=1
  local feedback=""
  local marker_dark=" "
  local marker_bright=" "
  local render_lines=0

  _alias_menu_session_begin
  while true; do
    _alias_menu_was_interrupted && {
      status=130
      break
    }

    _alias_menu_refresh_begin
    current_scheme="${BASH_ALIAS_COLOR_SCHEME:-dark}"
    marker_dark=" "
    marker_bright=" "
    [ "${selected}" -eq 1 ] && marker_dark=">"
    [ "${selected}" -eq 2 ] && marker_bright=">"

    echo ""
    printf "$(_text menu_title)\n" "${_user_settings_file}"
    printf "$(_text menu_current)\n" "${current_scheme}"
    printf ' %s %s\n' "${marker_dark}" "$(_text menu_dark)"
    printf ' %s %s\n' "${marker_bright}" "$(_text menu_bright)"
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
          REPLY="dark"
        else
          REPLY="bright"
        fi
        status=0
        break
        ;;
      1|dark|DARK)
        REPLY="dark"
        status=0
        break
        ;;
      2|bright|BRIGHT|light|LIGHT)
        REPLY="bright"
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
  local scheme="${1:-}"
  local select_rc=0

  _ensure_user_settings_file

  if [ -z "${scheme}" ]; then
    _select_scheme_interactive
    select_rc=$?
    case "${select_rc}" in
      0) ;;
      2) return 0 ;;
      130) return 130 ;;
      *) return 1 ;;
    esac
    scheme="${REPLY}"
  fi

  _write_scheme_block "${scheme}"
  _ensure_override_block "${scheme}"

  printf "$(_text saved)\n" "${scheme}" "${_user_settings_file}"
  echo "$(_text reload_hint)"
}

main "$@"
