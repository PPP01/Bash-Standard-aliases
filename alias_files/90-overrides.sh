# shellcheck shell=bash

_alias_module_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_alias_overrides_lib="${BASH_ALIAS_REPO_DIR:-${_alias_module_base_dir}}/lib/alias_overrides.sh"

if [ -f "${_alias_overrides_lib}" ]; then
  # shellcheck disable=SC1090
  source "${_alias_overrides_lib}"
else
  echo "Fehler: Overrides-Library nicht gefunden: ${_alias_overrides_lib}" >&2
fi

unset _alias_module_base_dir _alias_overrides_lib