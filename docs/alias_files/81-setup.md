# 81-setup.sh

Setup-Startpunkt fuer Kategorie-Umschaltung.

## Enthalten
- `_self_setup`: Alias, der das externe Script `scripts/alias_category_setup.sh` startet.

## Verhalten
- Nutzt `alias_files.local.conf` als Ziel.
- Falls nicht vorhanden, wird sie aus `alias_files.conf` erzeugt.
- Zeigt nummerierte Kategorien mit Status `[on/off/partial]`.
- Mit der Nummer wird die Kategorie ein-/ausgeschaltet.