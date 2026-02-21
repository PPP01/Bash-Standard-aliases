#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
_loader="${_repo_dir}/bash_alias_std.sh"

if [ ! -f "${_loader}" ]; then
  echo "FAIL: Loader nicht gefunden: ${_loader}"
  exit 1
fi

# shellcheck disable=SC1090
source "${_loader}"

declare -A _map_first=()
for _name in "${!BASH_ALIAS_ALIAS_CATEGORY[@]}"; do
  _map_first["${_name}"]="${BASH_ALIAS_ALIAS_CATEGORY[${_name}]}"
done

if [ "${#_map_first[@]}" -eq 0 ]; then
  echo "FAIL: Erstes Laden ergab keine Alias-Kategorie-Zuordnungen."
  exit 1
fi

unset BASH_ALIAS_STD_LOADED
# shellcheck disable=SC1090
source "${_loader}"

if [ "${#BASH_ALIAS_ALIAS_CATEGORY[@]}" -eq 0 ]; then
  echo "FAIL: Reload ergab keine Alias-Kategorie-Zuordnungen."
  exit 1
fi

for _name in "${!_map_first[@]}"; do
  if [ -z "${BASH_ALIAS_ALIAS_CATEGORY[${_name}]:-}" ]; then
    echo "FAIL: Alias nach Reload nicht mehr registriert: ${_name}"
    exit 1
  fi

  if [ "${BASH_ALIAS_ALIAS_CATEGORY[${_name}]}" != "${_map_first[${_name}]}" ]; then
    echo "FAIL: Kategorie-Aenderung nach Reload fuer ${_name}: ${_map_first[${_name}]} -> ${BASH_ALIAS_ALIAS_CATEGORY[${_name}]}"
    exit 1
  fi
done

echo "OK: Alias-Kategorie-Mapping bleibt nach Reload konsistent."
