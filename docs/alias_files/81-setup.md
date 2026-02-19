# 81-setup.sh

Interaktives Setup-Modul fuer die Einbindung von `bash_alias_std.sh`.

## Enthalten
- `alias_setup`: Fragt interaktiv nach den Ziel-Dateien und fuegt den Source-Block ein.
- `_self_setup`: Kurzer Alias auf `alias_setup`.

## Verhalten
- User-Setup:
  - Standardziel ist `~/.bashrc`.
  - Falls in `~/.bashrc` eine Alias-Datei erkannt wird (z. B. `~/.bash_aliases`), kann stattdessen dort eingetragen werden.
- Root-Setup:
  - Wenn als root ausgefuehrt und `/etc/bash.bashrc` vorhanden ist, gibt es eine Entweder-oder-Auswahl:
    - `~/.bashrc` bzw. erkannte Alias-Datei
    - oder `/etc/bash.bashrc`
    - oder ueberspringen

## Sicherheit
- Mehrfache Eintraege werden vermieden (Marker-/Pfad-Pruefung).
- Doppelladen in derselben Shell wird im Loader per Guard verhindert.
