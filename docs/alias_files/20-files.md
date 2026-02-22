# 20-files.sh

Datei- und Speicher-Helfer.

## Enthalten
- `h`: Shell-History anzeigen
- `dfh`: Dateisystem-Auslastung in human-readable Form
- `duh`: Grössen je Verzeichnis-Ebene
- `freeh`: RAM/SWAP Übersicht

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| h | history | Zeigt die Shell-History. | history |
| dfh | df -h | Zeigt Dateisystem-Auslastung in menschenlesbarer Form. | df -h |
| duh | du -h --max-depth=1 | Zeigt Speicherverbrauch pro Unterordner bis Tiefe 1. | du -h --max-depth=1 |
| freeh | free -h | Zeigt RAM- und Swap-Auslastung in menschenlesbarer Form. | free -h |
