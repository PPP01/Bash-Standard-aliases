#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
_loader="${_repo_dir}/bash_alias_std.sh"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"

if [ ! -f "${_loader}" ]; then
  printf '%s\n' "$(_alias_i18n_pick "FAIL: Loader nicht gefunden: ${_loader}" "FAIL: Loader not found: ${_loader}")"
  exit 1
fi

# shellcheck disable=SC1090
source "${_loader}"

declare -A _map_first=()
for _name in "${!BASH_ALIAS_ALIAS_CATEGORY[@]}"; do
  _map_first["${_name}"]="${BASH_ALIAS_ALIAS_CATEGORY[${_name}]}"
done

if [ "${#_map_first[@]}" -eq 0 ]; then
  echo "$(_alias_i18n_pick "FAIL: Erstes Laden ergab keine Alias-Kategorie-Zuordnungen." "FAIL: First load produced no alias-category mappings.")"
  exit 1
fi

unset BASH_ALIAS_STD_LOADED
# shellcheck disable=SC1090
source "${_loader}"

if [ "${#BASH_ALIAS_ALIAS_CATEGORY[@]}" -eq 0 ]; then
  echo "$(_alias_i18n_pick "FAIL: Reload ergab keine Alias-Kategorie-Zuordnungen." "FAIL: Reload produced no alias-category mappings.")"
  exit 1
fi

for _name in "${!_map_first[@]}"; do
  if [ -z "${BASH_ALIAS_ALIAS_CATEGORY[${_name}]:-}" ]; then
    printf '%s\n' "$(_alias_i18n_pick "FAIL: Alias nach Reload nicht mehr registriert: ${_name}" "FAIL: Alias no longer registered after reload: ${_name}")"
    exit 1
  fi

  if [ "${BASH_ALIAS_ALIAS_CATEGORY[${_name}]}" != "${_map_first[${_name}]}" ]; then
    printf '%s\n' "$(_alias_i18n_pick "FAIL: Kategorie-Änderung nach Reload für ${_name}: ${_map_first[${_name}]} -> ${BASH_ALIAS_ALIAS_CATEGORY[${_name}]}" "FAIL: Category changed after reload for ${_name}: ${_map_first[${_name}]} -> ${BASH_ALIAS_ALIAS_CATEGORY[${_name}]}")"
    exit 1
  fi
done

echo "$(_alias_i18n_pick "OK: Alias-Kategorie-Mapping bleibt nach Reload konsistent." "OK: Alias-category mapping remains consistent after reload.")"
