# 50-root-journal.sh

Journald- und Log-Funktionen für root.

## Enthalten
- `syslog [n]`: Letzte `n` Zeilen aus `/var/log/syslog`
- `log [n]`: Letzte `n` Journal-Zeilen
- `logs <service> [n]`: Journal für einen Dienst
- `log_min [n]`: Journal der letzten `n` Minuten
- `log_hour [n]`: Journal der letzten `n` Stunden
- `log_clean [tage] [size]`: Journal-Aufräumen per Zeit/Size

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| log | Journal letzte X Zeilen | Zeigt die letzten Journal-Logs (Standard 50 Zeilen, root-Funktion). | journalctl -n <X> --no-pager (Standard: X=50) |
| logs | Journal pro Service | Zeigt Journal-Logs für einen Dienst mit optionaler Zeilenanzahl (root-Funktion). | journalctl -u <service> -n <X> --no-pager (Standard: X=50) |
| log_min | Journal seit X Minuten | Zeigt Journal-Logs der letzten X Minuten (Standard 10, root-Funktion). | journalctl --since "<X> minutes ago" --no-pager (Standard: X=10) |
| log_hour | Journal seit X Stunden | Zeigt Journal-Logs der letzten X Stunden (Standard 1, root-Funktion). | journalctl --since "<X> hours ago" --no-pager (Standard: X=1) |
| log_clean | Journal bereinigen | Bereinigt Journal-Logs nach Aufbewahrungszeit/Grösse (root-Funktion). | journalctl --vacuum-time=<tage>d --vacuum-size=<grösse> (Standard: 2d, 100M) |
