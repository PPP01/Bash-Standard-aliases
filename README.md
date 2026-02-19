# bash_alias

Modulare Bash-Aliase fuer mehrere Linux-Server.

## Struktur
- `bash_alias_std.sh`: Einstiegspunkt, laedt alle Module.
- `aliases.d/00-core.sh`: Basis-Aliase.
- `aliases.d/10-navigation.sh`: Navigation/Sicherheit.
- `aliases.d/20-files.sh`: Datei- und Speicher-Helfer.
- `aliases.d/30-process.sh`: Prozess-Helfer.
- `aliases.d/40-network.sh`: Netzwerk-Helfer.
- `aliases.d/50-root-journal.sh`: Journald-Funktionen (root).
- `aliases.d/60-root-apt.sh`: APT-Shortcuts (root).
- `aliases.d/70-root-systemd.sh`: Systemd-Shortcuts (root).
- `aliases.d/90-overrides.sh`: Lokale Server-Overrides.
- `aliases.d/99-help.sh`: Anzeige-Hilfe.

## Einbindung
In `~/.bashrc`:

```bash
if [ -f /opt/scripts/bash_alias_std.sh ]; then
  source /opt/scripts/bash_alias_std.sh
fi
```

## GitHub Setup
1. Repository auf GitHub erstellen (z. B. `bash_alias`).
2. Lokal im Projektverzeichnis:

```bash
git init -b main
git add .
git commit -m "Initial modular alias setup"
git remote add origin git@github.com:<USER>/bash_alias.git
git push -u origin main
```

## Deployment auf Server
```bash
cd /opt/scripts
git clone git@github.com:<USER>/bash_alias.git
# oder spaeter
cd /opt/scripts/bash_alias
git pull
```

Dann in `~/.bashrc` die Datei `bash_alias_std.sh` sourcen.
