# 35-git.sh

Gängige Git-Aliase für den Alltag.

## Enthalten
- `g`: `git`
- `gs`: `git status -sb`
- `ga` / `gaa`: `git add` / `git add --all`
- `gb` / `gba` / `gbd`: Branch anzeigen / alle Branches / Branch löschen
- `gco` / `gcb`: Checkout / neün Branch anlegen und wechseln
- `gc` / `gcm` / `gca` / `gcan`: Commit-Shortcuts
- `gd` / `gds`: Unstaged bzw. staged Diff
- `gl`: Kompakter Graph-Log ueber alle Branches
- `gf`: `git fetch --all --prune`
- `gpl`: `git pull --ff-only`
- `gp` / `gpf`: Push / Force-Push mit `--force-with-lease`
- `gr` / `grs`: `git restore` / `git restore --staged`
- `grsoft1` / `grhard1`: Letzten Commit soft/hard zurücksetzen (`HEAD~1`)
- `gst` / `gstp`: `git stash` / `git stash pop`

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| g | git | Kurzform für git. | git |
| gs | git status -sb | Zeigt den Git-Status kurz inkl. Branch-Info. | git status -sb |
| ga | git add | Fügt Dateien zur Git-Staging-Area hinzu. | git add |
| gaa | git add --all | Fügt alle Aenderungen zur Git-Staging-Area hinzu. | git add --all |
| gb | git branch | Zeigt lokale Git-Branches. | git branch |
| gba | git branch -a | Zeigt lokale und Remote-Branches. | git branch -a |
| gbd | git branch -d | Löscht einen lokalen Branch. | git branch -d <branch> |
| gco | git checkout | Wechselt auf einen Branch oder Commit. | git checkout <ref> |
| gcb | git checkout -b | Erstellt einen neün Branch und wechselt darauf. | git checkout -b <branch> |
| gc | git commit | Erstellt einen neün Commit (Editor). | git commit |
| gcm | git commit -m | Erstellt einen Commit mit direkter Nachricht. | git commit -m "<msg>" |
| gca | git commit --amend | Aendert den letzten Commit (amend). | git commit --amend |
| gcan | git commit --amend --no-edit | Aendert den letzten Commit ohne neue Nachricht. | git commit --amend --no-edit |
| gd | git diff | Zeigt nicht gestagte Aenderungen. | git diff |
| gds | git diff --staged | Zeigt gestagte Aenderungen. | git diff --staged |
| gl | git log --oneline --decorate --graph --all | Zeigt kompakten Git-Graph-Log. | git log --oneline --decorate --graph --all |
| gf | git fetch --all --prune | Holt alle Remotes und bereinigt veraltete Referenzen. | git fetch --all --prune |
| gpl | git pull --ff-only | Führt git pull nur als Fast-Forward aus. | git pull --ff-only |
| gp | git push | Führt git push auf das konfigurierte Ziel aus. | git push |
| gpf | git push --force-with-lease | Führt git push mit --force-with-lease aus (sicherer Force-Push). | git push --force-with-lease |
| gr | git restore | Setzt Aenderungen im Working Tree auf HEAD zurück. | git restore <file> |
| grs | git restore --staged | Entfernt Dateien aus der Staging-Area. | git restore --staged <file> |
| grsoft1 | git reset --soft HEAD~1 | Setzt den letzten Commit zurück und behält alle Aenderungen im Staging-Bereich. | git reset --soft HEAD~1 |
| grhard1 | git reset --hard HEAD~1 | Verwirft den letzten Commit inklusive Working-Tree-Aenderungen unwiderruflich. | git reset --hard HEAD~1 |
| gst | git stash | Speichert den aktüllen Arbeitsstand in einem Stash. | git stash |
| gstp | git stash pop | Spielt den letzten Git-Stash wieder ein. | git stash pop |
