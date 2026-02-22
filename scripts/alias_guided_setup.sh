#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="${BASH_ALIAS_REPO_DIR:-$(cd "${_script_dir}/.." && pwd)}"
_color_setup_script="${_repo_dir}/scripts/alias_color_scheme_setup.sh"
_category_setup_script="${_repo_dir}/scripts/alias_category_setup.sh"

main() {
  echo "=== Guided Setup ==="
  echo "1) Farbschema"
  echo "2) Kategorien"
  echo ""

  if [ ! -f "${_color_setup_script}" ]; then
    echo "Fehler: Script nicht gefunden: ${_color_setup_script}"
    return 1
  fi
  if [ ! -f "${_category_setup_script}" ]; then
    echo "Fehler: Script nicht gefunden: ${_category_setup_script}"
    return 1
  fi

  echo "Schritt 1/2: Farbschema einstellen"
  bash "${_color_setup_script}" || return 1
  echo ""

  echo "Schritt 2/2: Kategorien konfigurieren"
  bash "${_category_setup_script}" || return 1
  echo ""

  echo "Guided Setup abgeschlossen."
}

main "$@"
