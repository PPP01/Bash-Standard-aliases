# 90-overrides.sh

Lokale Overrides und Reload-Helfer.

## Enthalten
- `_self_reload`: `~/.bashrc` neu laden
- `_self_edit`: `~/.bash_aliases` bearbeiten und neu laden
- Optionales Laden von:
  - `/opt/scripts/bash_aliases_specific`
  - `~/.bash_aliases_specific`

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| _self_reload | Alias-Module neu laden | Laedt die Alias-Module in der aktuellen Shell neu (Repo-Reload). | alias_repo_reload |
| _self_edit | Alias-Datei bearbeiten | Oeffnet ~/.bash_aliases zum Bearbeiten und laedt neu. | nano ~/.bash_aliases && source ~/.bashrc |
