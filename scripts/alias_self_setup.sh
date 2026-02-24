#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
_loader_path="${_repo_dir}/bash_alias_std.sh"
_category_setup_script="${_repo_dir}/scripts/alias_category_setup.sh"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_menu_engine.sh"
_alias_setup_marker_start="# >>> bash_alias_std setup >>>"
_alias_setup_marker_end="# <<< bash_alias_std setup <<<"

_text() {
  _alias_i18n_text "self_setup.$1"
}

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
    echo "$(_text err_no_target)"
    return 1
  fi

  if [ -e "${target_file}" ] && ! [ -w "${target_file}" ]; then
    printf "$(_text err_not_writable)\n" "${target_file}"
    return 1
  fi

  if [ -f "${target_file}" ] && grep -Fq "${_alias_setup_marker_start}" "${target_file}"; then
    printf "$(_text already_marker)\n" "${target_file}"
    return 0
  fi

  if [ -f "${target_file}" ] && grep -Fq "${loader_path}" "${target_file}"; then
    printf "$(_text already_loader)\n" "${target_file}"
    return 0
  fi

  {
    echo ""
    _alias_setup_block "${loader_path}"
  } >> "${target_file}"

  printf "$(_text entry_added)\n" "${target_file}"
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
  local selected=2
  local status=1
  local marker_yes=" "
  local marker_no=" "
  local feedback=""
  local render_lines=0

  _alias_menu_session_begin
  while true; do
    _alias_menu_was_interrupted && {
      status=130
      break
    }

    _alias_menu_refresh_begin
    marker_yes=" "
    marker_no=" "
    [ "${selected}" -eq 1 ] && marker_yes=">"
    [ "${selected}" -eq 2 ] && marker_no=">"

    echo ""
    echo "${question}"
    printf ' %s 1) yes\n' "${marker_yes}"
    printf ' %s 2) no\n' "${marker_no}"
    if [ -n "${feedback}" ]; then
      echo "${feedback}"
    fi
    render_lines=4
    if [ -n "${feedback}" ]; then
      render_lines=$((render_lines + 1))
    fi
    _alias_menu_redraw_set_lines $((render_lines + 1))

    _alias_menu_read_input "${question}$(_text prompt_yes_no_suffix)"
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
      up|left)
        if [ "${selected}" -le 1 ]; then
          selected=2
        else
          selected=1
        fi
        feedback=""
        ;;
      down|right)
        if [ "${selected}" -ge 2 ]; then
          selected=1
        else
          selected=2
        fi
        feedback=""
        ;;
      ''|1|y|Y|yes|YES)
        if [ "${answer}" = "" ] && [ "${selected}" -eq 2 ]; then
          status=2
        else
          status=0
        fi
        break
        ;;
      2|n|N|no|NO)
        status=2
        break
        ;;
      *)
        feedback="$(_text canceled)"
        ;;
    esac
  done
  _alias_menu_session_end

  if [ "${status}" -eq 0 ]; then
    return 0
  fi
  if [ "${status}" -eq 130 ]; then
    return 130
  fi
  return 1
}

_alias_setup_prompt_choice_root_target() {
  local user_target="$1"
  local answer=""
  local selected=1
  local status=1
  local feedback=""
  local marker_user=" "
  local marker_global=" "
  local marker_skip=" "
  local render_lines=0

  _alias_menu_session_begin
  while true; do
    _alias_menu_was_interrupted && {
      status=130
      break
    }

    _alias_menu_refresh_begin
    marker_user=" "
    marker_global=" "
    marker_skip=" "
    [ "${selected}" -eq 1 ] && marker_user=">"
    [ "${selected}" -eq 2 ] && marker_global=">"
    [ "${selected}" -eq 3 ] && marker_skip=">"

    echo "$(_text root_choose_target)"
    printf ' %s 1) %s\n' "${marker_user}" "${user_target}"
    printf ' %s 2) /etc/bash.bashrc\n' "${marker_global}"
    printf ' %s %s\n' "${marker_skip}" "$(_text root_skip)"
    if [ -n "${feedback}" ]; then
      echo "${feedback}"
    fi
    render_lines=4
    if [ -n "${feedback}" ]; then
      render_lines=$((render_lines + 1))
    fi
    _alias_menu_redraw_set_lines $((render_lines + 1))

    _alias_menu_read_input "$(_text prompt_choice_123)"
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
          selected=3
        else
          selected=$((selected - 1))
        fi
        feedback=""
        ;;
      down)
        if [ "${selected}" -ge 3 ]; then
          selected=1
        else
          selected=$((selected + 1))
        fi
        feedback=""
        ;;
      right|'')
        answer="${selected}"
        status=0
        break
        ;;
      1|2|3)
        status=0
        break
        ;;
      *)
        feedback="$(_text canceled)"
        ;;
    esac
  done
  _alias_menu_session_end

  if [ "${status}" -eq 130 ]; then
    return 130
  fi
  if [ "${status}" -ne 0 ]; then
    return 2
  fi

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
  local prompt_rc=0

  if [ ! -f "${_loader_path}" ]; then
    printf "$(_text err_loader_missing)\n" "${_loader_path}"
    return 1
  fi

  user_target="$(_alias_setup_resolve_user_target)"
  if [ -z "${user_target}" ]; then
    user_target="${user_rc}"
  fi

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ]; then
    final_target="$(_alias_setup_prompt_choice_root_target "${user_target}")"
    prompt_rc=$?
    if [ "${prompt_rc}" -eq 130 ]; then
      echo "$(_text canceled)"
      return 130
    fi
    if [ -n "${final_target}" ]; then
      _alias_setup_add_to_file "${final_target}" "${_loader_path}" || return 1
    else
      echo "$(_text root_skipped)"
    fi
  else
    if _alias_setup_prompt_yes_no "$(printf "$(_text prompt_user_setup)" "${user_target}")"; then
      _alias_setup_add_to_file "${user_target}" "${_loader_path}" || return 1
    else
      prompt_rc=$?
      if [ "${prompt_rc}" -eq 130 ]; then
        echo "$(_text canceled)"
        return 130
      fi
      echo "$(_text user_skipped)"
    fi
  fi

  echo "$(_text setup_done)"
}

_alias_setup_remove_from_file() {
  local target_file="$1"
  local tmp_file=""
  local awk_rc=0
  local stat_out=""
  local orig_mode=""
  local orig_uid=""
  local orig_gid=""

  if [ -z "${target_file}" ] || [ ! -f "${target_file}" ]; then
    printf "$(_text err_file_missing)\n" "${target_file}"
    return 1
  fi

  if [ ! -w "${target_file}" ]; then
    printf "$(_text err_not_writable)\n" "${target_file}"
    return 1
  fi

  # Preserve ownership and permissions because mktemp creates 0600 files.
  stat_out="$(stat -c '%a %u %g' "${target_file}" 2>/dev/null || true)"
  if [ -n "${stat_out}" ]; then
    read -r orig_mode orig_uid orig_gid <<< "${stat_out}"
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
      if [ -n "${orig_mode}" ]; then
        chmod "${orig_mode}" "${target_file}" || {
          printf "$(_text warn_mode_restore)\n" "${target_file}"
        }
      fi
      if [ -n "${orig_uid}" ] && [ -n "${orig_gid}" ]; then
        chown "${orig_uid}:${orig_gid}" "${target_file}" 2>/dev/null || true
      fi
      printf "$(_text marker_removed)\n" "${target_file}"
      ;;
    2)
      rm -f "${tmp_file}"
      printf "$(_text err_marker_unfinished)\n" "${target_file}"
      return 1
      ;;
    3)
      rm -f "${tmp_file}"
      printf "$(_text no_marker_in_file)\n" "${target_file}"
      return 1
      ;;
    *)
      rm -f "${tmp_file}"
      printf "$(_text err_marker_remove)\n" "${target_file}"
      return 1
      ;;
  esac
}

alias_setup_remove() {
  local target_file=""
  local user_target=""
  local answer=""
  local selected=3
  local status=0
  local feedback=""
  local marker_global=" "
  local marker_user=" "
  local marker_cancel=" "
  local render_lines=0

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
    _alias_menu_session_begin
    while true; do
      _alias_menu_was_interrupted && {
        status=130
        break
      }

      _alias_menu_refresh_begin
      marker_global=" "
      marker_user=" "
      marker_cancel=" "
      [ "${selected}" -eq 1 ] && marker_global=">"
      [ "${selected}" -eq 2 ] && marker_user=">"
      [ "${selected}" -eq 3 ] && marker_cancel=">"

      echo "$(_text no_marker_found)"
      echo "$(_text choose_remove_target)"
      printf ' %s 1) /etc/bash.bashrc\n' "${marker_global}"
      printf ' %s 2) %s\n' "${marker_user}" "${user_target}"
      printf ' %s %s\n' "${marker_cancel}" "$(_text remove_cancel)"
      if [ -n "${feedback}" ]; then
        echo "${feedback}"
      fi
      render_lines=5
      if [ -n "${feedback}" ]; then
        render_lines=$((render_lines + 1))
      fi
      _alias_menu_redraw_set_lines $((render_lines + 1))

      _alias_menu_read_input "$(_text prompt_choice_123)"
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
        answer=3
        break
      fi
      case "${answer}" in
        up)
          if [ "${selected}" -le 1 ]; then
            selected=3
          else
            selected=$((selected - 1))
          fi
          feedback=""
          ;;
        down)
          if [ "${selected}" -ge 3 ]; then
            selected=1
          else
            selected=$((selected + 1))
          fi
          feedback=""
          ;;
        right|'')
          answer="${selected}"
          break
          ;;
        1|2|3)
          break
          ;;
        *)
          feedback="$(_text canceled)"
          ;;
      esac
    done
    _alias_menu_session_end

    if [ "${status}" -eq 130 ]; then
      echo "$(_text canceled)"
      return 1
    fi
    case "${answer}" in
      1) _alias_setup_remove_from_file "/etc/bash.bashrc" ;;
      2) _alias_setup_remove_from_file "${user_target}" ;;
      *) echo "$(_text canceled)"; return 1 ;;
    esac
  else
    _alias_setup_remove_from_file "${user_target}"
  fi
}

_alias_setup_run_category_setup() {
  if [ -f "${_category_setup_script}" ]; then
    bash "${_category_setup_script}"
  else
    echo "$(_text err_category_script_missing)"
    return 1
  fi
}

alias_self_setup() {
  echo "$(_text start_category_selection)"
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
      printf "$(_text usage)\n" "$0"
      return 1
      ;;
  esac
}

_main "${1:-}"
