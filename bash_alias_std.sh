# shellcheck shell=bash
# version 2026-02-19
# Loader fuer modulare Aliase mit konfigurierbarer Modul-Liste

# Schutz vor doppeltem Laden in derselben Shell-Session.
if [ -n "${BASH_ALIAS_STD_LOADED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
BASH_ALIAS_STD_LOADED=1

_alias_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_alias_config_file_default="${_alias_base_dir}/alias_files.conf"
_alias_config_file_local="${_alias_base_dir}/alias_files.local.conf"
# Von Modulen/Funktionen nutzbar, um den Repo-Ordner sicher zu finden.
BASH_ALIAS_REPO_DIR="${_alias_base_dir}"

if [ -f "${_alias_config_file_local}" ]; then
  _alias_config_file="${_alias_config_file_local}"
elif [ -f "${_alias_config_file_default}" ]; then
  _alias_config_file="${_alias_config_file_default}"
else
  _alias_config_file=""
fi

if [ -n "${_alias_config_file}" ]; then
  while IFS= read -r _entry; do
    # Leerzeilen und Kommentare ignorieren
    [ -z "${_entry}" ] && continue
    case "${_entry}" in
      \#*) continue ;;
    esac

    # Aktive Zeilen enthalten nur den Dateinamen aus alias_files/
    _full_path="${_alias_base_dir}/alias_files/${_entry}"

    if [ -f "${_full_path}" ]; then
      # shellcheck disable=SC1090
      source "${_full_path}"
    fi
    unset _full_path
  done < "${_alias_config_file}"
else
  echo "Hinweis: Konfigurationsdatei fehlt: ${_alias_config_file_local} oder ${_alias_config_file_default}" >&2
fi

unset _entry _alias_config_file _alias_config_file_default _alias_config_file_local _alias_base_dir
