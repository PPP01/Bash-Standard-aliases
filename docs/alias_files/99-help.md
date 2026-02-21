# 99-help.sh

Hilfsfunktionen fuer Alias-Listen.

## Enthalten
- `show_aliases_functions`: Zeigt alle aktuell geladenen Aliase an.
- `a`: Zeigt Aliase nach Kategorie.
  - Ohne Parameter: interaktive Kategorie-Auswahl (inkl. `all`).
  - Mit Parameter: z. B. `a git`.
  - Navigation im interaktiven Menue:
    - `0`, `left`, `backspace`: eine Ebene zurueck
    - `escape`, `q`: Menue beenden
- Completion fuer `a`: Kategorie-Namen werden per Tab angeboten.

## Lokalisierbare Texte
- Alias-Texte fuer Tabelle/Details werden pro Kategorie aus `docs/alias_files/[0-9][0-9]-*.md` geladen.
- Je Datei sind Sprachvarianten moeglich:
  - Unterordner: `docs/alias_files/<lang>/35-git.md`
  - Suffix: `docs/alias_files/35-git.<lang>.md`
- Ohne Sprachvariante wird die Basisdatei genutzt (z. B. `docs/alias_files/35-git.md`).
