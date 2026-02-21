# shellcheck shell=bash

declare -g BASH_ALIAS_HELP_IMPL_LOADED=0

_alias_help_repo_dir() {
  if [ -n "${BASH_ALIAS_REPO_DIR:-}" ]; then
    printf '%s' "${BASH_ALIAS_REPO_DIR}"
    return 0
  fi
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

_alias_help_load_impl() {
  local repo_dir=""
  local impl_path=""

  if [ "${BASH_ALIAS_HELP_IMPL_LOADED}" -eq 1 ]; then
    return 0
  fi

  repo_dir="$(_alias_help_repo_dir)" || return 1
  impl_path="${repo_dir}/lib/alias_help_impl.sh"

  if [ ! -f "${impl_path}" ]; then
    echo "Fehler: Hilfe-Implementierung nicht gefunden: ${impl_path}" >&2
    return 1
  fi

  # shellcheck disable=SC1090
  source "${impl_path}" || return 1
  BASH_ALIAS_HELP_IMPL_LOADED=1
}

_alias_help_dispatch() {
  local fn_name="$1"
  local before=""
  local after=""
  shift

  before="$(declare -f "${fn_name}" 2>/dev/null || true)"
  _alias_help_load_impl || return 1
  after="$(declare -f "${fn_name}" 2>/dev/null || true)"

  if [ -z "${after}" ] || [ "${before}" = "${after}" ]; then
    echo "Fehler: Hilfe-Funktion '${fn_name}' konnte nicht geladen werden." >&2
    return 1
  fi

  "${fn_name}" "$@"
}

show_aliases_functions() {
  _alias_help_dispatch "show_aliases_functions" "$@"
}

a() {
  _alias_help_dispatch "a" "$@"
}

alias_self_test_reload() {
  _alias_help_dispatch "alias_self_test_reload" "$@"
}

_alias_help_category_completion_lazy() {
  _alias_help_load_impl || return 0
  if declare -F _alias_category_completion >/dev/null 2>&1; then
    _alias_category_completion
  fi
}

complete -F _alias_help_category_completion_lazy a
alias _self_test_reload='alias_self_test_reload'
