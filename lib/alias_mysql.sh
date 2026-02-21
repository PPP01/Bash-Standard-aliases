# shellcheck shell=bash

declare -g BASH_ALIAS_MYSQL_IMPL_LOADED="${BASH_ALIAS_MYSQL_IMPL_LOADED:-0}"

# MySQL CLI shortcuts (erwartet passende Rechte oder ~/.my.cnf)
alias my='mysql'
alias mya='mysqladmin'
alias myping='mysqladmin ping'

_alias_mysql_repo_dir() {
  if [ -n "${BASH_ALIAS_REPO_DIR:-}" ]; then
    printf '%s' "${BASH_ALIAS_REPO_DIR}"
    return 0
  fi
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

_alias_mysql_load_impl() {
  local repo_dir=""
  local impl_path=""

  if [ "${BASH_ALIAS_MYSQL_IMPL_LOADED}" -eq 1 ]; then
    return 0
  fi

  repo_dir="$(_alias_mysql_repo_dir)" || return 1
  impl_path="${repo_dir}/lib/alias_mysql_impl.sh"

  if [ ! -f "${impl_path}" ]; then
    echo "Fehler: MySQL-Implementierung nicht gefunden: ${impl_path}" >&2
    return 1
  fi

  # shellcheck disable=SC1090
  source "${impl_path}" || return 1
  BASH_ALIAS_MYSQL_IMPL_LOADED=1
}

_alias_mysql_dispatch() {
  local fn_name="$1"
  local before=""
  local after=""
  shift

  before="$(declare -f "${fn_name}" 2>/dev/null || true)"
  _alias_mysql_load_impl || return 1
  after="$(declare -f "${fn_name}" 2>/dev/null || true)"

  if [ -z "${after}" ] || [ "${before}" = "${after}" ]; then
    echo "Fehler: MySQL-Funktion '${fn_name}' konnte nicht geladen werden." >&2
    return 1
  fi

  "${fn_name}" "$@"
}

mysql_databases() {
  _alias_mysql_dispatch "mysql_databases" "$@"
}

mysql_dump() {
  _alias_mysql_dispatch "mysql_dump" "$@"
}

mysql_dump_gz() {
  _alias_mysql_dispatch "mysql_dump_gz" "$@"
}
