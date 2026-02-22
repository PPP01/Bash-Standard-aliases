#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="${BASH_ALIAS_REPO_DIR:-$(cd "${_script_dir}/.." && pwd)}"
_color_setup_script="${_repo_dir}/scripts/alias_color_scheme_setup.sh"
_category_setup_script="${_repo_dir}/scripts/alias_category_setup.sh"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"

_text() {
  local key="$1"
  case "${key}" in
    title) _alias_i18n_pick "=== Geführtes Setup ===" "=== Guided setup ===" ;;
    step_1) _alias_i18n_pick "1) Farbschema" "1) Color scheme" ;;
    step_2) _alias_i18n_pick "2) Kategorien" "2) Categories" ;;
    err_script_missing) _alias_i18n_pick "Fehler: Script nicht gefunden: %s" "Error: Script not found: %s" ;;
    run_step_1) _alias_i18n_pick "Schritt 1/2: Farbschema einstellen" "Step 1/2: configure color scheme" ;;
    run_step_2) _alias_i18n_pick "Schritt 2/2: Kategorien konfigurieren" "Step 2/2: configure categories" ;;
    done) _alias_i18n_pick "Geführtes Setup abgeschlossen." "Guided setup completed." ;;
    *) printf '%s' "${key}" ;;
  esac
}

main() {
  echo "$(_text title)"
  echo "$(_text step_1)"
  echo "$(_text step_2)"
  echo ""

  if [ ! -f "${_color_setup_script}" ]; then
    printf "$(_text err_script_missing)\n" "${_color_setup_script}"
    return 1
  fi
  if [ ! -f "${_category_setup_script}" ]; then
    printf "$(_text err_script_missing)\n" "${_category_setup_script}"
    return 1
  fi

  echo "$(_text run_step_1)"
  bash "${_color_setup_script}" || return 1
  echo ""

  echo "$(_text run_step_2)"
  bash "${_category_setup_script}" || return 1
  echo ""

  echo "$(_text done)"
}

main "$@"
