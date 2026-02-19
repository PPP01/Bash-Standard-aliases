# shellcheck shell=bash
# version 2026-02-19
# Modulare Loader-Datei fuer gemeinsame Aliase

_alias_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_alias_modules=(
  "aliases.d/00-core.sh"
  "aliases.d/10-navigation.sh"
  "aliases.d/20-files.sh"
  "aliases.d/30-process.sh"
  "aliases.d/40-network.sh"
  "aliases.d/50-root-journal.sh"
  "aliases.d/60-root-apt.sh"
  "aliases.d/70-root-systemd.sh"
  "aliases.d/90-overrides.sh"
  "aliases.d/99-help.sh"
)

for _module in "${_alias_modules[@]}"; do
  if [ -f "${_alias_base_dir}/${_module}" ]; then
    # shellcheck disable=SC1090
    source "${_alias_base_dir}/${_module}"
  fi
done

unset _module _alias_modules _alias_base_dir
