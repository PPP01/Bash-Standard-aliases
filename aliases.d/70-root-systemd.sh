# shellcheck shell=bash

if [ "${EUID}" -eq 0 ]; then
  start() {
    if [ -z "$1" ]; then echo "Welcher Service?"; return 1; fi
    sudo systemctl start "$1" && systemctl status "$1" --no-pager
  }

  restart() {
    if [ -z "$1" ]; then echo "Welcher Service?"; return 1; fi
    sudo systemctl restart "$1" && systemctl status "$1" --no-pager
  }

  stop() {
    if [ -z "$1" ]; then echo "Welcher Service?"; return 1; fi
    sudo systemctl stop "$1" && systemctl status "$1" --no-pager
  }

  reload() {
    if [ -z "$1" ]; then echo "Welcher Service?"; return 1; fi
    sudo systemctl reload "$1" && systemctl status "$1" --no-pager
  }

  status() {
    if [ -z "$1" ]; then echo "Welcher Service?"; return 1; fi
    systemctl status "$1" --no-pager
  }

  _systemd_short_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local units
    units="$(systemctl list-unit-files --no-legend --full 2>/dev/null | awk '{print $1}')"
    COMPREPLY=( $(compgen -W "${units}" -- "${cur}") )
  }

  complete -F _systemd_short_completion start restart stop reload status
fi
