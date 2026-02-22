# shellcheck shell=bash

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

_alias_i18n_pick() {
  local de_text="$1"
  local en_text="$2"
  if _alias_i18n_is_de; then
    printf '%s' "${de_text}"
  else
    printf '%s' "${en_text}"
  fi
}
