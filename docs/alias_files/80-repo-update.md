# 80-repo-update.sh

Update-Funktion fuer dieses Alias-Repository.

## Enthalten
- `alias_repo_update`: Wechselt in den Repo-Ordner und fuehrt `git pull --ff-only` aus.
- `alias_update`: Kurzer Alias auf `alias_repo_update`.

## Zweck
Der Update-Befehl funktioniert von jedem aktuellen Verzeichnis aus und nutzt immer den Ordner, in dem `bash_alias_std.sh` liegt.
