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
  _alias_i18n_text "guided_setup.$1"
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
