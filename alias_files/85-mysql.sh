# shellcheck shell=bash

# MySQL CLI shortcuts (erwartet passende Rechte oder ~/.my.cnf)
alias my='mysql'
alias mya='mysqladmin'
alias myping='mysqladmin ping'

mysql_databases() {
  mysql -e "SHOW DATABASES;"
}

mysql_dump() {
  local db="$1"
  local out="$2"

  if [ -z "${db}" ]; then
    echo "Usage: mysql_dump <database> [output.sql]"
    return 1
  fi

  if [ -z "${out}" ]; then
    out="${db}_$(date +%Y%m%d_%H%M%S).sql"
  fi

  mysqldump --single-transaction --quick --routines --triggers "${db}" > "${out}"
}

mysql_dump_gz() {
  local db="$1"
  local out="$2"

  if [ -z "${db}" ]; then
    echo "Usage: mysql_dump_gz <database> [output.sql.gz]"
    return 1
  fi

  if [ -z "${out}" ]; then
    out="${db}_$(date +%Y%m%d_%H%M%S).sql.gz"
  fi

  mysqldump --single-transaction --quick --routines --triggers "${db}" | gzip -c > "${out}"
}
