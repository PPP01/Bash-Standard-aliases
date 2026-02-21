# 30-process.sh

Prozessanalyse.

## Enthalten
- `psg`: Prozesse filtern (grep)
- `psmem`: Top-Prozesse nach RAM
- `pscpu`: Top-Prozesse nach CPU

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| psg | Prozesse filtern | Sucht Prozesse per grep in der Prozessliste. | ps aux \| grep -i --color=auto |
| psmem | Top-20 RAM | Zeigt Top-Prozesse nach RAM-Verbrauch. | ps aux --sort=-%mem \| head -n 20 |
| pscpu | Top-20 CPU | Zeigt Top-Prozesse nach CPU-Verbrauch. | ps aux --sort=-%cpu \| head -n 20 |
