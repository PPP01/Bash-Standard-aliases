# shellcheck shell=bash
# Lokale Overrides

alias _alias_reload='alias_repo_reload'

declare -g BASH_ALIAS_OVERRIDES_EDIT_IMPL_LOADED=0
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/alias_i18n.sh"

_alias_overrides_repo_dir() {
  if [ -n "${BASH_ALIAS_REPO_DIR:-}" ]; then
    printf '%s' "${BASH_ALIAS_REPO_DIR}"
    return 0
  fi
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

_alias_overrides_load_edit_impl() {
  local repo_dir=""
  local impl_path=""

  if [ "${BASH_ALIAS_OVERRIDES_EDIT_IMPL_LOADED}" -eq 1 ]; then
    return 0
  fi

  repo_dir="$(_alias_overrides_repo_dir)" || return 1
  impl_path="${repo_dir}/lib/alias_overrides_edit_impl.sh"

  if [ ! -f "${impl_path}" ]; then
    printf '%s\n' "$(_alias_i18n_pick "Fehler: Overrides-Implementierung nicht gefunden: ${impl_path}" "Error: Overrides implementation not found: ${impl_path}")" >&2
    return 1
  fi

  # shellcheck disable=SC1090
  source "${impl_path}" || return 1
  BASH_ALIAS_OVERRIDES_EDIT_IMPL_LOADED=1
}

alias_self_edit() {
  local before=""
  local after=""

  before="$(declare -f alias_self_edit 2>/dev/null || true)"
  _alias_overrides_load_edit_impl || return 1
  after="$(declare -f alias_self_edit 2>/dev/null || true)"

  if [ -z "${after}" ] || [ "${before}" = "${after}" ]; then
    printf '%s\n' "$(_alias_i18n_pick "Fehler: alias_self_edit konnte nicht geladen werden." "Error: Failed to load alias_self_edit.")" >&2
    return 1
  fi

  alias_self_edit "$@"
}

alias _alias_edit='alias_self_edit'

_alias_mark_own_category_from_file() {
  local file_path="$1"
  local alias_name=""

  [ -f "${file_path}" ] || return 0

  if declare -F _alias_add_category_if_missing >/dev/null 2>&1; then
    _alias_add_category_if_missing "_own"
  fi
  BASH_ALIAS_CATEGORY_ENABLED["_own"]=1

  while IFS= read -r alias_name; do
    [ -z "${alias_name}" ] && continue
    if builtin alias -- "${alias_name}" >/dev/null 2>&1; then
      BASH_ALIAS_ALIAS_CATEGORY["${alias_name}"]="_own"
    fi
  done < <(sed -n -E 's/^[[:space:]]*alias[[:space:]]+([^=[:space:]]+)=.*/\1/p' "${file_path}" | LC_ALL=C sort -u)
}

_alias_enable_own_category_if_custom_files_exist() {
  local repo_alias_file=""
  local repo_help_file=""
  local home_alias_file="${HOME}/.bash_aliases_specific"
  local home_help_file="${HOME}/.bash_aliases_specific.md"

  if [ -n "${BASH_ALIAS_REPO_DIR:-}" ]; then
    repo_alias_file="${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific"
    repo_help_file="${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific.md"
  fi

  if [ -f "${home_alias_file}" ] || [ -f "${home_help_file}" ] || { [ -n "${repo_alias_file}" ] && [ -f "${repo_alias_file}" ]; } || { [ -n "${repo_help_file}" ] && [ -f "${repo_help_file}" ]; }; then
    if declare -F _alias_add_category_if_missing >/dev/null 2>&1; then
      _alias_add_category_if_missing "_own"
    fi
    BASH_ALIAS_CATEGORY_ENABLED["_own"]=1
  fi
}

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -f "${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific" ]; then
  # shellcheck disable=SC1090
  source "${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific"
  _alias_mark_own_category_from_file "${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific"
fi

if [ -f "${HOME}/.bash_aliases_specific" ]; then
  # shellcheck disable=SC1090
  source "${HOME}/.bash_aliases_specific"
  _alias_mark_own_category_from_file "${HOME}/.bash_aliases_specific"
fi

_alias_enable_own_category_if_custom_files_exist
