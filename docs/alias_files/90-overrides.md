# 90-overrides.sh

Lokale Overrides und Reload-Helfer.

## Enthalten
- `_self_reload`: `~/.bashrc` neu laden
- `_self_edit`: Gefuehrter Assistent zum Erstellen eines eigenen Alias inkl. Beschreibung
- Optionales Laden von:
  - `$BASH_ALIAS_REPO_DIR/.bash_aliases_specific`
  - `~/.bash_aliases_specific`
- Optionale Hilfetexte fuer eigene Aliase aus:
  - `$BASH_ALIAS_REPO_DIR/.bash_aliases_specific.md`
  - `~/.bash_aliases_specific.md`
- Kategorie `_own` auf Menuepunkt `98`, sobald mindestens eine der eigenen Dateien vorhanden ist.

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| _self_reload | Alias-Module neu laden | Laedt die Alias-Module in der aktuellen Shell neu (Repo-Reload). | alias_repo_reload |
| _self_edit | Alias-Assistent | Startet einen Assistenten und legt ein Alias mit Beschreibung an; danach Reload. Root kann zwischen `~/.bash_aliases_specific` und `$BASH_ALIAS_REPO_DIR/.bash_aliases_specific` waehlen. | alias_self_edit |
