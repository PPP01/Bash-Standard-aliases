# shellcheck shell=bash

mysql_databases() {
  mysql -e "SHOW DATABASES;"
}

mysql_dump() {
  local db="${1:-}"
  local out="${2:-}"
  local script_path=""

  if [ -z "${db}" ]; then
    echo "Usage: mysql_dump <database> [output.sql]"
    return 1
  fi

  script_path="${BASH_ALIAS_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/scripts/mysql_dump.sh"
  if [ ! -f "${script_path}" ]; then
    echo "Fehler: Script nicht gefunden: ${script_path}"
    return 1
  fi

  bash "${script_path}" "${db}" "${out}"
}

mysql_dump_gz() {
  local db="${1:-}"
  local out="${2:-}"
  local script_path=""

  if [ -z "${db}" ]; then
    echo "Usage: mysql_dump_gz <database> [output.sql.gz]"
    return 1
  fi

  script_path="${BASH_ALIAS_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/scripts/mysql_dump.sh"
  if [ ! -f "${script_path}" ]; then
    echo "Fehler: Script nicht gefunden: ${script_path}"
    return 1
  fi

  bash "${script_path}" --gzip "${db}" "${out}"
}
