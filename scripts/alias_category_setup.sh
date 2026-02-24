#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_menu_engine.sh"
_default_conf="${_repo_dir}/alias_files.conf"
_local_conf="${_repo_dir}/alias_files.local.conf"
_user_conf_dir="${HOME}/.config/bash-standard-aliases"
_user_conf="${_user_conf_dir}/config.conf"
_categories_file="${_repo_dir}/alias_categories.sh"

_target_conf=""
_target_kind=""

declare -A _module_visible_cache=()

_text() {
  _alias_i18n_text "category_setup.$1"
}

if [ ! -f "${_default_conf}" ]; then
  printf "$(_text err_default_conf_missing)\n" "${_default_conf}"
  exit 1
fi

if [ -f "${_categories_file}" ]; then
  # shellcheck disable=SC1090
  source "${_categories_file}"
fi

_escape_regex() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\/]/\\&/g'
}

_select_root_target_interactive() {
  local answer=""
  local selected=2
  local status=1
  local feedback=""
  local marker_global=" "
  local marker_user=" "
  local marker_cancel=" "
  local render_lines=0

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

    echo ""
    echo "$(_text root_target_title)"
    printf ' %s ' "${marker_global}"
    printf "$(_text root_target_global)\n" "${_local_conf}"
    printf ' %s ' "${marker_user}"
    printf "$(_text root_target_user)\n" "${_user_conf}"
    printf ' %s %s\n' "${marker_cancel}" "$(_text root_target_cancel)"
    if [ -n "${feedback}" ]; then
      echo "${feedback}"
    fi
    render_lines=5
    if [ -n "${feedback}" ]; then
      render_lines=$((render_lines + 1))
    fi
    _alias_menu_redraw_set_lines $((render_lines + 1))

    _alias_menu_read_input "$(_text root_target_prompt)"
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
        REPLY="${selected}"
        status=0
        break
        ;;
      1|2|3)
        REPLY="${answer}"
        status=0
        break
        ;;
      *)
        feedback="$(_text enter_valid_number)"
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

_select_target_conf() {
  local answer=""
  local select_rc=0

  if [ "${EUID}" -ne 0 ]; then
    _target_kind="user"
    _target_conf="${_user_conf}"
    return 0
  fi

  _select_root_target_interactive
  select_rc=$?
  case "${select_rc}" in
    0) answer="${REPLY}" ;;
    2|130) exit 1 ;;
    *) exit 1 ;;
  esac

  case "${answer}" in
    1)
      _target_kind="global"
      _target_conf="${_local_conf}"
      ;;
    2|"")
      _target_kind="user"
      _target_conf="${_user_conf}"
      ;;
    *)
      echo "$(_text canceled)"
      exit 1
      ;;
  esac
}

_prepare_target_conf() {
  if [ "${_target_kind}" = "user" ]; then
    mkdir -p "${_user_conf_dir}" || {
      printf "$(_text err_mkdir)\n" "${_user_conf_dir}"
      exit 1
    }
  fi

  if [ -f "${_target_conf}" ]; then
    if [ ! -w "${_target_conf}" ]; then
      printf "$(_text err_not_writable)\n" "${_target_conf}"
      exit 1
    fi
    return 0
  fi

  {
    echo "$(_text cfg_header_1)"
    echo "$(_text cfg_header_2)"
    if [ "${_target_kind}" = "user" ]; then
      echo "$(_text cfg_header_user_base)"
    else
      echo "$(_text cfg_header_global_base)"
    fi
    echo "$(_text cfg_header_enable)"
    echo "$(_text cfg_header_disable)"
  } > "${_target_conf}" || {
    printf "$(_text err_create_config)\n" "${_target_conf}"
    exit 1
  }

  printf "$(_text cfg_created)\n" "${_target_conf}"
}

_module_state_in_file() {
  local file_path="$1"
  local module="$2"
  local regex=""
  local line=""

  [ -f "${file_path}" ] || {
    printf 'none'
    return 0
  }

  regex="$(_escape_regex "${module}")"
  line="$(grep -E "^[[:space:]]*#?[[:space:]]*${regex}[[:space:]]*$" "${file_path}" | tail -n 1)"

  if [ -z "${line}" ]; then
    printf 'none'
    return 0
  fi

  if [[ "${line}" =~ ^[[:space:]]*# ]]; then
    printf 'off'
  else
    printf 'on'
  fi
}

_base_state_for_module() {
  local module="$1"
  local state=""
  local global_state=""

  state="$(_module_state_in_file "${_default_conf}" "${module}")"
  if [ "${state}" = "none" ]; then
    state='off'
  fi

  if [ "${_target_kind}" = "user" ]; then
    global_state="$(_module_state_in_file "${_local_conf}" "${module}")"
    if [ "${global_state}" != "none" ]; then
      state="${global_state}"
    fi
  fi

  printf '%s' "${state}"
}

_effective_state_for_module() {
  local module="$1"
  local base_state=""
  local override_state=""

  base_state="$(_base_state_for_module "${module}")"
  override_state="$(_module_state_in_file "${_target_conf}" "${module}")"

  if [ "${override_state}" != "none" ]; then
    printf '%s' "${override_state}"
  else
    printf '%s' "${base_state}"
  fi
}

_remove_module_override() {
  local module="$1"
  local regex=""

  regex="$(_escape_regex "${module}")"
  sed -i -E "/^[[:space:]]*#?[[:space:]]*${regex}[[:space:]]*$/d" "${_target_conf}"
}

_write_module_override() {
  local module="$1"
  local desired_state="$2"

  _remove_module_override "${module}"

  if [ "${desired_state}" = "on" ]; then
    printf '%s\n' "${module}" >> "${_target_conf}"
  else
    printf '# %s\n' "${module}" >> "${_target_conf}"
  fi
}

_set_module_desired_state() {
  local module="$1"
  local desired_state="$2"
  local base_state=""

  base_state="$(_base_state_for_module "${module}")"

  if [ "${desired_state}" = "${base_state}" ]; then
    _remove_module_override "${module}"
  else
    _write_module_override "${module}" "${desired_state}"
  fi
}

_module_visible_for_user() {
  local module="$1"
  local module_path=""
  local cached=""

  cached="${_module_visible_cache[${module}]:-}"
  if [ -n "${cached}" ]; then
    [ "${cached}" = "1" ]
    return
  fi

  module_path="${_repo_dir}/alias_files/${module}"
  if [ ! -f "${module_path}" ]; then
    _module_visible_cache["${module}"]=0
    return 1
  fi

  if bash --noprofile --norc -c '
    module_path="$1"
    # shellcheck disable=SC1090
    source "${module_path}" >/dev/null 2>&1 || true
    alias_count="$(alias | wc -l | tr -d "[:space:]")"
    func_count="$(declare -F | wc -l | tr -d "[:space:]")"
    if [ "${alias_count}" -gt 0 ] || [ "${func_count}" -gt 0 ]; then
      exit 0
    fi
    exit 1
  ' _ "${module_path}"; then
    _module_visible_cache["${module}"]=1
    return 0
  fi

  _module_visible_cache["${module}"]=0
  return 1
}

_category_is_visible() {
  local category="$1"
  local modules=""
  local module=""

  if declare -F alias_modules_for_category >/dev/null 2>&1; then
    modules="$(alias_modules_for_category "${category}")"
  fi

  for module in ${modules}; do
    _module_visible_for_user "${module}" && return 0
  done

  return 1
}

_category_state() {
  local category="$1"
  local modules=""
  local module=""
  local total=0
  local active=0
  local state=""

  if declare -F alias_modules_for_category >/dev/null 2>&1; then
    modules="$(alias_modules_for_category "${category}")"
  fi

  for module in ${modules}; do
    _module_visible_for_user "${module}" || continue
    total=$((total + 1))
    state="$(_effective_state_for_module "${module}")"
    if [ "${state}" = "on" ]; then
      active=$((active + 1))
    fi
  done

  if [ "${total}" -eq 0 ] || [ "${active}" -eq 0 ]; then
    printf 'off'
  elif [ "${active}" -eq "${total}" ]; then
    printf 'on'
  else
    printf 'partial'
  fi
}

_toggle_category() {
  local category="$1"
  local state=""
  local desired_state=""
  local modules=""
  local module=""
  local message=""

  state="$(_category_state "${category}")"
  if [ "${state}" = "on" ]; then
    desired_state='off'
  else
    desired_state='on'
  fi

  if declare -F alias_modules_for_category >/dev/null 2>&1; then
    modules="$(alias_modules_for_category "${category}")"
  fi

  for module in ${modules}; do
    _module_visible_for_user "${module}" || continue
    _set_module_desired_state "${module}" "${desired_state}"
  done

  if [ "${desired_state}" = "on" ]; then
    message="$(printf "$(_text category_on)" "${category}")"
  else
    message="$(printf "$(_text category_off)" "${category}")"
  fi
  REPLY="${message}"
}

_collect_visible_categories() {
  local category=""

  if ! declare -F alias_categories_list >/dev/null 2>&1; then
    return 0
  fi

  while IFS= read -r category; do
    [ -z "${category}" ] && continue
    _category_is_visible "${category}" || continue
    printf '%s\n' "${category}"
  done < <(alias_categories_list)
}

_select_target_conf
_prepare_target_conf

_choice=""
_category=""
_status=0
_selected=1
_feedback=""
_render_lines=0
declare -a _visible_categories=()

_alias_menu_session_begin
while true; do
  _alias_menu_was_interrupted && {
    _status=130
    break
  }

  _alias_menu_refresh_begin
  _visible_categories=()
  while IFS= read -r _category; do
    [ -z "${_category}" ] && continue
    _visible_categories+=("${_category}")
  done < <(_collect_visible_categories)

  if [ "${#_visible_categories[@]}" -eq 0 ]; then
    _selected=0
  elif [ "${_selected}" -lt 1 ] || [ "${_selected}" -gt "${#_visible_categories[@]}" ]; then
    _selected=1
  fi

  echo ""
  printf "$(_text categories_in_file)\n" "${_target_conf}"
  if [ "${#_visible_categories[@]}" -eq 0 ]; then
    echo "$(_text no_editable_categories)"
  else
    _idx=1
    for _category in "${_visible_categories[@]}"; do
      _state="$(_category_state "${_category}")"
      _marker=" "
      if [ "${_idx}" -eq "${_selected}" ]; then
        _marker=">"
      fi
      printf ' %s %2d) %-12s [%s]\n' "${_marker}" "${_idx}" "${_category}" "${_state}"
      _idx=$((_idx + 1))
    done
  fi
  echo "   $(_text quit_line)"
  if [ -n "${_feedback}" ]; then
    echo "${_feedback}"
  fi

  _render_lines=3
  if [ "${#_visible_categories[@]}" -gt 0 ]; then
    _render_lines=$((_render_lines + ${#_visible_categories[@]}))
  else
    _render_lines=$((_render_lines + 1))
  fi
  if [ -n "${_feedback}" ]; then
    _render_lines=$((_render_lines + 1))
  fi
  _alias_menu_redraw_set_lines $((_render_lines + 1))

  _alias_menu_read_input "$(_text toggle_prompt)"
  case "$?" in
    130)
      _status=130
      break
      ;;
    0) ;;
    *)
      _status=1
      break
      ;;
  esac
  _choice="${REPLY:-}"

  if _alias_menu_is_quit_input "${_choice}" || _alias_menu_is_back_input "${_choice}"; then
    break
  fi

  case "${_choice}" in
    up)
      if [ "${#_visible_categories[@]}" -gt 0 ]; then
        if [ "${_selected}" -le 1 ]; then
          _selected="${#_visible_categories[@]}"
        else
          _selected=$((_selected - 1))
        fi
      fi
      _feedback=""
      continue
      ;;
    down)
      if [ "${#_visible_categories[@]}" -gt 0 ]; then
        if [ "${_selected}" -ge "${#_visible_categories[@]}" ]; then
          _selected=1
        else
          _selected=$((_selected + 1))
        fi
      fi
      _feedback=""
      continue
      ;;
    right|'')
      if [ "${#_visible_categories[@]}" -le 0 ] || [ "${_selected}" -lt 1 ]; then
        _feedback="$(_text invalid_number)"
        continue
      fi
      _category="${_visible_categories[$((_selected - 1))]}"
      _toggle_category "${_category}"
      _feedback="${REPLY:-}"
      continue
      ;;
  esac

  if [[ ! "${_choice}" =~ ^[0-9]+$ ]]; then
    _feedback="$(_text enter_valid_number)"
    continue
  fi
  if [ "${_choice}" -lt 1 ] || [ "${_choice}" -gt "${#_visible_categories[@]}" ]; then
    _feedback="$(_text invalid_number)"
    continue
  fi

  _category="${_visible_categories[$((_choice - 1))]}"
  _selected="${_choice}"
  _toggle_category "${_category}"
  _feedback="${REPLY:-}"
done
_alias_menu_session_end

if [ "${_status}" -eq 130 ]; then
  echo "$(_text canceled)"
  exit 130
fi

echo "$(_text done_hint)"
