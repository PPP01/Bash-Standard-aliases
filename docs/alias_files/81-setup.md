# 81-setup.sh

Setup-Startpunkt mit markerbasierter Installation und Kategorie-Umschaltung.

## Enthalten
- `_alias_init`: Marker-Prüfung und Setup-Initialisierung.
- `_alias_init_remove`: Entfernt den Setup-Markerblock wieder aus der Zieldatei.
- `_alias_category_setup`: Alias, der das externe Script `scripts/alias_category_setup.sh` startet.
- `_alias_setup`: Guided Setup (zuerst Farbschema, danach Kategorien).

## Verhalten
- `_alias_init`:
- Sucht zuerst nach dem Setup-Marker.
- Bei root zuerst in `/etc/bash.bashrc`, danach in erkannter Alias-Datei oder `~/.bashrc`.
- Wenn Marker gefunden: startet direkt Kategorie-Umschaltung.
- Wenn kein Marker gefunden: startet Setup-Assistent und danach Kategorie-Umschaltung.
- Setup schreibt einen markierten Source-Block nur einmal (idempotent).
- `_alias_init_remove`:
- Entfernt den markierten Setup-Block aus der erkannten Zieldatei.
- `_alias_setup`:
- Startet nacheinander:
  - `scripts/alias_color_scheme_setup.sh`
  - `scripts/alias_category_setup.sh`
- `_alias_category_setup`:
- Startet nur den Kategorie-Setup-Assistenten.
- Nutzt ein Delta-Konfigurationsmodell:
- Basis ist immer `alias_files.conf`.
- Globale Abweichungen: `${BASH_ALIAS_REPO_DIR}/alias_files.local.conf`.
- User-Abweichungen: `~/.config/bash-standard-aliases/config.conf`.
- Settings (z. B. Farben) werden separat per Layer geladen:
- Basis: `settings.conf`
- Globales Delta: `${BASH_ALIAS_REPO_DIR}/settings.local.conf`
- User-Delta: `~/.config/bash-standard-aliases/settings.conf`
- Als root Auswahl zwischen globalen oder eigenen Änderungen.
- Als User immer eigene Änderungen im Home-Pfad.
- Zeigt nummerierte Kategorien mit Status `[on/off/partial]`.
- Mit der Nummer wird die Kategorie ein-/ausgeschaltet.

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| _alias_init | Marker-Setup starten | Prüft Marker und startet Kategorie-Umschaltung oder Setup. | _alias_init |
| _alias_init_remove | Setup-Marker entfernen | Entfernt den markierten Setup-Block aus der erkannten Startdatei. | _alias_init_remove |
| _alias_category_setup | Kategorie-Setup starten | Startet den interaktiven Kategorie-Setup-Assistenten. | bash "$BASH_ALIAS_REPO_DIR/scripts/alias_category_setup.sh" |
| _alias_setup | Guided Setup starten | Startet nacheinander Farbschema-Setup und Kategorie-Setup. | bash "$BASH_ALIAS_REPO_DIR/scripts/alias_guided_setup.sh" |
