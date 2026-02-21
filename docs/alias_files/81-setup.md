# 81-setup.sh

Setup-Startpunkt mit markerbasierter Installation und Kategorie-Umschaltung.

## Enthalten
- `_self_setup`: Marker-Pruefung, dann Kategorie-Umschaltung oder Setup.
- `_self_setup_remove`: Entfernt den Setup-Markerblock wieder aus der Zieldatei.
- `_self_category_setup`: Alias, der das externe Script `scripts/alias_category_setup.sh` startet.

## Verhalten
- `_self_setup`:
- Sucht zuerst nach dem Setup-Marker.
- Bei root zuerst in `/etc/bash.bashrc`, danach in erkannter Alias-Datei oder `~/.bashrc`.
- Wenn Marker gefunden: startet direkt Kategorie-Umschaltung.
- Wenn kein Marker gefunden: startet Setup-Assistent und danach Kategorie-Umschaltung.
- Setup schreibt einen markierten Source-Block nur einmal (idempotent).
- `_self_setup_remove`:
- Entfernt den markierten Setup-Block aus der erkannten Zieldatei.
- Unterstuetzt auch `_self_setup --remove`.
- `_self_category_setup`:
- Nutzt `alias_files.local.conf` als Ziel.
- Falls nicht vorhanden, wird sie aus `alias_files.conf` erzeugt.
- Zeigt nummerierte Kategorien mit Status `[on/off/partial]`.
- Mit der Nummer wird die Kategorie ein-/ausgeschaltet.

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| _self_setup | Marker-Setup starten | Prueft Marker und startet Kategorie-Umschaltung oder Setup. | alias_self_setup |
| _self_setup_remove | Setup-Marker entfernen | Entfernt den markierten Setup-Block aus der erkannten Startdatei. | alias_setup_remove |
| _self_category_setup | Kategorie-Setup starten | Startet den interaktiven Kategorie-Setup-Assistenten. | bash "$BASH_ALIAS_REPO_DIR/scripts/alias_category_setup.sh" |
