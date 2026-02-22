# 80-repo-update.sh

Update-Funktion für dieses Alias-Repository.

## Enthalten
- `alias_repo_update`: Wechselt in den Repo-Ordner, führt `git pull --ff-only` aus und lädt danach neu.
- `alias_repo_reload`: Lädt `bash_alias_std.sh` in der aktüllen Session neu.
- `_alias_update`: Kurzer Alias auf `alias_repo_update`.

## Zweck
Der Update-Befehl funktioniert von jedem aktüllen Verzeichnis aus und nutzt immer den Ordner, in dem `bash_alias_std.sh` liegt.

## Optionen
- `_alias_update` oder `_alias_update --reload`: Update + Reload in aktüller Shell.
- `_alias_update --restart`: Update + Neustart als Login-Shell (`exec $SHELL -l`).

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| _alias_update | Repo-Update + Reload | Aktualisiert dieses Alias-Repository per git pull und lädt neu. | git pull --ff-only && alias_repo_reload |
