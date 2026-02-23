# shellcheck shell=bash

declare -g BASH_ALIAS_I18N_CACHE_LOADED=0
declare -gA BASH_ALIAS_I18N_DE=()
declare -gA BASH_ALIAS_I18N_EN=()

_alias_i18n_lang() {
  local locale="${BASH_ALIAS_LOCALE:-de}"
  printf '%s' "${locale%%_*}"
}

_alias_i18n_is_de() {
  case "$(_alias_i18n_lang)" in
    de*) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_i18n_load_cache() {
  local cache_file=""

  [ "${BASH_ALIAS_I18N_CACHE_LOADED}" -eq 0 ] || return 0
  BASH_ALIAS_I18N_CACHE_LOADED=1

  cache_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/alias_i18n_cache.sh"
  if [ -f "${cache_file}" ]; then
    # shellcheck disable=SC1090
    source "${cache_file}"
  fi
}

_alias_i18n_text() {
  local key="$1"
  shift || true

  local lang=""
  local template=""

  _alias_i18n_load_cache
  lang="$(_alias_i18n_lang)"

  case "${lang}" in
    de*)
      template="${BASH_ALIAS_I18N_DE[${key}]:-${BASH_ALIAS_I18N_EN[${key}]:-${key}}}"
      ;;
    *)
      template="${BASH_ALIAS_I18N_EN[${key}]:-${BASH_ALIAS_I18N_DE[${key}]:-${key}}}"
      ;;
  esac

  if [ "$#" -gt 0 ]; then
    printf "${template}" "$@"
  else
    printf '%s' "${template}"
  fi
}

_alias_i18n_has_key() {
  local key="$1"
  _alias_i18n_load_cache
  [ -n "${BASH_ALIAS_I18N_DE[${key}]+_}" ] || [ -n "${BASH_ALIAS_I18N_EN[${key}]+_}" ]
}

_alias_i18n_pick() {
  # Backward compatibility:
  # - 1 arg: treat as i18n key
  # - 2 args: legacy DE/EN inline texts
  if [ "$#" -eq 1 ]; then
    _alias_i18n_text "$1"
    return
  fi
  local de_text="${1:-}"
  local en_text="${2:-}"
  _alias_i18n_is_de && printf '%s' "${de_text}" || printf '%s' "${en_text}"
}
