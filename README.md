# Bash Standard Aliases

Modulare Bash-Aliase fuer mehrere Linux-Server.

## Zielstruktur
- `bash_alias_std.sh`: Loader-Datei.
- `alias_files/`: Alle verfuegbaren Alias-Module.
- `alias_files.conf`: Steuerdatei mit Beschreibung pro Modul.
- `docs/alias_files/*.md`: Dokumentation je Modul.

## Module aktivieren/deaktivieren
Datei: `alias_files.conf`

Format pro Modul:

```text
# 3-5 Zeilen Beschreibung
# ...
00-core.sh
```

Moeglichkeiten:
- Aktiv: Datei-Zeile ohne `#`
- Deaktiviert: Datei-Zeile auskommentiert, z. B. `# 00-core.sh`

## Einbindung in ~/.bashrc

```bash
if [ -f /opt/scripts/bash_alias_std.sh ]; then
  source /opt/scripts/bash_alias_std.sh
fi
```

## Repo Update

Nach dem Laden der Aliase steht dieser Befehl zur Verfuegung:

```bash
alias_update
```

Er fuehrt `git pull --ff-only` immer im Ordner dieses Repositories aus, egal in welchem Verzeichnis du gerade bist.
