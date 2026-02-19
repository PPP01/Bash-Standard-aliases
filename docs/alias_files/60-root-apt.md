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
