# 81-setup.sh

Setup-Startpunkt fuer Bash-Startdatei und Kategorie-Umschaltung.

## Enthalten
- `_self_setup`: Interaktives Menue fuer Setup und Kategorie-Umschaltung.
- `_self_category_setup`: Alias, der das externe Script `scripts/alias_category_setup.sh` startet.

## Verhalten
- `_self_setup`:
- Menue mit Auswahl fuer Bash-Setup oder Kategorie-Umschaltung.
- Beim Bash-Setup: erkennt optionale Alias-Datei aus `~/.bashrc` und bietet diese als Ziel an.
- Beim Bash-Setup: fragt bei root nach Zielauswahl `~/.bashrc` oder `/etc/bash.bashrc`.
- Beim Bash-Setup: schreibt einen markierten Source-Block nur einmal (idempotent).
- `_self_category_setup`:
- Nutzt `alias_files.local.conf` als Ziel.
- Falls nicht vorhanden, wird sie aus `alias_files.conf` erzeugt.
- Zeigt nummerierte Kategorien mit Status `[on/off/partial]`.
- Mit der Nummer wird die Kategorie ein-/ausgeschaltet.

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| _self_setup | Setup-Menue starten | Startet ein Menue fuer Bash-Setup oder Kategorie-Umschaltung. | alias_self_setup |
| _self_category_setup | Kategorie-Setup starten | Startet den interaktiven Kategorie-Setup-Assistenten. | bash "$BASH_ALIAS_REPO_DIR/scripts/alias_category_setup.sh" |
