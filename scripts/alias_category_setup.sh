#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
_default_conf="${_repo_dir}/alias_files.conf"
_local_conf="${_repo_dir}/alias_files.local.conf"
_categories_file="${_repo_dir}/alias_categories.sh"

declare -A _module_visible_cache=()

if [ ! -f "${_default_conf}" ]; then
  echo "Fehler: alias_files.conf nicht gefunden: ${_default_conf}"
  exit 1
fi

if [ -f "${_categories_file}" ]; then
  # shellcheck disable=SC1090
  source "${_categories_file}"
fi

if [ -f "${_local_conf}" ]; then
  _target_conf="${_local_conf}"
else
  cp "${_default_conf}" "${_local_conf}"
  _target_conf="${_local_conf}"
  echo "Lokale Konfiguration erzeugt: ${_local_conf}"
fi

_escape_regex() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\/]/\\&/g'
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
  local regex=""
  local total=0
  local active=0

  if declare -F alias_modules_for_category >/dev/null 2>&1; then
    modules="$(alias_modules_for_category "${category}")"
  fi

  for module in ${modules}; do
    _module_visible_for_user "${module}" || continue
    total=$((total + 1))
    regex="$(_escape_regex "${module}")"
    if grep -Eq "^[[:space:]]*${regex}[[:space:]]*$" "${_target_conf}"; then
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

_enable_module() {
  local module="$1"
  local regex=""

  regex="$(_escape_regex "${module}")"

  if grep -Eq "^[[:space:]]*${regex}[[:space:]]*$" "${_target_conf}"; then
    return 0
  fi

  if grep -Eq "^[[:space:]]*#[[:space:]]*${regex}[[:space:]]*$" "${_target_conf}"; then
    sed -i -E "s|^[[:space:]]*#[[:space:]]*${regex}[[:space:]]*$|${module}|" "${_target_conf}"
  else
    printf '\n%s\n' "${module}" >> "${_target_conf}"
  fi
}

_disable_module() {
  local module="$1"
  local regex=""

  regex="$(_escape_regex "${module}")"
  sed -i -E "s|^[[:space:]]*${regex}[[:space:]]*$|# ${module}|" "${_target_conf}"
}

_toggle_category() {
  local category="$1"
  local state=""
  local modules=""
  local module=""

  state="$(_category_state "${category}")"
  if declare -F alias_modules_for_category >/dev/null 2>&1; then
    modules="$(alias_modules_for_category "${category}")"
  fi

  if [ "${state}" = "on" ]; then
    for module in ${modules}; do
      _module_visible_for_user "${module}" || continue
      _disable_module "${module}"
    done
    echo "Kategorie '${category}' ausgeschaltet."
  else
    for module in ${modules}; do
      _module_visible_for_user "${module}" || continue
      _enable_module "${module}"
    done
    echo "Kategorie '${category}' eingeschaltet."
  fi
}

_list_categories() {
  local idx=1
  local category=""
  local state=""

  echo ""
  echo "Kategorien in ${_target_conf}:"

  if declare -F alias_categories_list >/dev/null 2>&1; then
    while IFS= read -r category; do
      [ -z "${category}" ] && continue
      _category_is_visible "${category}" || continue
      state="$(_category_state "${category}")"
      printf ' %2d) %-12s [%s]\n' "${idx}" "${category}" "${state}"
      idx=$((idx + 1))
    done < <(alias_categories_list)
  else
    echo "Keine Kategorien definiert."
  fi

  echo "  q) Ende"
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

while true; do
  _list_categories
  read -r -p "Kategorie-Nummer zum Umschalten (q zum Beenden): " _choice

  case "${_choice}" in
    q|Q|quit|QUIT|exit|EXIT)
      break
      ;;
    ''|*[!0-9]*)
      echo "Bitte eine gueltige Nummer eingeben."
      ;;
    *)
      _category="$(_resolve_category_by_index "${_choice}")" || {
        echo "Nummer ungueltig."
        continue
      }
      _toggle_category "${_category}"
      ;;
  esac

done

echo "Fertig. Fuer die aktuelle Shell ggf. '_self_reload' oder 'source ~/.bashrc' ausfuehren."
