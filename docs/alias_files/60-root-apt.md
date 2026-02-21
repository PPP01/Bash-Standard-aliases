# 60-root-apt.sh

APT-Shortcuts und Update-Workflow fuer root.

## Enthalten
- `agi`: `apt install`
- `agr`: `apt remove`
- `acs`: `apt search`
- `agu`: `apt update`
- `agg`: `apt upgrade`
- `aga`: `apt autoremove`
- `agl`: `apt list --upgradable`
- `aua`: `update-all` Wrapper

## Funktion
- `update-all [-y]`: Fuehrt `apt update`, zeigt verfuegbare Updates, dann Upgrade + Autoremove aus.

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| agi | apt install | Installiert ein Paket via apt install (root). | apt install <paket> |
| agr | apt remove | Entfernt ein Paket via apt remove (root). | apt remove <paket> |
| acs | apt search | Sucht Pakete via apt search. | apt search <pattern> |
| agu | apt update | Aktualisiert Paketlisten via apt update (root). | apt update |
| agg | apt upgrade | Fuehrt Paket-Upgrade via apt upgrade aus (root). | apt upgrade |
| aga | apt autoremove | Entfernt unnoetige Pakete via apt autoremove (root). | apt autoremove |
| agl | apt list --upgradable | Zeigt alle upgradefaehigen Pakete. | apt list --upgradable |
| aua | apt Gesamt-Update | Fuehrt apt update, upgrade und autoremove als Gesamt-Update aus (root). | apt update && apt upgrade [-y] && apt autoremove [-y] |
