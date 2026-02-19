# shellcheck shell=bash
# version 2026-02-19
# Loader fuer modulare Aliase mit konfigurierbarer Modul-Liste

_alias_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_alias_config_file="${_alias_base_dir}/alias_files.conf"

if [ -f "${_alias_config_file}" ]; then
  while IFS='|' read -r _state _file _description; do
    # Leerzeilen und Kommentare ignorieren
    [ -z "${_state}" ] && continue
    case "${_state}" in
      \#*) continue ;;
    esac

    # Nur aktivierte Module laden
    if [ "${_state}" = "enabled" ] && [ -n "${_file}" ]; then
      _full_path="${_alias_base_dir}/alias_files/${_file}"
      if [ -f "${_full_path}" ]; then
        # shellcheck disable=SC1090
        source "${_full_path}"
      fi
      unset _full_path
    fi
  done < "${_alias_config_file}"
else
  echo "Hinweis: Konfigurationsdatei fehlt: ${_alias_config_file}" >&2
fi

unset _state _file _description _alias_config_file _alias_base_dir
