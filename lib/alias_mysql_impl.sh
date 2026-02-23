# shellcheck shell=bash

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/alias_i18n.sh"

mysql_databases() {
  mysql -e "SHOW DATABASES;"
}

mysql_dump() {
  local db="${1:-}"
  local out="${2:-}"
  local script_path=""

  if [ -z "${db}" ]; then
    echo "$(_alias_i18n_text "mysql_impl.usage_dump")"
    return 1
  fi

  script_path="${BASH_ALIAS_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/scripts/mysql_dump.sh"
  if [ ! -f "${script_path}" ]; then
    printf '%s\n' "$(_alias_i18n_text "mysql.common.err_script_not_found" "${script_path}")"
    return 1
  fi

  bash "${script_path}" "${db}" "${out}"
}

mysql_dump_gz() {
  local db="${1:-}"
  local out="${2:-}"
  local script_path=""

  if [ -z "${db}" ]; then
    echo "$(_alias_i18n_text "mysql_impl.usage_dump_gz")"
    return 1
  fi

  script_path="${BASH_ALIAS_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/scripts/mysql_dump.sh"
  if [ ! -f "${script_path}" ]; then
    printf '%s\n' "$(_alias_i18n_text "mysql.common.err_script_not_found" "${script_path}")"
    return 1
  fi

  bash "${script_path}" --gzip "${db}" "${out}"
}
