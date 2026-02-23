#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"
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

_select_target_conf() {
  local answer=""

  if [ "${EUID}" -ne 0 ]; then
    _target_kind="user"
    _target_conf="${_user_conf}"
    return 0
  fi

  echo ""
  echo "$(_text root_target_title)"
  printf "$(_text root_target_global)\n" "${_local_conf}"
  printf "$(_text root_target_user)\n" "${_user_conf}"
  echo "$(_text root_target_cancel)"
  read -r -p "$(_text root_target_prompt)" answer

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
    printf "$(_text category_on)\n" "${category}"
  else
    printf "$(_text category_off)\n" "${category}"
  fi
}

_list_categories() {
  local idx=1
  local category=""
  local state=""
  local shown=0

  echo ""
  printf "$(_text categories_in_file)\n" "${_target_conf}"

  if declare -F alias_categories_list >/dev/null 2>&1; then
    while IFS= read -r category; do
      [ -z "${category}" ] && continue
      _category_is_visible "${category}" || continue
      state="$(_category_state "${category}")"
      printf ' %2d) %-12s [%s]\n' "${idx}" "${category}" "${state}"
      shown=1
      idx=$((idx + 1))
    done < <(alias_categories_list)
  else
    echo "$(_text no_categories_defined)"
  fi

  if [ "${shown}" -eq 0 ]; then
    echo "$(_text no_editable_categories)"
  fi

  echo "$(_text quit_line)"
}

_resolve_category_by_index() {
  local wanted="$1"
  local idx=1
  local category=""

  if declare -F alias_categories_list >/dev/null 2>&1; then
    while IFS= read -r category; do
      [ -z "${category}" ] && continue
      _category_is_visible "${category}" || continue
      if [ "${idx}" -eq "${wanted}" ]; then
        printf '%s' "${category}"
        return 0
      fi
      idx=$((idx + 1))
    done < <(alias_categories_list)
  fi

  return 1
}

_select_target_conf
_prepare_target_conf

while true; do
  _list_categories
  read -r -p "$(_text toggle_prompt)" _choice

  case "${_choice}" in
    q|Q|quit|QUIT|exit|EXIT)
      break
      ;;
    ''|*[!0-9]*)
      echo "$(_text enter_valid_number)"
      ;;
    *)
      _category="$(_resolve_category_by_index "${_choice}")" || {
        echo "$(_text invalid_number)"
        continue
      }
      _toggle_category "${_category}"
      ;;
  esac

done

echo "$(_text done_hint)"
