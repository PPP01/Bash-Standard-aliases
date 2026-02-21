#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

use_gzip=0
if [ "${1:-}" = "--gzip" ]; then
  use_gzip=1
  shift
fi

db="${1:-}"
out="${2:-}"

if [ -z "${db}" ]; then
  echo "Usage: mysql_dump.sh [--gzip] <database> [output]" >&2
  exit 1
fi

if [ "${use_gzip}" -eq 1 ]; then
  if [ -z "${out}" ]; then
    out="${db}_$(date +%Y%m%d_%H%M%S).sql.gz"
  fi
  mysqldump --single-transaction --quick --routines --triggers "${db}" | gzip -c > "${out}"
else
  if [ -z "${out}" ]; then
    out="${db}_$(date +%Y%m%d_%H%M%S).sql"
  fi
  mysqldump --single-transaction --quick --routines --triggers "${db}" > "${out}"
fi