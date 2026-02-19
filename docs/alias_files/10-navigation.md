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
