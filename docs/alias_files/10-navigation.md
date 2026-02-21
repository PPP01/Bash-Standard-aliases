# 10-navigation.sh

Navigation und Sicherheits-Defaults.

## Enthalten
- `..`: Eine Ebene hoch
- `...`: Zwei Ebenen hoch
- `....` / `.....`: Drei bzw. vier Ebenen hoch
- `-`: Zurueck ins vorherige Verzeichnis (`cd -`)
- `+1` bis `+4`: Wie `pushd +N` (Stack-Rotation)
- `-1` bis `-4`: Wie `pushd -N` (Stack-Rotation)
- `cdl`: Directory-Stack anzeigen (`dirs -v`)
- `p`: `pushd`
- `o`: `popd`
- `rm`: Interaktives Loeschen (`rm -i`)

## Alias-Hilfe (de)
| alias | kurz | beschreibung | befehl |
|---|---|---|---|
| rm | rm -i | Loescht interaktiv mit Rueckfrage. | rm -i |
| .. | cd .. | Wechselt ein Verzeichnis nach oben. | cd .. |
| ... | cd ../../ | Wechselt zwei Verzeichnisse nach oben. | cd ../../ |
| .... | cd ../../../ | Wechselt drei Verzeichnisse nach oben. | cd ../../../ |
| ..... | cd ../../../../ | Wechselt vier Verzeichnisse nach oben. | cd ../../../../ |
| .2 | cd ../../ | Wechselt zwei Verzeichnisse nach oben. | cd ../../ |
| .3 | cd ../../../ | Wechselt drei Verzeichnisse nach oben. | cd ../../../ |
| .4 | cd ../../../../ | Wechselt vier Verzeichnisse nach oben. | cd ../../../../ |
| .5 | cd ../../../../../ | Wechselt fuenf Verzeichnisse nach oben. | cd ../../../../../ |
| ~ | cd ~ | Wechselt ins Home-Verzeichnis. | cd ~ |
| - | cd - | Wechselt ins vorherige Verzeichnis. | cd - |
| cdl | dirs -v | Zeigt den Verzeichnis-Stack mit Indizes. | dirs -v |
| p | pushd | Legt Verzeichnisse per pushd auf den Stack. | pushd |
| o | popd | Nimmt das oberste Verzeichnis per popd vom Stack. | popd |
| +1 | pushd +1 | Springt zu Verzeichnis-Stack-Eintrag +1. | pushd +1 |
| +2 | pushd +2 | Springt zu Verzeichnis-Stack-Eintrag +2. | pushd +2 |
| +3 | pushd +3 | Springt zu Verzeichnis-Stack-Eintrag +3. | pushd +3 |
| +4 | pushd +4 | Springt zu Verzeichnis-Stack-Eintrag +4. | pushd +4 |
| -1 | pushd -1 | Springt zu Verzeichnis-Stack-Eintrag -1. | pushd -1 |
| -2 | pushd -2 | Springt zu Verzeichnis-Stack-Eintrag -2. | pushd -2 |
| -3 | pushd -3 | Springt zu Verzeichnis-Stack-Eintrag -3. | pushd -3 |
| -4 | pushd -4 | Springt zu Verzeichnis-Stack-Eintrag -4. | pushd -4 |
