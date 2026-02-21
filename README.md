# Bash Standard Aliases

Modulare Bash-Aliase fuer mehrere Linux-Server.

## Installation
```bash
git clone https://github.com/PPP01/Bash-Standard-aliases bash-standard-aliases
```

## Zielstruktur
- `bash_alias_std.sh`: Loader-Datei.
- `alias_files/`: Alle verfuegbaren Alias-Module.
- `alias_files.conf`: Standard-Steuerdatei (versioniert).
- `alias_files.local.conf`: Lokale Steuerdatei pro Server (nicht versioniert).
- `alias_files.local.conf.example`: Vorlage fuer lokale Konfiguration.
- `alias_categories.sh`: Kategorie-Zuordnung Modul <-> Kategorie.
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

## Alias-Setup in Bash-Startdatei

```bash
_self_setup
```

`_self_setup` arbeitet markerbasiert:
1. Sucht zuerst nach dem Setup-Marker.
2. Bei root zuerst in `/etc/bash.bashrc`, danach analog User in erkannter Alias-Datei oder `~/.bashrc`.
3. Wenn Marker gefunden: startet direkt die Kategorie-Umschaltung.
4. Wenn kein Marker gefunden: startet den Setup-Assistenten und danach die Kategorie-Umschaltung.

Marker entfernen:

```bash
_self_setup_remove
```

Alternativ:

```bash
_self_setup --remove
```

## Kategorien interaktiv umschalten

```bash
_self_category_setup
```

`_self_category_setup` startet das Kategorie-Script mit nummerierter Liste, z. B. `git`, `journald`, `mysql`, `systemd`.
Mit der Nummer wird die jeweilige Kategorie ein-/ausgeschaltet.

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
_self_update
```

Er fuehrt `git pull --ff-only` immer im Ordner dieses Repositories aus, egal in welchem Verzeichnis du gerade bist, und laedt danach die Aliase neu.

Optional:

```bash
_self_update --restart
```

Fuehrt nach dem Update einen Shell-Neustart (`exec $SHELL -l`) fuer einen komplett sauberen Zustand aus.

Hinweis: Fuer Pageant-Setups kann Git mit `core.sshCommand` auf `plink -agent` konfiguriert sein.

## Alias-Liste nach Kategorie

```bash
a
```

Ohne Parameter bietet `a` eine Kategorie-Auswahl an.
Mit Parameter filtert `a` direkt, z. B. `a git` oder `a all`.
Fuer Kategorien ist Tab-Completion aktiv.
