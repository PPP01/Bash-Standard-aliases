# Bash Standard Aliases

## 1. Kurzbeschreibung
`bash-standard-aliases` ist ein modulares Alias-Set fuer Linux-Server.
Ziel: wiederkehrende Admin- und Dev-Aufgaben schneller, einheitlicher und nachvollziehbar machen.

Typische Beispiele:
- Navigation und Dateisicht: `ll`, `la`, `..`, `dfh`, `duh`
- Prozesse und Netzwerk: `psmem`, `pscpu`, `ports`, `myip`
- Git-Workflow: `gs`, `ga`, `gcm`, `gpl`
- Systemdienste/Logs (root): `start nginx`, `status ssh`, `logs nginx`
- Selbstverwaltung: `_self_setup`, `_self_category_setup`, `_self_update`, `_self_edit`

## 2. Installation
```bash
git clone https://github.com/PPP01/Bash-Standard-aliases bash-standard-aliases
```

## 3. Initiale Konfiguration per `_self_setup`
Nach dem ersten Laden des Repos startet `_self_setup` den Setup-Assistenten.
Er setzt einen Marker-Block in die passende Bash-Startdatei und startet danach die Kategorie-Auswahl.

```bash
_self_setup
```

### 3.1 Integration
Was passiert:
- Marker-basierter `source`-Block wird eingetragen (idempotent).
- User: Ziel ist erkannte Alias-Datei aus `~/.bashrc` oder `~/.bashrc`.
- Root: Auswahl zwischen User-Ziel und `/etc/bash.bashrc`.

### 3.2 Kategorien ein/ausschalten
Nach der Integration (oder bei vorhandenem Marker) startet direkt das Kategorien-Menue.
Du kannst es jederzeit separat starten:

```bash
_self_category_setup
```

Speicherort der Aenderungen:
- Normaler User: `~/.config/bash-standard-aliases/config.conf`
- Root: Auswahl zwischen `global` (`${BASH_ALIAS_REPO_DIR}/alias_files.local.conf`) und `root-eigen` (`~/.config/bash-standard-aliases/config.conf`)

Hinweis: Es werden Delta-Aenderungen gespeichert (nur Abweichungen), nicht die komplette Basisdatei.

### 3.3 Remove
Setup-Marker wieder entfernen:

```bash
_self_setup_remove
```

Alternativ:

```bash
_self_setup --remove
```

## 4. Bedienung

### 4.1 Menue `a`
```bash
a
```

Oeffnet ein interaktives Menue mit sichtbaren Kategorien und Alias-Details.
Kategorien ohne verfuegbare Aliase fuer den aktuellen User werden ausgeblendet.
In der Detailansicht startet `Enter` den ausgewaehlten Alias direkt.

### 4.1.1 Menue `a [kategorie]`
```bash
a git
a network
a all
```

- `a <kategorie>` zeigt Aliase einer Kategorie.
- `a all` zeigt alle sichtbaren Kategorien.

### 4.1.2 Menue `a [alias]`
```bash
a gs
a _self_setup
```

Wenn der Parameter ein Alias-Name ist, zeigt `a` direkt die Detailansicht (Beschreibung + Befehl).

### 4.1.3 Farben der Detailansicht
Die Labels `Beschreibung` und `Befehl` sind standardmaessig gruen.
Sie koennen ueber Settings-Layer ueberschrieben werden:

```bash
# globales Delta (root/host)
settings.local.conf

# user Delta
~/.config/bash-standard-aliases/settings.conf
```

### 4.2 Alias Bedienung
Aliase sind normale Shell-Aliase/Funktionen und werden direkt ausgefuehrt, z. B.:

```bash
ll
gs
ports
```

Root-only Module (z. B. `journald`, `apt`, `systemd`) sind nur sichtbar/nutzbar, wenn die jeweiligen Aliase fuer die aktuelle Shell verfuegbar sind.

### 4.3 Eigene Aliase hinzufuegen

### 4.3.1 Per Menue
```bash
_self_edit
```

Der Assistent fragt Alias-Name, Beschreibung und Befehl ab und laedt danach automatisch neu.

### 4.3.2 Speicherort (+ MD)
Standard-Speicherorte:
- User: `~/.bash_aliases_specific`
- Root: Auswahl zwischen `~/.bash_aliases_specific` (root-eigen) und `${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific` (projektweit)

Zugehoerige Hilfe-Datei liegt jeweils daneben:
- `~/.bash_aliases_specific.md`
- `${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific.md`

## 5. Update per `_self_update`
```bash
_self_update
```

Fuehrt `git pull --ff-only` im Repo aus und macht danach einen Reload.

Optional:

```bash
_self_update --restart
```

Startet nach dem Update eine frische Login-Shell.

## 6. Manuelle Konfiguration
### 6.1 Modul-Konfiguration
Konfigurations-Layer fuer Module (in dieser Reihenfolge):
1. `alias_files.conf` (Basis, versioniert)
2. `alias_files.local.conf` (globale Delta-Aenderungen)
3. `~/.config/bash-standard-aliases/config.conf` (user Delta-Aenderungen)

Regeln pro Modulzeile:
- Aktiv: `20-files.sh`
- Deaktiviert: `# 20-files.sh`

Beispiel (nur Delta):
```text
# aktivieren
85-mysql.sh

# deaktivieren
# 35-git.sh
```

### 6.2 Settings-Konfiguration
Konfigurations-Layer fuer Settings (in dieser Reihenfolge):
1. `settings.conf` (Basis, versioniert)
2. `settings.local.conf` (globale Delta-Settings)
3. `~/.config/bash-standard-aliases/settings.conf` (user Delta-Settings)

Beispiel (nur Delta):
```bash
# ~/.config/bash-standard-aliases/settings.conf
BASH_ALIAS_HELP_COLOR_DETAIL_LABEL='\033[1;32m'
```

## 7. Manuelle Einbindung
Wenn du `_self_setup` nicht nutzen willst, kannst du den Loader direkt sourcen:

```bash
if [ -f /pfad/zu/bash-standard-aliases/bash_alias_std.sh ]; then
  source /pfad/zu/bash-standard-aliases/bash_alias_std.sh
fi
```

## 8. Zielstruktur
- `bash_alias_std.sh`: Loader (Layer-Logik + Kategorie-Mapping zur Laufzeit)
- `alias_files/`: Alias-Module
- `alias_files.conf`: Basis-Konfiguration
- `alias_files.local.conf`: globale Delta-Konfiguration
- `settings.conf`: Basis-Settings (z. B. Farben)
- `settings.local.conf`: globale Delta-Settings
- `scripts/alias_self_setup.sh`: Setup/Marker-Logik
- `scripts/alias_category_setup.sh`: Kategorie-Umschaltung
- `alias_categories.sh`: Modul <-> Kategorie Zuordnung
- `docs/alias_files/*.md`: Modul-Doku

## 9. Alle noetigen Schritte: eigene Kategorie mit Aliases anlegen
1. Neues Modul anlegen, z. B. `alias_files/45-monitoring.sh`.
2. Aliase/Funktionen im Modul definieren.
3. Kategorie in `alias_categories.sh` ergaenzen.
4. In `alias_categories_list` den Kategorienamen eintragen.
5. In `alias_category_sort_key` Sortierreihenfolge festlegen.
6. In `alias_category_for_module` das Modul der Kategorie zuordnen.
7. In `alias_modules_for_category` Rueck-Mapping pflegen.
8. Optional Doku anlegen: `docs/alias_files/45-monitoring.md`.
9. Modul aktivieren, entweder global in `alias_files.local.conf` oder user-spezifisch in `~/.config/bash-standard-aliases/config.conf`.
10. Reload ausfuehren:
```bash
_self_reload
```
11. Ergebnis pruefen:
```bash
a monitoring
```
12. Optional Konsistenztest:
```bash
_self_test_reload
```
