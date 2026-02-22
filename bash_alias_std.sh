# shellcheck shell=bash
# version 2026-02-21
# Loader fuer modulare Aliase mit Kategorien und konfigurierbarer Modul-Liste

# Schutz vor doppeltem Laden in derselben Shell-Session.
if [ -n "${BASH_ALIAS_STD_LOADED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
BASH_ALIAS_STD_LOADED=1

_alias_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_alias_config_file_default="${_alias_base_dir}/alias_files.conf"
_alias_config_file_local="${_alias_base_dir}/alias_files.local.conf"
_alias_config_file_user="${HOME}/.config/bash-standard-aliases/config.conf"
_alias_settings_file_default="${_alias_base_dir}/settings.conf"
_alias_settings_file_local="${_alias_base_dir}/settings.local.conf"
_alias_settings_file_user="${HOME}/.config/bash-standard-aliases/settings.conf"
_alias_categories_file="${_alias_base_dir}/alias_categories.sh"
# Von Modulen/Funktionen nutzbar, um den Repo-Ordner sicher zu finden.
BASH_ALIAS_REPO_DIR="${_alias_base_dir}"

if [ -f "${_alias_categories_file}" ]; then
  # shellcheck disable=SC1090
  source "${_alias_categories_file}"
fi

# Beim Reload existieren bereits Aliase aus dem vorherigen Lauf.
# Diese zuerst entfernen, bevor die Mapping-Arrays neu initialisiert werden.
if declare -p BASH_ALIAS_ALIAS_CATEGORY >/dev/null 2>&1; then
  for _prev_alias_name in "${!BASH_ALIAS_ALIAS_CATEGORY[@]}"; do
    [ -z "${_prev_alias_name}" ] && continue
    unalias -- "${_prev_alias_name}" 2>/dev/null || true
  done
  unset _prev_alias_name
fi

declare -gA BASH_ALIAS_CATEGORY_ENABLED=()
declare -gA BASH_ALIAS_ALIAS_CATEGORY=()
declare -ga BASH_ALIAS_CATEGORY_ORDER=()

declare -A _alias_module_enabled=()
declare -a _alias_module_order=()

declare -a _alias_settings_layers=()
if [ -f "${_alias_settings_file_default}" ]; then
  _alias_settings_layers+=("${_alias_settings_file_default}")
fi
if [ -f "${_alias_settings_file_local}" ]; then
  _alias_settings_layers+=("${_alias_settings_file_local}")
fi
if [ -f "${_alias_settings_file_user}" ]; then
  _alias_settings_layers+=("${_alias_settings_file_user}")
fi

declare -a _alias_config_layers=()
if [ -f "${_alias_config_file_default}" ]; then
  _alias_config_layers+=("${_alias_config_file_default}")
fi
if [ -f "${_alias_config_file_local}" ]; then
  _alias_config_layers+=("${_alias_config_file_local}")
fi
if [ -f "${_alias_config_file_user}" ]; then
  _alias_config_layers+=("${_alias_config_file_user}")
fi

_alias_add_category_if_missing() {
  local category="$1"
  local existing=""

  for existing in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    if [ "${existing}" = "${category}" ]; then
      return 0
    fi
  done

  BASH_ALIAS_CATEGORY_ORDER+=("${category}")
}

_alias_add_module_if_missing() {
  local module="$1"
  local existing=""

  for existing in "${_alias_module_order[@]}"; do
    if [ "${existing}" = "${module}" ]; then
      return 0
    fi
  done

  _alias_module_order+=("${module}")
}

_alias_sort_key_for_category() {
  local category="$1"
  local key="50000"

  if declare -F alias_category_sort_key >/dev/null 2>&1; then
    key="$(alias_category_sort_key "${category}")"
  fi

  if [[ ! "${key}" =~ ^[0-9]+$ ]]; then
    key="50000"
  fi

  printf '%s' "${key}"
}

_alias_sort_categories() {
  local i=0
  local category=""
  local key=""
  local existing=""
  local existing_key=""
  local inserted=0
  local -a sorted=()
  local -a keys=()

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    key="$(_alias_sort_key_for_category "${category}")"
    inserted=0

    if [ "${#sorted[@]}" -eq 0 ]; then
      sorted+=("${category}")
      keys+=("${key}")
      continue
    fi

    for i in "${!sorted[@]}"; do
      existing="${sorted[$i]}"
      existing_key="${keys[$i]}"

      if [ "${key}" -lt "${existing_key}" ] || { [ "${key}" -eq "${existing_key}" ] && [ "${category}" \< "${existing}" ]; }; then
        sorted=("${sorted[@]:0:$i}" "${category}" "${sorted[@]:$i}")
        keys=("${keys[@]:0:$i}" "${key}" "${keys[@]:$i}")
        inserted=1
        break
      fi
    done

    if [ "${inserted}" -eq 0 ]; then
      sorted+=("${category}")
      keys+=("${key}")
    fi
  done

  BASH_ALIAS_CATEGORY_ORDER=("${sorted[@]}")
}

_alias_init_categories() {
  local category=""

  if declare -F alias_categories_list >/dev/null 2>&1; then
    while IFS= read -r category; do
      [ -z "${category}" ] && continue
      _alias_add_category_if_missing "${category}"
      BASH_ALIAS_CATEGORY_ENABLED["${category}"]=0
    done < <(alias_categories_list)
  fi

  _alias_add_category_if_missing "misc"
  BASH_ALIAS_CATEGORY_ENABLED["misc"]=0
}

_alias_collect_alias_names() {
  alias | sed -E "s/^alias[[:space:]]+--[[:space:]]+([^=]+)=.*/\1/; t; s/^alias[[:space:]]+([^=]+)=.*/\1/" | LC_ALL=C sort -u
}

_alias_register_aliases_for_category() {
  local category="$1"
  local aliases_before="$2"
  local aliases_after="$3"
  local alias_name=""
  local mapped_category=""

  while IFS= read -r alias_name; do
    [ -z "${alias_name}" ] && continue

    if ! grep -Fxq -- "${alias_name}" <<< "${aliases_before}"; then
      if [ -n "${BASH_ALIAS_ALIAS_CATEGORY[${alias_name}]:-}" ]; then
        continue
      fi
      mapped_category="${category}"
      case "${alias_name}" in
        _alias_*)
          mapped_category="setup"
          _alias_add_category_if_missing "${mapped_category}"
          BASH_ALIAS_CATEGORY_ENABLED["${mapped_category}"]=1
          ;;
      esac
      BASH_ALIAS_ALIAS_CATEGORY["${alias_name}"]="${mapped_category}"
    fi
  done <<< "${aliases_after}"
}

_alias_apply_config_layer() {
  local file_path="$1"
  local line=""
  local entry=""

  [ -f "${file_path}" ] || return 0

  while IFS= read -r line; do
    if [[ "${line}" =~ ^[[:space:]]*([0-9][0-9]-[[:alnum:]_.-]+\.sh)[[:space:]]*$ ]]; then
      entry="${BASH_REMATCH[1]}"
      _alias_add_module_if_missing "${entry}"
      _alias_module_enabled["${entry}"]=1
      continue
    fi

    if [[ "${line}" =~ ^[[:space:]]*#[[:space:]]*([0-9][0-9]-[[:alnum:]_.-]+\.sh)[[:space:]]*$ ]]; then
      entry="${BASH_REMATCH[1]}"
      _alias_add_module_if_missing "${entry}"
      _alias_module_enabled["${entry}"]=0
      continue
    fi
  done < "${file_path}"
}

_alias_apply_settings_layer() {
  local file_path="$1"

  [ -f "${file_path}" ] || return 0
  # shellcheck disable=SC1090
  source "${file_path}"
}

if [ "${#_alias_settings_layers[@]}" -gt 0 ]; then
  for _layer in "${_alias_settings_layers[@]}"; do
    _alias_apply_settings_layer "${_layer}"
  done
fi

_alias_init_categories

if [ "${#_alias_config_layers[@]}" -gt 0 ]; then
  for _layer in "${_alias_config_layers[@]}"; do
    _alias_apply_config_layer "${_layer}"
  done

  for _entry in "${_alias_module_order[@]}"; do
    [ "${_alias_module_enabled[${_entry}]:-0}" -eq 1 ] || continue

    _full_path="${_alias_base_dir}/alias_files/${_entry}"
    _category="misc"

    if declare -F alias_category_for_module >/dev/null 2>&1; then
      _category="$(alias_category_for_module "${_entry}")"
    fi

    _alias_add_category_if_missing "${_category}"
    BASH_ALIAS_CATEGORY_ENABLED["${_category}"]=1

    if [ -f "${_full_path}" ]; then
      _aliases_before="$(_alias_collect_alias_names)"
      # shellcheck disable=SC1090
      if ! source "${_full_path}"; then
        echo "Fehler: Modul konnte nicht geladen werden: ${_entry}" >&2
        return 1 2>/dev/null || exit 1
      fi
      _aliases_after="$(_alias_collect_alias_names)"
      _alias_register_aliases_for_category "${_category}" "${_aliases_before}" "${_aliases_after}"
    fi

    unset _full_path _category _aliases_before _aliases_after
  done
else
  echo "Hinweis: Konfigurationsdatei fehlt: ${_alias_config_file_default} (Basis), optional ${_alias_config_file_local}, ${_alias_config_file_user}" >&2
fi

_alias_sort_categories

unset _entry _layer _full_path _category _aliases_before _aliases_after line entry
unset _alias_settings_layers _alias_config_layers _alias_module_order _alias_module_enabled
unset _alias_config_file_default _alias_config_file_local _alias_config_file_user _alias_settings_file_default _alias_settings_file_local _alias_settings_file_user _alias_base_dir _alias_categories_file
unset -f _alias_add_category_if_missing _alias_add_module_if_missing _alias_sort_key_for_category _alias_sort_categories _alias_init_categories _alias_collect_alias_names _alias_register_aliases_for_category _alias_apply_config_layer _alias_apply_settings_layer
