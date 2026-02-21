# 80-repo-update.sh

Update-Funktion fuer dieses Alias-Repository.

## Enthalten
- `alias_repo_update`: Wechselt in den Repo-Ordner, fuehrt `git pull --ff-only` aus und laedt danach neu.
- `alias_repo_reload`: Laedt `bash_alias_std.sh` in der aktuellen Session neu.
- `_self_update`: Kurzer Alias auf `alias_repo_update`.

## Zweck
Der Update-Befehl funktioniert von jedem aktuellen Verzeichnis aus und nutzt immer den Ordner, in dem `bash_alias_std.sh` liegt.

## Optionen
- `_self_update` oder `_self_update --reload`: Update + Reload in aktueller Shell.
- `_self_update --restart`: Update + Neustart als Login-Shell (`exec $SHELL -l`).
