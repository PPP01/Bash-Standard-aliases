# 99-help.sh

Hilfsfunktionen für Alias-Listen.

## Enthalten
- `show_aliases_functions`: Zeigt alle aktüll geladenen Aliase an.
- `a`: Zeigt Aliase nach Kategorie.
  - Ohne Parameter: interaktive Kategorie-Auswahl (inkl. `all`).
  - Mit Parameter: z. B. `a git`.
  - Navigation im interaktiven Menue:
    - `0`, `left`, `backspace`: eine Ebene zurück
    - `escape`, `q`: Menue beenden
- Completion für `a`: Kategorie-Namen werden per Tab angeboten.

## Lokalisierbare Texte
- Alias-Texte für Tabelle/Details werden pro Kategorie aus `docs/alias_files/[0-9][0-9]-*.md` geladen.
- Zusätzlich werden eigene Hilfetexte aus folgenden Dateien geladen, falls vorhanden:
  - `$BASH_ALIAS_REPO_DIR/.bash_aliases_specific.md`
  - `~/.bash_aliases_specific.md`
- Je Datei sind Sprachvarianten möglich:
  - Unterordner: `docs/alias_files/<lang>/35-git.md`
  - Suffix: `docs/alias_files/35-git.<lang>.md`
- Ohne Sprachvariante wird die Basisdatei genutzt (z. B. `docs/alias_files/35-git.md`).
