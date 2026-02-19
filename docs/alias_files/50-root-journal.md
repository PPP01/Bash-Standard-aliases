# 50-root-journal.sh

Journald- und Log-Funktionen fuer root.

## Enthalten
- `syslog [n]`: Letzte `n` Zeilen aus `/var/log/syslog`
- `log [n]`: Letzte `n` Journal-Zeilen
- `logs <service> [n]`: Journal fuer einen Dienst
- `log_min [n]`: Journal der letzten `n` Minuten
- `log_hour [n]`: Journal der letzten `n` Stunden
- `log_clean [tage] [size]`: Journal-Aufraeumen per Zeit/Size
