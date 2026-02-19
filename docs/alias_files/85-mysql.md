# 85-mysql.sh

Optionales MySQL-Modul fuer CLI- und Backup-Aufgaben.

## Enthalten
- `my`: `mysql`
- `mya`: `mysqladmin`
- `myping`: `mysqladmin ping`
- `mysql_databases`: Zeigt alle Datenbanken
- `mysql_dump <db> [out.sql]`: SQL-Dump mit sinnvollen Optionen
- `mysql_dump_gz <db> [out.sql.gz]`: Komprimierter SQL-Dump

## Hinweise
- Das Modul ist in `alias_files.conf` standardmaessig auskommentiert.
- Zugangsdaten sollten ueber `~/.my.cnf` oder passende Umgebungsparameter erfolgen.
