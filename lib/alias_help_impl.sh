show_aliases_functions() {
  echo ""
  echo "==== Verfuegbare Aliase ===="
  alias
}

_alias_sorted_names() {
  local name=""
  _alias_runtime_cache_build
  for name in "${BASH_ALIAS_RUNTIME_SORTED_NAMES[@]}"; do
    printf '%s\n' "${name}"
  done
}

declare -gA BASH_ALIAS_HELP_SHORT=()
declare -gA BASH_ALIAS_HELP_DESC=()
declare -gA BASH_ALIAS_HELP_CMD=()
declare -g BASH_ALIAS_HELP_DATA_LOADED=0
declare -gA BASH_ALIAS_RUNTIME_VALUE=()
declare -ga BASH_ALIAS_RUNTIME_SORTED_NAMES=()
declare -gA BASH_ALIAS_RUNTIME_CATEGORY_NAMES=()
declare -g BASH_ALIAS_RUNTIME_CACHE_READY=0

: "${BASH_ALIAS_HELP_COLOR_DETAIL_LABEL:=\033[0;32m}"
: "${BASH_ALIAS_HELP_COLOR_MENU_TITLE:=\033[0;32m}"
: "${BASH_ALIAS_HELP_COLOR_MENU_META:=\033[0;36m}"
: "${BASH_ALIAS_HELP_COLOR_MENU_HEADER:=\033[1;36m}"
: "${BASH_ALIAS_HELP_COLOR_RESET:=\033[0m}"

_alias_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

_alias_menu_is_back_input() {
  local value="$1"
  case "${value}" in
    0|left|LEFT|Left|backspace|BACKSPACE|Backspace|$'\x7f'|$'\b'|$'\e[D') return 0 ;;
    *) return 1 ;;
  esac
}

_alias_menu_is_quit_input() {
  local value="$1"
  case "${value}" in
    q|Q|quit|QUIT|Quit|esc|ESC|Esc|escape|ESCAPE|Escape|$'\e') return 0 ;;
    *) return 1 ;;
  esac
}

_alias_menu_read_input() {
  local prompt="$1"
  local key=""
  local seq=""
  local value=""

  printf '%s' "${prompt}"
  while IFS= read -r -s -n 1 key; do
    case "${key}" in
      '')
        break
        ;;
      $'\e')
        if IFS= read -r -s -n 1 -t 0.05 seq; then
          if [ "${seq}" = "[" ] && IFS= read -r -s -n 1 -t 0.05 seq; then
            if [ "${seq}" = "D" ]; then
              echo ""
              REPLY="left"
              return 0
            fi
          fi
          continue
        fi
        echo ""
        REPLY="escape"
        return 0
        ;;
      $'\x7f'|$'\b')
        if [ -n "${value}" ]; then
          value="${value%?}"
          printf '\b \b'
        else
          echo ""
          REPLY="backspace"
          return 0
        fi
        ;;
      *)
        value+="${key}"
        printf '%s' "${key}"
        ;;
    esac
  done

  echo ""
  REPLY="${value}"
}

_alias_runtime_cache_reset() {
  BASH_ALIAS_RUNTIME_VALUE=()
  BASH_ALIAS_RUNTIME_SORTED_NAMES=()
  BASH_ALIAS_RUNTIME_CATEGORY_NAMES=()
  BASH_ALIAS_RUNTIME_CACHE_READY=0
}

_alias_runtime_cache_build() {
  local line=""
  local rest=""
  local name=""
  local value=""
  local category=""
  local -a raw_names=()

  if [ "${BASH_ALIAS_RUNTIME_CACHE_READY}" -eq 1 ]; then
    return 0
  fi

  BASH_ALIAS_RUNTIME_VALUE=()
  BASH_ALIAS_RUNTIME_SORTED_NAMES=()
  BASH_ALIAS_RUNTIME_CATEGORY_NAMES=()

  while IFS= read -r line; do
    [[ "${line}" == alias[[:space:]]* ]] || continue
    rest="${line#alias }"
    if [[ "${rest}" == --[[:space:]]* ]]; then
      rest="${rest#-- }"
    fi

    name="${rest%%=*}"
    value="${rest#*=}"
    name="$(_alias_trim "${name}")"
    [ -z "${name}" ] && continue

    value="${value#\'}"
    value="${value%\'}"

    BASH_ALIAS_RUNTIME_VALUE["${name}"]="${value}"
    raw_names+=( "${name}" )
  done < <(alias)

  if [ "${#raw_names[@]}" -gt 0 ]; then
    while IFS= read -r name; do
      [ -z "${name}" ] && continue
      BASH_ALIAS_RUNTIME_SORTED_NAMES+=( "${name}" )
    done < <(printf '%s\n' "${raw_names[@]}" | LC_ALL=C sort -u)
  fi

  for name in "${BASH_ALIAS_RUNTIME_SORTED_NAMES[@]}"; do
    category="${BASH_ALIAS_ALIAS_CATEGORY[${name}]:-}"
    [ -z "${category}" ] && continue
    BASH_ALIAS_RUNTIME_CATEGORY_NAMES["${category}"]+="${name}"$'\n'
  done

  BASH_ALIAS_RUNTIME_CACHE_READY=1
}

_alias_help_doc_path() {
  local base_dir="${BASH_ALIAS_REPO_DIR:-}"

  if [ -z "${base_dir}" ]; then
    base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi

  printf '%s/docs/alias_files' "${base_dir}"
}

_alias_help_select_doc_variant() {
  local base_file="$1"
  local lang="$2"
  local doc_dir="$3"
  local base_name=""
  local stem=""

  base_name="$(basename "${base_file}")"
  stem="${base_name%.md}"

  if [ -f "${doc_dir}/${lang}/${base_name}" ]; then
    printf '%s' "${doc_dir}/${lang}/${base_name}"
    return 0
  fi

  if [ -f "${doc_dir}/${stem}.${lang}.md" ]; then
    printf '%s' "${doc_dir}/${stem}.${lang}.md"
    return 0
  fi

  printf '%s' "${base_file}"
}

_alias_help_load_data() {
  local doc_dir=""
  local locale="${BASH_ALIAS_LOCALE:-de}"
  local lang="${locale%%_*}"
  local -a base_files=()
  local -a files=()
  local selected_file=""
  local file=""
  local line=""
  local in_help_section=0
  local alias_name=""
  local short_text=""
  local desc_text=""
  local cmd_text=""
  local custom_file=""

  if [ "${BASH_ALIAS_HELP_DATA_LOADED}" -eq 1 ]; then
    return 0
  fi
  BASH_ALIAS_HELP_DATA_LOADED=1

  doc_dir="$(_alias_help_doc_path)"
  [ -d "${doc_dir}" ] || return 0

  shopt -s nullglob
  base_files=( "${doc_dir}"/[0-9][0-9]-*.md )
  shopt -u nullglob
  [ "${#base_files[@]}" -eq 0 ] && return 0

  while IFS= read -r file; do
    selected_file="$(_alias_help_select_doc_variant "${file}" "${lang}" "${doc_dir}")"
    files+=( "${selected_file}" )
  done < <(printf '%s\n' "${base_files[@]}" | LC_ALL=C sort)

  if [ -n "${BASH_ALIAS_REPO_DIR:-}" ]; then
    custom_file="${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific.md"
    if [ -f "${custom_file}" ]; then
      files+=( "${custom_file}" )
    fi
  fi

  custom_file="${HOME}/.bash_aliases_specific.md"
  if [ -f "${custom_file}" ]; then
    files+=( "${custom_file}" )
  fi

  for file in "${files[@]}"; do
    in_help_section=0
    while IFS= read -r line; do
      if [[ "${line}" =~ ^##[[:space:]]+Alias-Hilfe ]]; then
        in_help_section=1
        continue
      fi
      if [[ "${line}" =~ ^##[[:space:]]+ ]] && [ "${in_help_section}" -eq 1 ]; then
        in_help_section=0
      fi
      [ "${in_help_section}" -eq 1 ] || continue
      [[ "${line}" != \|* ]] && continue
      IFS='|' read -r _ alias_name short_text desc_text cmd_text _ <<< "${line}"

      alias_name="$(_alias_trim "${alias_name}")"
      short_text="$(_alias_trim "${short_text}")"
      desc_text="$(_alias_trim "${desc_text}")"
      cmd_text="$(_alias_trim "${cmd_text}")"

      [ -z "${alias_name}" ] && continue
      [ "${alias_name}" = "alias" ] && continue
      [ "${alias_name}" = "---" ] && continue

      short_text="${short_text//\\|/|}"
      desc_text="${desc_text//\\|/|}"
      cmd_text="${cmd_text//\\|/|}"

      BASH_ALIAS_HELP_SHORT["${alias_name}"]="${short_text}"
      BASH_ALIAS_HELP_DESC["${alias_name}"]="${desc_text}"
      BASH_ALIAS_HELP_CMD["${alias_name}"]="${cmd_text}"
    done < "${file}"
  done
}

_alias_help_get() {
  local field="$1"
  local name="$2"

  _alias_help_load_data

  case "${field}" in
    short) REPLY="${BASH_ALIAS_HELP_SHORT[${name}]:-}" ;;
    desc) REPLY="${BASH_ALIAS_HELP_DESC[${name}]:-}" ;;
    cmd) REPLY="${BASH_ALIAS_HELP_CMD[${name}]:-}" ;;
    *) REPLY="" ;;
  esac
}

_alias_text() {
  local key="$1"
  local locale="${BASH_ALIAS_LOCALE:-de}"

  case "${locale}" in
    de*)
      case "${key}" in
        categories_title) printf 'Alias-Kategorien:' ;;
        categories_prompt) printf 'Kategorie (Name/Nummer, 0 = alle, q/esc = Ende): ' ;;
        categories_invalid) printf 'Ungueltige Eingabe. Menue wird beendet.' ;;
        categories_back) printf 'Alle Kategorien' ;;
        all_categories_title) printf 'Alle Kategorien' ;;
        all_categories_prompt) printf 'Kategorie wählen (0/left/backspace = Zurück, q/esc = Ende): ' ;;
        all_categories_back) printf 'Zurück zur Hauptauswahl' ;;
        category_prompt) printf 'Alias wählen (Nummer, 0/left/backspace = Zurück, q/esc = Ende): ' ;;
        category_empty) printf '(keine geladenen Aliase)' ;;
        category_back) printf 'Zurück zur Kategorienauswahl' ;;
        table_col_no) printf 'no)' ;;
        table_col_alias) printf 'alias' ;;
        table_col_short) printf 'kurzbeschreibung' ;;
        alias_invalid) printf 'Ungueltige Eingabe. Menue wird beendet.' ;;
        alias_detail_title) printf 'Alias-Details' ;;
        alias_detail_desc) printf 'Beschreibung' ;;
        alias_detail_cmd) printf 'Befehl' ;;
        alias_detail_prompt) printf 'Enter = ausfuehren, 0/left/backspace = Zurück, q/esc = Ende: ' ;;
        alias_unknown) printf 'Unbekannter Alias: %s' ;;
        short_internal) printf 'Interner Helfer: %s' ;;
        desc_fallback) printf 'Fuehrt aus: %s' ;;
        *) printf '%s' "${key}" ;;
      esac
      ;;
    *)
      case "${key}" in
        categories_title) printf 'Alias categories:' ;;
        categories_prompt) printf 'Category (name/number, 0 = all, q/esc = quit): ' ;;
        categories_invalid) printf 'Invalid input. Exiting menu.' ;;
        categories_back) printf 'All categories' ;;
        all_categories_title) printf 'All categories' ;;
        all_categories_prompt) printf 'Choose category (0/left/backspace = back, q/esc = quit): ' ;;
        all_categories_back) printf 'Back to main menu' ;;
        category_prompt) printf 'Choose alias (number, 0/left/backspace = back, q/esc = quit): ' ;;
        category_empty) printf '(no loaded aliases)' ;;
        category_back) printf 'Back to category menu' ;;
        table_col_no) printf 'no)' ;;
        table_col_alias) printf 'alias' ;;
        table_col_short) printf 'short description' ;;
        alias_invalid) printf 'Invalid input. Exiting menu.' ;;
        alias_detail_title) printf 'Alias details' ;;
        alias_detail_desc) printf 'Description' ;;
        alias_detail_cmd) printf 'Command' ;;
        alias_detail_prompt) printf 'Enter = run, 0/left/backspace = back, q/esc = quit: ' ;;
        alias_unknown) printf 'Unknown alias: %s' ;;
        short_internal) printf 'Internal helper: %s' ;;
        desc_fallback) printf 'Runs: %s' ;;
        *) printf '%s' "${key}" ;;
      esac
      ;;
  esac
}

_alias_value_for_name() {
  local name="$1"
  local value=""

  _alias_runtime_cache_build
  value="${BASH_ALIAS_RUNTIME_VALUE[${name}]:-}"
  [ -n "${value}" ] || return 1
  REPLY="${value}"
}

_alias_short_description_for_name() {
  local name="$1"
  local cmd="$2"
  local from_docs=""

  _alias_help_get short "${name}"
  from_docs="${REPLY:-}"
  if [ -n "${from_docs}" ]; then
    REPLY="${from_docs}"
    return 0
  fi

  case "${name}" in
    log) REPLY='Journal: letzte X Zeilen (Standard 50).' ;;
    logs) REPLY='Journal: Service-Logs der letzten X Zeilen.' ;;
    log_min) REPLY='Journal seit X Minuten (Standard 10).' ;;
    log_hour) REPLY='Journal seit X Stunden (Standard 1).' ;;
    log_clean) REPLY='Journal aufbewahren/bereinigen (Tage/Groesse).' ;;
    aua) REPLY='APT Update/Upgrade/Autoremove in einem Lauf.' ;;
    _self_update) REPLY='Repository aktualisieren und Aliase neu laden.' ;;
    _self_setup) REPLY='Marker-Pruefung, dann Kategorie-Setup oder Installation.' ;;
    _self_setup_remove) REPLY='Setup-Marker aus Bash-Startdatei entfernen.' ;;
    _self_category_setup) REPLY='Interaktives Kategorie-Setup starten.' ;;
    _self_reload) REPLY='Alias-Module in aktueller Shell neu laden.' ;;
    _self_edit) REPLY='Gefuehrter Assistent fuer eigenes Alias und Reload.' ;;
    _self_test_reload) REPLY='Reload-Konsistenztest fuer Alias-Kategorien.' ;;
    *)
      REPLY="${cmd}"
      ;;
  esac
}

_alias_description_for_name() {
  local name="$1"
  local cmd="$2"
  local locale="${BASH_ALIAS_LOCALE:-de}"
  local from_docs=""

  _alias_help_get desc "${name}"
  from_docs="${REPLY:-}"
  if [ -n "${from_docs}" ]; then
    REPLY="${from_docs}"
    return 0
  fi

  case "${locale}" in
    de*)
      case "${name}" in
        ls) REPLY='Listet Dateien im aktuellen Verzeichnis farbig auf.' ;;
        la) REPLY='Listet alle Dateien inkl. versteckter Dateien im langen, menschenlesbaren Format.' ;;
        ll) REPLY='Listet alle Dateien inkl. versteckter Dateien im langen, menschenlesbaren Format.' ;;
        grep) REPLY='Sucht Textmuster farbig hervorgehoben.' ;;
        rm) REPLY='Loescht interaktiv mit Rueckfrage.' ;;
        ..) REPLY='Wechselt ein Verzeichnis nach oben.' ;;
        ...) REPLY='Wechselt zwei Verzeichnisse nach oben.' ;;
        ....) REPLY='Wechselt drei Verzeichnisse nach oben.' ;;
        .....) REPLY='Wechselt vier Verzeichnisse nach oben.' ;;
        .2) REPLY='Wechselt zwei Verzeichnisse nach oben.' ;;
        .3) REPLY='Wechselt drei Verzeichnisse nach oben.' ;;
        .4) REPLY='Wechselt vier Verzeichnisse nach oben.' ;;
        .5) REPLY='Wechselt fuenf Verzeichnisse nach oben.' ;;
        '~') REPLY='Wechselt ins Home-Verzeichnis.' ;;
        -) REPLY='Wechselt ins vorherige Verzeichnis.' ;;
        cdl) REPLY='Zeigt den Verzeichnis-Stack mit Indizes.' ;;
        p) REPLY='Legt Verzeichnisse per pushd auf den Stack.' ;;
        o) REPLY='Nimmt das oberste Verzeichnis per popd vom Stack.' ;;
        +1|+2|+3|+4|-1|-2|-3|-4) REPLY='Springt zu einem Eintrag im Verzeichnis-Stack.' ;;
        h) REPLY='Zeigt die Shell-History.' ;;
        dfh) REPLY='Zeigt Dateisystem-Auslastung in menschenlesbarer Form.' ;;
        duh) REPLY='Zeigt Speicherverbrauch pro Unterordner bis Tiefe 1.' ;;
        freeh) REPLY='Zeigt RAM- und Swap-Auslastung in menschenlesbarer Form.' ;;
        psg) REPLY='Sucht Prozesse per grep in der Prozessliste.' ;;
        psmem) REPLY='Zeigt Top-Prozesse nach RAM-Verbrauch.' ;;
        pscpu) REPLY='Zeigt Top-Prozesse nach CPU-Verbrauch.' ;;
        g) REPLY='Kurzform fuer git.' ;;
        gs) REPLY='Zeigt den Git-Status kurz inkl. Branch-Info.' ;;
        ga) REPLY='Fuegt Dateien zur Git-Staging-Area hinzu.' ;;
        gaa) REPLY='Fuegt alle Aenderungen zur Git-Staging-Area hinzu.' ;;
        gb) REPLY='Zeigt lokale Git-Branches.' ;;
        gba) REPLY='Zeigt lokale und Remote-Branches.' ;;
        gbd) REPLY='Loescht einen lokalen Branch.' ;;
        gco) REPLY='Wechselt auf einen Branch oder Commit.' ;;
        gcb) REPLY='Erstellt einen neuen Branch und wechselt darauf.' ;;
        gc) REPLY='Erstellt einen neuen Commit (Editor).' ;;
        gcm) REPLY='Erstellt einen Commit mit direkter Nachricht.' ;;
        gca) REPLY='Aendert den letzten Commit (amend).' ;;
        gcan) REPLY='Aendert den letzten Commit ohne neue Nachricht.' ;;
        gd) REPLY='Zeigt nicht gestagte Aenderungen.' ;;
        gds) REPLY='Zeigt gestagte Aenderungen.' ;;
        gl) REPLY='Zeigt kompakten Git-Graph-Log.' ;;
        gf) REPLY='Holt alle Remotes und bereinigt veraltete Referenzen.' ;;
        gpl) REPLY='Fuehrt git pull nur als Fast-Forward aus.' ;;
        gp) REPLY='Fuehrt git push auf das konfigurierte Ziel aus.' ;;
        gpf) REPLY='Fuehrt git push mit --force-with-lease aus (sicherer Force-Push).' ;;
        gr) REPLY='Setzt Aenderungen im Working Tree auf HEAD Zurück.' ;;
        grs) REPLY='Entfernt Dateien aus der Staging-Area.' ;;
        gst) REPLY='Speichert den aktuellen Arbeitsstand in einem Stash.' ;;
        gstp) REPLY='Spielt den letzten Git-Stash wieder ein.' ;;
        ports) REPLY='Zeigt offene Ports und zugehoerige Prozesse.' ;;
        myip) REPLY='Zeigt lokale IP-Adressen kompakt an.' ;;
        pingg) REPLY='Testet Netzwerkverbindung zu google.com.' ;;
        log) REPLY='Zeigt die letzten Journal-Logs (Standard 50 Zeilen, root-Funktion).' ;;
        logs) REPLY='Zeigt Journal-Logs fuer einen Dienst mit optionaler Zeilenanzahl (root-Funktion).' ;;
        log_min) REPLY='Zeigt Journal-Logs der letzten X Minuten (Standard 10, root-Funktion).' ;;
        log_hour) REPLY='Zeigt Journal-Logs der letzten X Stunden (Standard 1, root-Funktion).' ;;
        log_clean) REPLY='Bereinigt Journal-Logs nach Aufbewahrungszeit/Groesse (root-Funktion).' ;;
        agi) REPLY='Installiert ein Paket via apt install (root).' ;;
        agr) REPLY='Entfernt ein Paket via apt remove (root).' ;;
        acs) REPLY='Sucht Pakete via apt search.' ;;
        agu) REPLY='Aktualisiert Paketlisten via apt update (root).' ;;
        agg) REPLY='Fuehrt Paket-Upgrade via apt upgrade aus (root).' ;;
        aga) REPLY='Entfernt unnoetige Pakete via apt autoremove (root).' ;;
        agl) REPLY='Zeigt alle upgradefähigen Pakete.' ;;
        aua) REPLY='Fuehrt apt update, upgrade und autoremove als Gesamt-Update aus (root).' ;;
        my) REPLY='Startet die MySQL-CLI.' ;;
        mya) REPLY='Startet mysqladmin fuer Admin-Operationen.' ;;
        myping) REPLY='Prueft, ob der MySQL-Server antwortet.' ;;
        _self_update) REPLY='Aktualisiert dieses Alias-Repository per git pull und lädt neu.' ;;
        _self_setup) REPLY='Prueft Marker zuerst (/etc/bash.bashrc bei root, sonst Alias-Datei/.bashrc) und startet dann Kategorie-Setup oder Installation.' ;;
        _self_setup_remove) REPLY='Entfernt den markierten Setup-Block aus der erkannten Bash-Startdatei.' ;;
        _self_category_setup) REPLY='Startet den interaktiven Kategorie-Setup-Assistenten.' ;;
        _self_reload) REPLY='Lädt die Alias-Module in der aktuellen Shell neu (Repo-Reload).' ;;
        _self_edit) REPLY='Startet einen Assistenten und legt ein Alias mit Beschreibung an; danach Reload.' ;;
        _self_test_reload) REPLY='Prueft automatisiert, ob Alias-Kategorien nach Reload konsistent bleiben.' ;;
        *) REPLY="$(printf "$(_alias_text desc_fallback)" "${cmd}")" ;;
      esac
      ;;
    *)
      REPLY="$(printf "$(_alias_text desc_fallback)" "${cmd}")"
      ;;
  esac
}

_alias_detail_command_for_name() {
  local name="$1"
  local cmd="$2"
  local from_docs=""

  _alias_help_get cmd "${name}"
  from_docs="${REPLY:-}"
  if [ -n "${from_docs}" ]; then
    REPLY="${from_docs}"
    return 0
  fi

  case "${name}" in
    log) REPLY='journalctl -n <X> --no-pager  (Standard: X=50)' ;;
    logs) REPLY='journalctl -u <service> -n <X> --no-pager  (Standard: X=50)' ;;
    log_min) REPLY='journalctl --since \"<X> minutes ago\" --no-pager  (Standard: X=10)' ;;
    log_hour) REPLY='journalctl --since \"<X> hours ago\" --no-pager  (Standard: X=1)' ;;
    log_clean) REPLY='journalctl --vacuum-time=<tage>d --vacuum-size=<groesse>  (Standard: 2d, 100M)' ;;
    aua) REPLY='apt update && apt upgrade [-y] && apt autoremove [-y]' ;;
    _self_update) REPLY='git pull --ff-only && alias_repo_reload  (Standardmodus)' ;;
    _self_reload) REPLY='alias_repo_reload  (Alias-Loader in aktueller Shell neu laden)' ;;
    _self_setup) REPLY='bash \"$BASH_ALIAS_REPO_DIR/scripts/alias_self_setup.sh\"' ;;
    _self_setup_remove) REPLY='bash \"$BASH_ALIAS_REPO_DIR/scripts/alias_self_setup.sh\" --remove' ;;
    _self_category_setup) REPLY='bash \"$BASH_ALIAS_REPO_DIR/scripts/alias_category_setup.sh\"' ;;
    _self_test_reload) REPLY='bash \"$BASH_ALIAS_REPO_DIR/scripts/test_reload_category_mapping.sh\"' ;;
    _self_edit) REPLY='alias_self_edit  (Alias-Assistent mit Ziel-Datei-Auswahl und Reload)' ;;
    *) REPLY="${cmd}" ;;
  esac
}

_alias_resolve_category_input() {
  local raw="$1"
  local lowered=""
  local category=""
  local found=""
  local count=0

  lowered="$(printf '%s' "${raw}" | tr '[:upper:]' '[:lower:]')"

  [ "${lowered}" = "all" ] && {
    printf 'all'
    return 0
  }

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    if [ "${category}" = "${lowered}" ]; then
      printf '%s' "${category}"
      return 0
    fi
  done

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    case "${category}" in
      "${lowered}"*)
        found="${category}"
        count=$((count + 1))
        ;;
    esac
  done

  if [ "${count}" -eq 1 ]; then
    printf '%s' "${found}"
    return 0
  fi

  return 1
}

_alias_print_category_list() {
  local category=""
  local state=""
  local number=""

  echo "" >&2
  printf '%b%s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_TITLE}" "$(_alias_text categories_title)" "${BASH_ALIAS_HELP_COLOR_RESET}" >&2
  printf ' %3d) %-12s\n' 0 "$(_alias_text categories_back)" >&2

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    state="off"
    if [ "${BASH_ALIAS_CATEGORY_ENABLED[${category}]:-0}" -eq 1 ]; then
      state="on"
    fi
    number="$(_alias_category_number_for_name "${category}")" || continue
    printf ' %3d) %-12s [%s]\n' "${number}" "${category}" "${state}" >&2
  done
}

_alias_names_for_category() {
  local category="$1"
  local names_block=""
  _alias_runtime_cache_build
  names_block="${BASH_ALIAS_RUNTIME_CATEGORY_NAMES[${category}]:-}"
  [ -n "${names_block}" ] && printf '%s' "${names_block}"
}

_alias_category_is_visible() {
  local category="$1"
  local names_block=""

  _alias_runtime_cache_build
  names_block="${BASH_ALIAS_RUNTIME_CATEGORY_NAMES[${category}]:-}"
  [ -n "${names_block}" ]
}

_alias_reserved_number_for_category() {
  case "$1" in
    _own) printf '98' ;;
    _setup) printf '99' ;;
    *) return 1 ;;
  esac
}

_alias_category_number_for_name() {
  local wanted="$1"
  local category=""
  local number=1
  local reserved_own=98
  local reserved_setup=99
  local reserved_number=""

  if reserved_number="$(_alias_reserved_number_for_category "${wanted}")"; then
    _alias_category_is_visible "${wanted}" || return 1
    printf '%s' "${reserved_number}"
    return 0
  fi

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    [ "${category}" = "_own" ] && continue
    [ "${category}" = "_setup" ] && continue
    _alias_category_is_visible "${category}" || continue
    if [ "${number}" -eq "${reserved_own}" ] || [ "${number}" -eq "${reserved_setup}" ]; then
      number=$((number + 1))
    fi
    if [ "${category}" = "${wanted}" ]; then
      printf '%s' "${number}"
      return 0
    fi
    number=$((number + 1))
  done

  return 1
}

_alias_category_name_for_number() {
  local wanted="$1"
  local category=""
  local number=1
  local reserved_own=98
  local reserved_setup=99

  if [ "${wanted}" -eq "${reserved_own}" ]; then
    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      if [ "${category}" = "_own" ]; then
        _alias_category_is_visible "${category}" || return 1
        printf '%s' "${category}"
        return 0
      fi
    done
    return 1
  fi

  if [ "${wanted}" -eq "${reserved_setup}" ]; then
    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      if [ "${category}" = "_setup" ]; then
        _alias_category_is_visible "${category}" || return 1
        printf '%s' "${category}"
        return 0
      fi
    done
    return 1
  fi

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    [ "${category}" = "_own" ] && continue
    [ "${category}" = "_setup" ] && continue
    _alias_category_is_visible "${category}" || continue
    if [ "${number}" -eq "${reserved_own}" ] || [ "${number}" -eq "${reserved_setup}" ]; then
      number=$((number + 1))
    fi
    if [ "${number}" -eq "${wanted}" ]; then
      printf '%s' "${category}"
      return 0
    fi
    number=$((number + 1))
  done

  return 1
}

_alias_show_alias_details() {
  local name="$1"
  local raw_cmd=""
  local cmd=""
  local desc=""

  _alias_value_for_name "${name}" || raw_cmd=""
  raw_cmd="${REPLY:-}"
  _alias_description_for_name "${name}" "${raw_cmd}"
  desc="${REPLY:-}"
  _alias_detail_command_for_name "${name}" "${raw_cmd}"
  cmd="${REPLY:-}"

  echo ""
  echo "=== $(_alias_text alias_detail_title): ${name} ==="
  printf '%b%s%b: %s\n' "${BASH_ALIAS_HELP_COLOR_DETAIL_LABEL}" "$(_alias_text alias_detail_desc)" "${BASH_ALIAS_HELP_COLOR_RESET}" "${desc}"
  printf '%b%s%b: %s\n' "${BASH_ALIAS_HELP_COLOR_DETAIL_LABEL}" "$(_alias_text alias_detail_cmd)" "${BASH_ALIAS_HELP_COLOR_RESET}" "${cmd}"
  return 0
}

_alias_execute_by_name() {
  local name="$1"

  if ! builtin alias -- "${name}" >/dev/null 2>&1; then
    printf "$(_alias_text alias_unknown)\n" "${name}"
    return 1
  fi

  eval "${name}"
}

_alias_menu_alias_details() {
  local name="$1"
  local choice=""

  _alias_show_alias_details "${name}" || return 1
  _alias_menu_read_input "$(_alias_text alias_detail_prompt)"
  choice="${REPLY:-}"

  if _alias_menu_is_quit_input "${choice}"; then
    return 130
  fi
  if _alias_menu_is_back_input "${choice}"; then
    return 0
  fi
  if [ -z "${choice}" ]; then
    _alias_execute_by_name "${name}"
    return $?
  fi

  echo "$(_alias_text alias_invalid)"
  return 1
}

_alias_menu_category() {
  local category="$1"
  local show_back_entry="${2:-1}"
  local number_re='^[0-9]+$'
  local choice=""
  local idx=1
  local name=""
  local raw_cmd=""
  local short_desc=""
  local -a names=()

  while true; do
    names=()
    while IFS= read -r name; do
      [ -z "${name}" ] && continue
      names+=("${name}")
    done < <(_alias_names_for_category "${category}")

    echo ""
    printf '%b=== %s ===%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_TITLE}" "${category}" "${BASH_ALIAS_HELP_COLOR_RESET}"
    if [ "${show_back_entry}" -eq 1 ]; then
      printf '%b %3d) %s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_META}" 0 "$(_alias_text category_back)" "${BASH_ALIAS_HELP_COLOR_RESET}"
    fi
    printf '%b %4s | %-18s | %s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_HEADER}" "$(_alias_text table_col_no)" "$(_alias_text table_col_alias)" "$(_alias_text table_col_short)" "${BASH_ALIAS_HELP_COLOR_RESET}"

    if [ "${#names[@]}" -eq 0 ]; then
      echo "$(_alias_text category_empty)"
    else
      idx=1
      for name in "${names[@]}"; do
        _alias_value_for_name "${name}" || raw_cmd=""
        raw_cmd="${REPLY:-}"
        _alias_short_description_for_name "${name}" "${raw_cmd}"
        short_desc="${REPLY:-}"
        printf ' %3d) | %-18s | %s\n' "${idx}" "${name}" "${short_desc}"
        idx=$((idx + 1))
      done
    fi

    _alias_menu_read_input "$(_alias_text category_prompt)"
    choice="${REPLY:-}"
    if _alias_menu_is_quit_input "${choice}"; then
      return 130
    fi
    if _alias_menu_is_back_input "${choice}"; then
      return 0
    fi
    if ! [[ "${choice}" =~ ${number_re} ]]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    if [ "${choice}" -lt 1 ] || [ "${choice}" -gt "${#names[@]}" ]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    _alias_menu_alias_details "${names[$((choice - 1))]}"
    case "$?" in
      0) ;;
      130) return 130 ;;
      *) return 1 ;;
    esac
  done
}

_alias_show_all_categories() {
  local category=""
  local name=""
  local found=0
  local idx=1
  local raw_cmd=""
  local short_desc=""

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    echo ""
    printf '%b=== %s ===%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_TITLE}" "${category}" "${BASH_ALIAS_HELP_COLOR_RESET}"
    printf '%b %4s | %-18s | %s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_HEADER}" "$(_alias_text table_col_no)" "$(_alias_text table_col_alias)" "$(_alias_text table_col_short)" "${BASH_ALIAS_HELP_COLOR_RESET}"
    found=0
    idx=1
    while IFS= read -r name; do
      [ -z "${name}" ] && continue
      _alias_value_for_name "${name}" || raw_cmd=""
      raw_cmd="${REPLY:-}"
      _alias_short_description_for_name "${name}" "${raw_cmd}"
      short_desc="${REPLY:-}"
      printf ' %3d) | %-18s | %s\n' "${idx}" "${name}" "${short_desc}"
      idx=$((idx + 1))
      found=1
    done < <(_alias_names_for_category "${category}")

    if [ "${found}" -eq 0 ]; then
      echo "$(_alias_text category_empty)"
    fi
  done
}

_alias_menu_all_categories() {
  local choice=""
  local number_re='^[0-9]+$'
  local category=""
  local number=""

  while true; do
    echo ""
    printf '%b=== %s ===%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_TITLE}" "$(_alias_text all_categories_title)" "${BASH_ALIAS_HELP_COLOR_RESET}"
    printf '%b %3d) %s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_META}" 0 "$(_alias_text all_categories_back)" "${BASH_ALIAS_HELP_COLOR_RESET}"

    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      _alias_category_is_visible "${category}" || continue
      number="$(_alias_category_number_for_name "${category}")" || continue
      printf ' %3d) %s\n' "${number}" "${category}"
    done

    _alias_menu_read_input "$(_alias_text all_categories_prompt)"
    choice="${REPLY:-}"
    if _alias_menu_is_quit_input "${choice}"; then
      return 130
    fi
    if _alias_menu_is_back_input "${choice}"; then
      return 0
    fi
    if ! [[ "${choice}" =~ ${number_re} ]]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    category="$(_alias_category_name_for_number "${choice}")" || {
      echo "$(_alias_text alias_invalid)"
      return 1
    }
    _alias_menu_category "${category}"
    case "$?" in
      0) ;;
      130) return 130 ;;
      *) return 1 ;;
    esac
    continue

  done
}

_alias_pick_category_interactive() {
  local choice=""
  local number_re='^[0-9]+$'
  local category=""
  local rc=0

  while true; do
    _alias_print_category_list
    _alias_menu_read_input "$(_alias_text categories_prompt)"
    choice="${REPLY:-}"
    if _alias_menu_is_quit_input "${choice}"; then
      return 0
    fi
    if _alias_menu_is_back_input "${choice}" && [ "${choice}" != "0" ]; then
      return 0
    fi
    [ -z "${choice}" ] && {
      echo "$(_alias_text categories_invalid)"
      return 1
    }

    if [[ "${choice}" =~ ${number_re} ]]; then
      if [ "${choice}" -eq 0 ]; then
        _alias_menu_all_categories
        rc=$?
        case "${rc}" in
          0) ;;
          130) return 0 ;;
          *) return 1 ;;
        esac
        continue
      fi

      category="$(_alias_category_name_for_number "${choice}")" || {
        echo "$(_alias_text categories_invalid)"
        return 1
      }
      _alias_menu_category "${category}"
      case "$?" in
        0) ;;
        130) return 0 ;;
        *) return 1 ;;
      esac
      continue
    fi
    category="$(_alias_resolve_category_input "${choice}")" || {
      echo "$(_alias_text categories_invalid)"
      return 1
    }
    _alias_menu_category "${category}"
    case "$?" in
      0) ;;
      130) return 0 ;;
      *) return 1 ;;
    esac
  done
}

a() {
  local category=""
  local rc=0
  _alias_runtime_cache_reset

  if [ -n "${1:-}" ]; then
    if builtin alias -- "$1" >/dev/null 2>&1; then
      _alias_show_alias_details "$1"
      return $?
    fi

    category="$(_alias_resolve_category_input "$1")" || {
      echo "Unbekannter Alias oder Kategorie: $1"
      echo "Nutze 'a' fuer Auswahl."
      return 1
    }
  else
    _alias_pick_category_interactive
    rc=$?
    case "${rc}" in
      130) return 0 ;;
      *) return "${rc}" ;;
    esac
  fi

  if [ "${category}" = "all" ]; then
    _alias_show_all_categories
    return 0
  fi

  _alias_menu_category "${category}" 0
  rc=$?
  case "${rc}" in
    130) return 0 ;;
    *) return "${rc}" ;;
  esac
}

_alias_category_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local words="all"
  local category=""

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    words+=" ${category}"
  done

  COMPREPLY=( $(compgen -W "${words}" -- "${cur}") )
}

complete -F _alias_category_completion a

alias_self_test_reload() {
  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "Fehler: BASH_ALIAS_REPO_DIR ist nicht gesetzt."
    return 1
  fi

  bash "${BASH_ALIAS_REPO_DIR}/scripts/test_reload_category_mapping.sh"
}

alias _self_test_reload='alias_self_test_reload'
