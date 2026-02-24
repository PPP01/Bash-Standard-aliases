# Bash Standard Aliases

## 1. Kurzbeschreibung
`bash-standard-aliases` ist ein modulares Alias-Set für Linux-Server.
Ziel: wiederkehrende Admin- und Dev-Aufgaben schneller, einheitlicher und nachvollziehbar machen.

Typische Beispiele:
- Navigation und Dateisicht: `ll`, `la`, `..`, `dfh`, `duh`
- Prozesse und Netzwerk: `psmem`, `pscpu`, `ports`, `myip`
- Git-Workflow: `gs`, `ga`, `gcm`, `gpl`
- Systemdienste/Logs (root): `start nginx`, `status ssh`, `logs nginx`
- Selbstverwaltung: `_alias_init`, `_alias_setup_language`, `_alias_category_setup`, `_alias_update`, `_alias_edit`

## 2. Installation
```bash
git clone https://github.com/PPP01/Bash-Standard-aliases bash-standard-aliases
```

### 2.1 Direkt laden (source)
Wenn du direkt laden willst:

```bash
source bash-standard-aliases/bash_alias_std.sh
```

### 2.2 Erstinitialisierung (`_alias_init`)
Nach dem Klonen kannst du die Initialisierung direkt starten:

```bash
_alias_init
```

Der Befehl richtet die Einbindung in der Shell-Startdatei ein (Marker-Block) und führt danach ins Setup.

### 2.2.1 Integration
Was passiert:
- Marker-basierter `source`-Block wird eingetragen (idempotent).
- User: Ziel ist erkannte Alias-Datei aus `~/.bashrc` oder `~/.bashrc`.
- Root: Auswahl zwischen User-Ziel und `/etc/bash.bashrc`.

### 2.2.2 Integration entfernen (`_alias_init_remove`)
Setup-Marker wieder entfernen:

```bash
_alias_init_remove
```

## 3. Kategorie-Konfiguration per `_alias_setup`
`_alias_setup` startet ein geführtes Setup mit drei Schritten:
1. Sprache einstellen
2. Farbschema einstellen
3. Kategorien konfigurieren

```bash
_alias_setup
```

### 3.1 Kategorien ein/ausschalten
Für nur die Kategorie-Auswahl (ohne Farbschema) nutze:

```bash
_alias_category_setup
```

Speicherort der Änderungen:
- Normaler User: `~/.config/bash-standard-aliases/config.conf`
- Root: Auswahl zwischen `global` (`${BASH_ALIAS_REPO_DIR}/alias_files.local.conf`) und `root-eigen` (`~/.config/bash-standard-aliases/config.conf`)

Hinweis: Es werden Delta-Änderungen gespeichert (nur Abweichungen), nicht die komplette Basisdatei.

## 4. Bedienung

### 4.1 Menü `a`
```bash
a
```

Oeffnet ein interaktives Menü mit sichtbaren Kategorien und Alias-Details.
Kategorien ohne verfügbare Aliase für den aktuellen User werden ausgeblendet.
In der Detailansicht startet `Enter` den ausgewählten Alias direkt.

Navigationstasten im interaktiven Menü:
- `Pfeil hoch` / `Pfeil runter`: Auswahl bewegen
- `Pfeil rechts` / `Enter`: ausgewählten Eintrag öffnen (oder in der Detailansicht ausführen)
- `Pfeil links` / `Backspace` / `0`: eine Ebene zurück
- `q` / `Esc`: Menü beenden

### 4.1.1 Menü `a [kategorie]`
```bash
a git
a network
a all
```

- `a <kategorie>` zeigt Aliase einer Kategorie.
- `a all` zeigt alle sichtbaren Kategorien.

### 4.1.2 Menü `a [alias]`
```bash
a gs
a _alias_init
```

Wenn der Parameter ein Alias-Name ist, zeigt `a` direkt die Detailansicht (Beschreibung + Befehl).

### 4.1.3 Performance-Cache für `a`
Der Menü-Cache von `a` wird lazy aufgebaut:
- Beim ersten Aufruf von `a` wird der Cache berechnet.
- Danach wird ein userbezogener Disk-Cache genutzt:
  - `${XDG_CACHE_HOME:-$HOME/.cache}/bash-standard-aliases`
- Bei neuer Repo-Version wird der Cache automatisch neu aufgebaut.
  - Versionserkennung über Git-Revision (`HEAD`, bei lokalen Änderungen mit `-dirty`).
- User-spezifische Dateien fließen ebenfalls in den Cache-Key ein:
  - `~/.bash_aliases_specific`
  - `~/.bash_aliases_specific.md`

Deaktivieren (optional):
```bash
export BASH_ALIAS_MENU_DISK_CACHE=0
```

### 4.1.4 Menü- und Detailfarben
Farben für Menü und Detailansicht sind über `BASH_ALIAS_HELP_COLOR_*` konfigurierbar
(z. B. `..._DETAIL_LABEL`, `..._MENU_TITLE`, `..._MENU_HIGHLIGHT_LINE`).
Sie können über Settings-Layer überschrieben werden:

```bash
# globales Delta (root/host)
settings.local.conf

# user Delta
~/.config/bash-standard-aliases/settings.conf
```

### 4.2 Alias Bedienung
Aliase sind normale Shell-Aliase/Funktionen und werden direkt ausgeführt, z. B.:

```bash
ll
gs
ports
```

Root-only Module (z. B. `journald`, `apt`, `systemd`) sind nur sichtbar/nutzbar, wenn die jeweiligen Aliase für die aktuelle Shell verfügbar sind.

### 4.3 Eigene Aliase hinzufügen

### 4.3.1 Per Menü
```bash
_alias_edit
```

Der Assistent fragt Alias-Name, Beschreibung und Befehl ab und laedt danach automatisch neu.

### 4.3.2 Speicherort (+ MD)
Standard-Speicherorte:
- User: `~/.bash_aliases_specific`
- Root: Auswahl zwischen `~/.bash_aliases_specific` (root-eigen) und `${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific` (projektweit)

Zugehoerige Hilfe-Datei liegt jeweils daneben:
- `~/.bash_aliases_specific.md`
- `${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific.md`

## 5. Update per `_alias_update`
```bash
_alias_update
```

Führt `git pull --ff-only` im Repo aus und macht danach einen Reload.

Optional:

```bash
_alias_update --restart
```

Startet nach dem Update eine frische Login-Shell.

## 6. Manuelle Konfiguration
### 6.1 Modul-Konfiguration
Konfigurations-Layer für Module (in dieser Reihenfolge):
1. `alias_files.conf` (Basis, versioniert)
2. `alias_files.local.conf` (globale Delta-Änderungen)
3. `~/.config/bash-standard-aliases/config.conf` (user Delta-Änderungen)

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
Konfigurations-Layer für Settings (in dieser Reihenfolge):
1. `settings.conf` (Basis, versioniert)
2. `settings.local.conf` (globale Delta-Settings)
3. `~/.config/bash-standard-aliases/settings.conf` (user Delta-Settings)

`_alias_setup_scheme` schreibt zwei Marker-Blöcke in die User-Settings:
- `# >>> _alias_setup_scheme managed >>>`: generierte Schema-Werte
- `# >>> _alias_setup_scheme user-overrides >>>`: aktive manuelle Overrides

Wichtiges Verhalten:
- Aktive `BASH_ALIAS_HELP_COLOR_*`-Zeilen außerhalb des Managed-Blocks werden beim
  nächsten Lauf von `_alias_setup_scheme` in den `user-overrides`-Block normalisiert.
- Dadurch werden manuelle Farb-Overrides nicht von generierten Managed-Werten überschrieben.

Beispiel (nur Delta):
```bash
# ~/.config/bash-standard-aliases/settings.conf
BASH_ALIAS_HELP_COLOR_DETAIL_LABEL='\033[1;32m'
```

## 7. Manuelle Einbindung
Wenn du `_alias_init` nicht nutzen willst, kannst du den Loader direkt sourcen:

```bash
if [ -f /pfad/zu/bash-standard-aliases/bash_alias_std.sh ]; then
  source /pfad/zu/bash-standard-aliases/bash_alias_std.sh
fi
```

### 7.1 Optionales Loader-Profiling
Für die Analyse von Startzeit-Problemen kann der Loader pro Modul Laufzeiten ausgeben:

```bash
BASH_ALIAS_PROFILE=1 source /pfad/zu/bash-standard-aliases/bash_alias_std.sh
```

Optionale Filterung:
```bash
BASH_ALIAS_PROFILE=1 BASH_ALIAS_PROFILE_MIN_MS=20 source /pfad/zu/bash-standard-aliases/bash_alias_std.sh
```

- `BASH_ALIAS_PROFILE=1`: Profiling aktivieren
- `BASH_ALIAS_PROFILE_MIN_MS=<n>`: nur Module mit mindestens `<n>` ms anzeigen
- Ausgabe erfolgt auf `stderr` und enthält zusätzlich eine Gesamtzeit

## 8. Zielstruktur
- `bash_alias_std.sh`: Loader (Layer-Logik + Kategorie-Mapping zur Laufzeit)
- `alias_files/`: Alias-Module
- `alias_files.conf`: Basis-Konfiguration
- `alias_files.local.conf`: globale Delta-Konfiguration
- `settings.conf`: Basis-Settings (z. B. Farben)
- `settings.local.conf`: globale Delta-Settings
- `scripts/`: Setup/Marker- und Kategorie-Setup-Logik
- `scripts/alias_category_setup.sh`: Kategorie-Umschaltung
- `alias_categories.sh`: Modul <-> Kategorie Zuordnung
- `docs/alias_files/*.md`: Modul-Doku

## 9. Alle nötigen Schritte: eigene Kategorie mit Aliases anlegen
1. Neues Modul anlegen, z. B. `alias_files/45-monitoring.sh`.
2. Aliase/Funktionen im Modul definieren.
3. Kategorie in `alias_categories.sh` ergänzen.
4. In `alias_categories_list` den Kategorienamen eintragen.
5. In `alias_category_sort_key` Sortierreihenfolge festlegen.
6. In `alias_category_for_module` das Modul der Kategorie zuordnen.
7. In `alias_modules_for_category` Rück-Mapping pflegen.
8. Optional Doku anlegen: `docs/alias_files/45-monitoring.md`.
9. Modul aktivieren, entweder global in `alias_files.local.conf` oder user-spezifisch in `~/.config/bash-standard-aliases/config.conf`.
10. Reload ausführen:
```bash
_alias_reload
```
11. Ergebnis prüfen:
```bash
a monitoring
```
12. Optional Konsistenztest:
```bash
_alias_test_reload
```
