# 99-help.sh

Hilfsfunktionen für Alias-Listen.

## Enthalten
- `show_aliases_functions`: Zeigt alle aktüll geladenen Aliase an.
- `a`: Zeigt Aliase nach Kategorie.
  - Ohne Parameter: interaktive Kategorie-Auswahl (inkl. `all`).
  - Mit Parameter: z. B. `a git`.
  - Navigation im interaktiven Menü:
    - `0`, `left`, `backspace`: eine Ebene zurück
    - `escape`, `q`: Menü beenden
  - In der Alias-Detailansicht:
    - `Enter`: ausgewählten Alias direkt ausführen
    - `0`, `left`, `backspace`: zur Alias-Liste zurück
    - `escape`, `q`: Menü beenden
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

## Farben (überschreibbar)
- Definiert in `settings.conf` (Bereich `Color`).
- Delta-Overrides:
  - `settings.local.conf` (global pro Host/Repo)
  - `~/.config/bash-standard-aliases/settings.conf` (pro User)
- Relevante Variablen:
  - `BASH_ALIAS_HELP_COLOR_DETAIL_LABEL` (Default: grün, `\033[0;32m`)
  - `BASH_ALIAS_HELP_COLOR_RESET` (Default: `\033[0m`)
