# shellcheck shell=bash

_alias_module_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_alias_help_lib="${BASH_ALIAS_REPO_DIR:-${_alias_module_base_dir}}/lib/alias_help.sh"

if [ -f "${_alias_help_lib}" ]; then
  # shellcheck disable=SC1090
  source "${_alias_help_lib}"
else
  echo "Fehler: Hilfe-Library nicht gefunden: ${_alias_help_lib}" >&2
fi

unset _alias_module_base_dir _alias_help_lib