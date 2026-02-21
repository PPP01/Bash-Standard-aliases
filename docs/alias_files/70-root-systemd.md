# 70-root-systemd.sh

Systemd-Shortcuts für root, inklusive Completion.

## Enthalten
- `start <service>`
- `restart <service>`
- `stop <service>`
- `reload <service>`
- `status <service>`

Jede Aktion zeigt danach direkt `systemctl status` an.
Tab-Completion liefert bekannte Unit-Namen.

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| start | systemd start + status | Startet einen Dienst und zeigt danach direkt den aktuellen Status. | systemctl start <service> && systemctl status <service> --no-pager |
| restart | systemd restart + status | Startet einen Dienst neu und zeigt danach direkt den aktuellen Status. | systemctl restart <service> && systemctl status <service> --no-pager |
| stop | systemd stop + status | Stoppt einen Dienst und zeigt danach direkt den aktuellen Status. | systemctl stop <service> && systemctl status <service> --no-pager |
| reload | systemd reload + status | Lädt die Konfiguration eines Dienstes neu und zeigt danach den Status. | systemctl reload <service> && systemctl status <service> --no-pager |
| status | systemd status | Zeigt den aktuellen Status eines Dienstes ohne Pager an. | systemctl status <service> --no-pager |
