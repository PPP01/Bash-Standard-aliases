# 85-mysql.sh

Optionales MySQL-Modul für CLI- und Backup-Aufgaben.

## Enthalten
- `my`: `mysql`
- `mya`: `mysqladmin`
- `myping`: `mysqladmin ping`
- `mysql_databases`: Zeigt alle Datenbanken
- `mysql_dump <db> [out.sql]`: SQL-Dump mit sinnvollen Optionen
- `mysql_dump_gz <db> [out.sql.gz]`: Komprimierter SQL-Dump

## Hinweise
- Das Modul ist in `alias_files.conf` standardmässig auskommentiert.
- Zugangsdaten sollten über `~/.my.cnf` oder passende Umgebungsparameter erfolgen.

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| my | mysql | Startet die MySQL-CLI. | mysql |
| mya | mysqladmin | Startet mysqladmin für Admin-Operationen. | mysqladmin |
| myping | mysqladmin ping | Prüft, ob der MySQL-Server antwortet. | mysqladmin ping |
