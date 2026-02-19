# Bash Standard Aliases

Modulare Bash-Aliase fuer mehrere Linux-Server.

## Zielstruktur
- `bash_alias_std.sh`: Loader-Datei.
- `alias_files/`: Alle verfuegbaren Alias-Module.
- `alias_files.conf`: Standard-Steuerdatei (versioniert).
- `alias_files.local.conf`: Lokale Steuerdatei pro Server (nicht versioniert).
- `alias_files.local.conf.example`: Vorlage fuer lokale Konfiguration.
- `docs/alias_files/*.md`: Dokumentation je Modul.

## Module aktivieren/deaktivieren
Dateien:
- `alias_files.local.conf` (hat Prioritaet, wenn vorhanden)
- sonst `alias_files.conf`

Format pro Modul:

```text
# 3-5 Zeilen Beschreibung
# ...
00-core.sh
```

Moeglichkeiten:
- Aktiv: Datei-Zeile ohne `#`
- Deaktiviert: Datei-Zeile auskommentiert, z. B. `# 00-core.sh`

## Lokale Konfiguration ohne Git-Aenderung

```bash
cp alias_files.local.conf.example alias_files.local.conf
```

Danach in `alias_files.local.conf` Module pro Server ein-/auskommentieren.
Die Datei `alias_files.local.conf` ist in `.gitignore` und erzeugt keine Git-Diffs.

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

Hinweis: Fuer Pageant-Setups kann Git mit `core.sshCommand` auf `plink -agent` konfiguriert sein.
