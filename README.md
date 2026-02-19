# Bash Standard Aliases

Modulare Bash-Aliase fuer mehrere Linux-Server.

## Zielstruktur
- `bash_alias_std.sh`: Loader-Datei.
- `alias_files/`: Alle verfuegbaren Alias-Module.
- `alias_files.conf`: Steuerdatei, welche Module aktiv sind.
- `docs/alias_files/*.md`: Dokumentation je Modul.

## Module aktivieren/deaktivieren
Datei: `alias_files.conf`

Format pro Zeile:

```text
enabled|00-core.sh|Basis-Aliase fuer alle Benutzer
```

Moeglichkeiten:
- Aktiv: `enabled|...`
- Deaktiviert: `disabled|...`
- Oder auskommentiert: `# enabled|...`

## Einbindung in ~/.bashrc

```bash
if [ -f /opt/scripts/bash_alias_std.sh ]; then
  source /opt/scripts/bash_alias_std.sh
fi
```

## GitHub Sync

```bash
git add .
git commit -m "Rework alias architecture with config and docs"
git push
```
