# shellcheck shell=bash

if [ "${EUID}" -eq 0 ]; then
  syslog() {
    local s_lines="${1:-50}"
    tail -n "${s_lines}" /var/log/syslog
  }

  journal_log() {
    sudo journalctl -n "${1:-50}" --no-pager
  }

  journal_logs() {
    if [ -z "$1" ]; then
      echo "Fehler: Bitte einen Dienst angeben (z.B. nginx, sshd)."
      return 1
    fi
    sudo journalctl -u "$1" -n "${2:-50}" --no-pager
  }

  journal_log_minutes() {
    local minutes="${1:-10}"
    if ! [[ "${minutes}" =~ ^[0-9]+$ ]]; then
      echo "Fehler: Bitte eine positive Zahl für Minuten angeben."
      return 1
    fi
    sudo journalctl --since "$(date --date="${minutes} minutes ago" '+%Y-%m-%d %H:%M:%S')" --no-pager
  }

  journal_log_hours() {
    local hours="${1:-1}"
    if ! [[ "${hours}" =~ ^[0-9]+$ ]]; then
      echo "Fehler: Bitte eine positive Zahl für Stunden angeben."
      return 1
    fi
    sudo journalctl --since "$(date --date="${hours} hours ago" '+%Y-%m-%d %H:%M:%S')" --no-pager
  }

  journal_clean() {
    local days="${1:-2}"
    local size="${2:-100M}"
    echo "Journal wird bereinigt: Aufbewahrung ${days} Tage, max. ${size} Speicherplatz"
    sudo journalctl --vacuum-time="${days}d" --vacuum-size="${size}"
  }

  alias log='journal_log'
  alias logs='journal_logs'
  alias log_min='journal_log_minutes'
  alias log_hour='journal_log_hours'
  alias log_clean='journal_clean'
fi
