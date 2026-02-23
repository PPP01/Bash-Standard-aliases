#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
_de_file="${_repo_dir}/i18n/messages.de.tsv"
_en_file="${_repo_dir}/i18n/messages.en.tsv"
_out_file="${_repo_dir}/lib/alias_i18n_cache.sh"

declare -A _de=()
declare -A _en=()

_read_tsv_into_map() {
  local file_path="$1"
  local map_name="$2"
  local line=""
  local key=""
  local value=""

  [ -f "${file_path}" ] || {
    echo "Missing file: ${file_path}" >&2
    return 1
  }

  while IFS= read -r line || [ -n "${line}" ]; do
    [ -n "${line}" ] || continue
    case "${line}" in
      \#*) continue ;;
    esac

    if [[ "${line}" != *$'\t'* ]]; then
      echo "Invalid TSV (missing TAB): ${file_path}: ${line}" >&2
      return 1
    fi

    key="${line%%$'\t'*}"
    value="${line#*$'\t'}"
    [ -n "${key}" ] || {
      echo "Invalid TSV (empty key): ${file_path}: ${line}" >&2
      return 1
    }

    case "${map_name}" in
      de) _de["${key}"]="${value}" ;;
      en) _en["${key}"]="${value}" ;;
      *)
        echo "Unknown map: ${map_name}" >&2
        return 1
        ;;
    esac
  done < "${file_path}"
}

_read_tsv_into_map "${_de_file}" de
_read_tsv_into_map "${_en_file}" en

{
  echo "# shellcheck shell=bash"
  echo "# GENERATED FILE - DO NOT EDIT"
  echo "# source: i18n/messages.de.tsv + i18n/messages.en.tsv"
  echo ""
  echo "declare -gA BASH_ALIAS_I18N_DE=("
  while IFS= read -r key; do
    printf "  [%q]=%q\n" "${key}" "${_de[${key}]}"
  done < <(printf '%s\n' "${!_de[@]}" | LC_ALL=C sort)
  echo ")"
  echo ""
  echo "declare -gA BASH_ALIAS_I18N_EN=("
  while IFS= read -r key; do
    printf "  [%q]=%q\n" "${key}" "${_en[${key}]}"
  done < <(printf '%s\n' "${!_en[@]}" | LC_ALL=C sort)
  echo ")"
} > "${_out_file}"

echo "Generated: ${_out_file}"
