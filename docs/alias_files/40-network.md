# 40-network.sh

Netzwerk-Helfer.

## Enthalten
- `ports`: Offene Ports und zugehoerige Prozesse
- `myip`: Kurzuebersicht lokaler IP-Adressen
- `pingg`: Schnelltest Richtung internet (google.com)

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| ports | ss -tulpen | Zeigt offene Ports und zugehoerige Prozesse. | ss -tulpen |
| myip | ip -brief address | Zeigt lokale IP-Adressen kompakt an. | ip -brief address |
| pingg | ping -c 4 google.com | Testet Netzwerkverbindung zu google.com. | ping -c 4 google.com |
