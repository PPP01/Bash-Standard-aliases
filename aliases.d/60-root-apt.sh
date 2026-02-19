# shellcheck shell=bash

if [ "${EUID}" -eq 0 ]; then
  update-all() {
    local apt_yes=()

    if [[ "${1:-}" == "-y" ]]; then
      apt_yes=(-y)
    elif [[ $# -gt 0 ]]; then
      echo "Usage: update-all [-y]"
      return 2
    fi

    sudo apt update || return 1

    local upg_count
    upg_count="$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)"

    if [[ "${upg_count}" -eq 0 ]]; then
      echo "Keine neuen Pakete vorhanden - breche ab."
      return 0
    fi

    echo "Upgrades verfuegbar (${upg_count}):"
    apt list --upgradable

    sudo apt upgrade "${apt_yes[@]}" || return 1
    sudo apt autoremove "${apt_yes[@]}"

    echo "Fertig."
  }

  alias agi='apt install'
  alias agr='apt remove'
  alias acs='apt search'
  alias agu='apt update'
  alias agg='apt upgrade'
  alias aga='apt autoremove'
  alias agl='apt list --upgradable'
  alias aua='update-all'
fi
