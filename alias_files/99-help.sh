show_aliases_functions() {
  echo ""
  echo "==== Verfuegbare Aliase ===="
  alias
}

_alias_sorted_names() {
  alias | sed -E "s/^alias[[:space:]]+--[[:space:]]+([^=]+)=.*/\1/; t; s/^alias[[:space:]]+([^=]+)=.*/\1/" | LC_ALL=C sort -u
}

declare -gA BASH_ALIAS_HELP_SHORT=()
declare -gA BASH_ALIAS_HELP_DESC=()
declare -gA BASH_ALIAS_HELP_CMD=()
declare -g BASH_ALIAS_HELP_DATA_LOADED=0

_alias_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
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
    short) printf '%s' "${BASH_ALIAS_HELP_SHORT[${name}]:-}" ;;
    desc) printf '%s' "${BASH_ALIAS_HELP_DESC[${name}]:-}" ;;
    cmd) printf '%s' "${BASH_ALIAS_HELP_CMD[${name}]:-}" ;;
    *) printf '' ;;
  esac
}

_alias_text() {
  local key="$1"
  local locale="${BASH_ALIAS_LOCALE:-de}"

  case "${locale}" in
    de*)
      case "${key}" in
        categories_title) printf 'Alias-Kategorien:' ;;
        categories_prompt) printf 'Kategorie (Name oder Nummer, 0 = alle): ' ;;
        categories_invalid) printf 'Ungueltige Eingabe. Menue wird beendet.' ;;
        categories_back) printf 'Alle Kategorien' ;;
        all_categories_title) printf 'Alle Kategorien' ;;
        all_categories_prompt) printf 'Kategorie waehlen (0 = Zurueck): ' ;;
        all_categories_back) printf 'Zurueck zur Hauptauswahl' ;;
        category_prompt) printf 'Alias-Nummer waehlen (0 = Zurueck): ' ;;
        category_empty) printf '(keine geladenen Aliase)' ;;
        category_back) printf 'Zurueck zur Kategorienauswahl' ;;
        table_col_no) printf 'no)' ;;
        table_col_alias) printf 'alias' ;;
        table_col_short) printf 'kurzbeschreibung' ;;
        alias_invalid) printf 'Ungueltige Eingabe. Menue wird beendet.' ;;
        alias_detail_title) printf 'Alias-Details' ;;
        alias_detail_desc) printf 'Beschreibung' ;;
        alias_detail_cmd) printf 'Befehl' ;;
        alias_unknown) printf 'Unbekannter Alias: %s' ;;
        short_internal) printf 'Interner Helfer: %s' ;;
        desc_fallback) printf 'Fuehrt aus: %s' ;;
        *) printf '%s' "${key}" ;;
      esac
      ;;
    *)
      case "${key}" in
        categories_title) printf 'Alias categories:' ;;
        categories_prompt) printf 'Category (name or number, 0 = all): ' ;;
        categories_invalid) printf 'Invalid input. Exiting menu.' ;;
        categories_back) printf 'All categories' ;;
        all_categories_title) printf 'All categories' ;;
        all_categories_prompt) printf 'Choose category (0 = back): ' ;;
        all_categories_back) printf 'Back to main menu' ;;
        category_prompt) printf 'Choose alias number (0 = back): ' ;;
        category_empty) printf '(no loaded aliases)' ;;
        category_back) printf 'Back to category menu' ;;
        table_col_no) printf 'no)' ;;
        table_col_alias) printf 'alias' ;;
        table_col_short) printf 'short description' ;;
        alias_invalid) printf 'Invalid input. Exiting menu.' ;;
        alias_detail_title) printf 'Alias details' ;;
        alias_detail_desc) printf 'Description' ;;
        alias_detail_cmd) printf 'Command' ;;
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
  local line=""
  local value=""

  line="$(builtin alias -- "${name}" 2>/dev/null)" || return 1
  value="${line#*=}"
  value="${value#\'}"
  value="${value%\'}"
  printf '%s' "${value}"
}

_alias_short_description_for_name() {
  local name="$1"
  local cmd="$2"
  local from_docs=""

  from_docs="$(_alias_help_get short "${name}")"
  if [ -n "${from_docs}" ]; then
    printf '%s' "${from_docs}"
    return 0
  fi

  case "${name}" in
    log) printf 'Journal: letzte X Zeilen (Standard 50).' ;;
    logs) printf 'Journal: Service-Logs der letzten X Zeilen.' ;;
    log_min) printf 'Journal seit X Minuten (Standard 10).' ;;
    log_hour) printf 'Journal seit X Stunden (Standard 1).' ;;
    log_clean) printf 'Journal aufbewahren/bereinigen (Tage/Groesse).' ;;
    aua) printf 'APT Update/Upgrade/Autoremove in einem Lauf.' ;;
    _self_update) printf 'Repository aktualisieren und Aliase neu laden.' ;;
    _self_setup) printf 'Interaktives Kategorie-Setup starten.' ;;
    _self_reload) printf 'Alias-Module in aktueller Shell neu laden.' ;;
    _self_edit) printf 'Alias-Datei bearbeiten und ~/.bashrc neu laden.' ;;
    _self_test_reload) printf 'Reload-Konsistenztest fuer Alias-Kategorien.' ;;
    *)
      printf '%s' "${cmd}"
      ;;
  esac
}

_alias_description_for_name() {
  local name="$1"
  local cmd="$2"
  local locale="${BASH_ALIAS_LOCALE:-de}"
  local from_docs=""

  from_docs="$(_alias_help_get desc "${name}")"
  if [ -n "${from_docs}" ]; then
    printf '%s' "${from_docs}"
    return 0
  fi

  case "${locale}" in
    de*)
      case "${name}" in
        ls) printf 'Listet Dateien im aktuellen Verzeichnis farbig auf.' ;;
        la) printf 'Listet alle Dateien inkl. versteckter Dateien im langen, menschenlesbaren Format.' ;;
        ll) printf 'Listet alle Dateien inkl. versteckter Dateien im langen, menschenlesbaren Format.' ;;
        grep) printf 'Sucht Textmuster farbig hervorgehoben.' ;;
        rm) printf 'Loescht interaktiv mit Rueckfrage.' ;;
        ..) printf 'Wechselt ein Verzeichnis nach oben.' ;;
        ...) printf 'Wechselt zwei Verzeichnisse nach oben.' ;;
        ....) printf 'Wechselt drei Verzeichnisse nach oben.' ;;
        .....) printf 'Wechselt vier Verzeichnisse nach oben.' ;;
        .2) printf 'Wechselt zwei Verzeichnisse nach oben.' ;;
        .3) printf 'Wechselt drei Verzeichnisse nach oben.' ;;
        .4) printf 'Wechselt vier Verzeichnisse nach oben.' ;;
        .5) printf 'Wechselt fuenf Verzeichnisse nach oben.' ;;
        '~') printf 'Wechselt ins Home-Verzeichnis.' ;;
        -) printf 'Wechselt ins vorherige Verzeichnis.' ;;
        cdl) printf 'Zeigt den Verzeichnis-Stack mit Indizes.' ;;
        p) printf 'Legt Verzeichnisse per pushd auf den Stack.' ;;
        o) printf 'Nimmt das oberste Verzeichnis per popd vom Stack.' ;;
        +1|+2|+3|+4|-1|-2|-3|-4) printf 'Springt zu einem Eintrag im Verzeichnis-Stack.' ;;
        h) printf 'Zeigt die Shell-History.' ;;
        dfh) printf 'Zeigt Dateisystem-Auslastung in menschenlesbarer Form.' ;;
        duh) printf 'Zeigt Speicherverbrauch pro Unterordner bis Tiefe 1.' ;;
        freeh) printf 'Zeigt RAM- und Swap-Auslastung in menschenlesbarer Form.' ;;
        psg) printf 'Sucht Prozesse per grep in der Prozessliste.' ;;
        psmem) printf 'Zeigt Top-Prozesse nach RAM-Verbrauch.' ;;
        pscpu) printf 'Zeigt Top-Prozesse nach CPU-Verbrauch.' ;;
        g) printf 'Kurzform fuer git.' ;;
        gs) printf 'Zeigt den Git-Status kurz inkl. Branch-Info.' ;;
        ga) printf 'Fuegt Dateien zur Git-Staging-Area hinzu.' ;;
        gaa) printf 'Fuegt alle Aenderungen zur Git-Staging-Area hinzu.' ;;
        gb) printf 'Zeigt lokale Git-Branches.' ;;
        gba) printf 'Zeigt lokale und Remote-Branches.' ;;
        gbd) printf 'Loescht einen lokalen Branch.' ;;
        gco) printf 'Wechselt auf einen Branch oder Commit.' ;;
        gcb) printf 'Erstellt einen neuen Branch und wechselt darauf.' ;;
        gc) printf 'Erstellt einen neuen Commit (Editor).' ;;
        gcm) printf 'Erstellt einen Commit mit direkter Nachricht.' ;;
        gca) printf 'Aendert den letzten Commit (amend).' ;;
        gcan) printf 'Aendert den letzten Commit ohne neue Nachricht.' ;;
        gd) printf 'Zeigt nicht gestagte Aenderungen.' ;;
        gds) printf 'Zeigt gestagte Aenderungen.' ;;
        gl) printf 'Zeigt kompakten Git-Graph-Log.' ;;
        gf) printf 'Holt alle Remotes und bereinigt veraltete Referenzen.' ;;
        gpl) printf 'Fuehrt git pull nur als Fast-Forward aus.' ;;
        gp) printf 'Fuehrt git push auf das konfigurierte Ziel aus.' ;;
        gpf) printf 'Fuehrt git push mit --force-with-lease aus (sicherer Force-Push).' ;;
        gr) printf 'Setzt Aenderungen im Working Tree auf HEAD zurueck.' ;;
        grs) printf 'Entfernt Dateien aus der Staging-Area.' ;;
        gst) printf 'Speichert den aktuellen Arbeitsstand in einem Stash.' ;;
        gstp) printf 'Spielt den letzten Git-Stash wieder ein.' ;;
        ports) printf 'Zeigt offene Ports und zugehoerige Prozesse.' ;;
        myip) printf 'Zeigt lokale IP-Adressen kompakt an.' ;;
        pingg) printf 'Testet Netzwerkverbindung zu google.com.' ;;
        log) printf 'Zeigt die letzten Journal-Logs (Standard 50 Zeilen, root-Funktion).' ;;
        logs) printf 'Zeigt Journal-Logs fuer einen Dienst mit optionaler Zeilenanzahl (root-Funktion).' ;;
        log_min) printf 'Zeigt Journal-Logs der letzten X Minuten (Standard 10, root-Funktion).' ;;
        log_hour) printf 'Zeigt Journal-Logs der letzten X Stunden (Standard 1, root-Funktion).' ;;
        log_clean) printf 'Bereinigt Journal-Logs nach Aufbewahrungszeit/Groesse (root-Funktion).' ;;
        agi) printf 'Installiert ein Paket via apt install (root).' ;;
        agr) printf 'Entfernt ein Paket via apt remove (root).' ;;
        acs) printf 'Sucht Pakete via apt search.' ;;
        agu) printf 'Aktualisiert Paketlisten via apt update (root).' ;;
        agg) printf 'Fuehrt Paket-Upgrade via apt upgrade aus (root).' ;;
        aga) printf 'Entfernt unnoetige Pakete via apt autoremove (root).' ;;
        agl) printf 'Zeigt alle upgradefaehigen Pakete.' ;;
        aua) printf 'Fuehrt apt update, upgrade und autoremove als Gesamt-Update aus (root).' ;;
        my) printf 'Startet die MySQL-CLI.' ;;
        mya) printf 'Startet mysqladmin fuer Admin-Operationen.' ;;
        myping) printf 'Prueft, ob der MySQL-Server antwortet.' ;;
        _self_update) printf 'Aktualisiert dieses Alias-Repository per git pull und laedt neu.' ;;
        _self_setup) printf 'Startet den interaktiven Kategorie-Setup-Assistenten.' ;;
        _self_reload) printf 'Laedt die Alias-Module in der aktuellen Shell neu (Repo-Reload).' ;;
        _self_edit) printf 'Oeffnet ~/.bash_aliases zum Bearbeiten und laedt neu.' ;;
        _self_test_reload) printf 'Prueft automatisiert, ob Alias-Kategorien nach Reload konsistent bleiben.' ;;
        *) printf "$(_alias_text desc_fallback)" "${cmd}" ;;
      esac
      ;;
    *)
      printf "$(_alias_text desc_fallback)" "${cmd}"
      ;;
  esac
}

_alias_detail_command_for_name() {
  local name="$1"
  local cmd="$2"
  local from_docs=""

  from_docs="$(_alias_help_get cmd "${name}")"
  if [ -n "${from_docs}" ]; then
    printf '%s' "${from_docs}"
    return 0
  fi

  case "${name}" in
    log) printf 'journalctl -n <X> --no-pager  (Standard: X=50)' ;;
    logs) printf 'journalctl -u <service> -n <X> --no-pager  (Standard: X=50)' ;;
    log_min) printf 'journalctl --since \"<X> minutes ago\" --no-pager  (Standard: X=10)' ;;
    log_hour) printf 'journalctl --since \"<X> hours ago\" --no-pager  (Standard: X=1)' ;;
    log_clean) printf 'journalctl --vacuum-time=<tage>d --vacuum-size=<groesse>  (Standard: 2d, 100M)' ;;
    aua) printf 'apt update && apt upgrade [-y] && apt autoremove [-y]' ;;
    _self_update) printf 'git pull --ff-only && alias_repo_reload  (Standardmodus)' ;;
    _self_reload) printf 'alias_repo_reload  (Alias-Loader in aktueller Shell neu laden)' ;;
    _self_setup) printf 'bash \"$BASH_ALIAS_REPO_DIR/scripts/alias_category_setup.sh\"' ;;
    _self_test_reload) printf 'bash \"$BASH_ALIAS_REPO_DIR/scripts/test_reload_category_mapping.sh\"' ;;
    _self_edit) printf 'nano ~/.bash_aliases && source ~/.bashrc' ;;
    *) printf '%s' "${cmd}" ;;
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
    if [ "${category}" = "${lowered}" ]; then
      printf '%s' "${category}"
      return 0
    fi
  done

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
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
  echo "$(_alias_text categories_title)" >&2
  printf ' %2d) %-12s\n' 0 "$(_alias_text categories_back)" >&2

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
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
  local name=""

  while IFS= read -r name; do
    [ -z "${name}" ] && continue
    if [ "${BASH_ALIAS_ALIAS_CATEGORY[${name}]:-}" = "${category}" ]; then
      printf '%s\n' "${name}"
    fi
  done < <(_alias_sorted_names)
}

_alias_setup_special_number() {
  if [ "${#BASH_ALIAS_CATEGORY_ORDER[@]}" -le 99 ]; then
    printf '99'
  else
    printf '999'
  fi
}

_alias_category_number_for_name() {
  local wanted="$1"
  local category=""
  local number=1
  local reserved=0

  reserved="$(_alias_setup_special_number)"

  if [ "${wanted}" = "_setup" ]; then
    printf '%s' "${reserved}"
    return 0
  fi

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    [ "${category}" = "_setup" ] && continue
    if [ "${number}" -eq "${reserved}" ]; then
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
  local reserved=0

  reserved="$(_alias_setup_special_number)"
  if [ "${wanted}" -eq "${reserved}" ]; then
    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      if [ "${category}" = "_setup" ]; then
        printf '%s' "${category}"
        return 0
      fi
    done
    return 1
  fi

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    [ "${category}" = "_setup" ] && continue
    if [ "${number}" -eq "${reserved}" ]; then
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

  raw_cmd="$(_alias_value_for_name "${name}")"
  desc="$(_alias_description_for_name "${name}" "${raw_cmd}")"
  cmd="$(_alias_detail_command_for_name "${name}" "${raw_cmd}")"

  echo ""
  echo "=== $(_alias_text alias_detail_title): ${name} ==="
  echo "$(_alias_text alias_detail_desc): ${desc}"
  echo "$(_alias_text alias_detail_cmd): ${cmd}"
  return 0
}

_alias_menu_category() {
  local category="$1"
  local number_re='^[0-9]+$'
  local choice=""
  local idx=1
  local name=""
  local -a names=()

  while true; do
    names=()
    while IFS= read -r name; do
      [ -z "${name}" ] && continue
      names+=("${name}")
    done < <(_alias_names_for_category "${category}")

    echo ""
    echo "=== ${category} ==="
    printf ' %2d) %s\n' 0 "$(_alias_text category_back)"
    printf ' %3s | %-18s | %s\n' "$(_alias_text table_col_no)" "$(_alias_text table_col_alias)" "$(_alias_text table_col_short)"

    if [ "${#names[@]}" -eq 0 ]; then
      echo "$(_alias_text category_empty)"
    else
      idx=1
      for name in "${names[@]}"; do
        printf ' %3d) | %-18s | %s\n' "${idx}" "${name}" "$(_alias_short_description_for_name "${name}" "$(_alias_value_for_name "${name}")")"
        idx=$((idx + 1))
      done
    fi

    read -r -p "$(_alias_text category_prompt)" choice
    if ! [[ "${choice}" =~ ${number_re} ]]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    if [ "${choice}" -eq 0 ]; then
      return 0
    fi

    if [ "${choice}" -lt 1 ] || [ "${choice}" -gt "${#names[@]}" ]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    _alias_show_alias_details "${names[$((choice - 1))]}" || return 1
  done
}

_alias_show_all_categories() {
  local category=""
  local name=""
  local found=0
  local idx=1

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    echo ""
    echo "=== ${category} ==="
    printf ' %3s | %-18s | %s\n' "$(_alias_text table_col_no)" "$(_alias_text table_col_alias)" "$(_alias_text table_col_short)"
    found=0
    idx=1
    while IFS= read -r name; do
      [ -z "${name}" ] && continue
      printf ' %3d) | %-18s | %s\n' "${idx}" "${name}" "$(_alias_short_description_for_name "${name}" "$(_alias_value_for_name "${name}")")"
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
    echo "=== $(_alias_text all_categories_title) ==="
    printf ' %2d) %s\n' 0 "$(_alias_text all_categories_back)"

    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      number="$(_alias_category_number_for_name "${category}")" || continue
      printf ' %3d) %s\n' "${number}" "${category}"
    done

    read -r -p "$(_alias_text all_categories_prompt)" choice
    if ! [[ "${choice}" =~ ${number_re} ]]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    if [ "${choice}" -eq 0 ]; then
      return 0
    fi

    category="$(_alias_category_name_for_number "${choice}")" || {
      echo "$(_alias_text alias_invalid)"
      return 1
    }
    _alias_menu_category "${category}" || return 1
    continue

  done
}

_alias_pick_category_interactive() {
  local choice=""
  local number_re='^[0-9]+$'
  local category=""

  while true; do
    _alias_print_category_list
    read -r -p "$(_alias_text categories_prompt)" choice
    [ -z "${choice}" ] && {
      echo "$(_alias_text categories_invalid)"
      return 1
    }

    if [[ "${choice}" =~ ${number_re} ]]; then
      if [ "${choice}" -eq 0 ]; then
        _alias_menu_all_categories || return 1
        continue
      fi

      category="$(_alias_category_name_for_number "${choice}")" || {
        echo "$(_alias_text categories_invalid)"
        return 1
      }
      _alias_menu_category "${category}" || return 1
      continue
    fi
    category="$(_alias_resolve_category_input "${choice}")" || {
      echo "$(_alias_text categories_invalid)"
      return 1
    }
    _alias_menu_category "${category}" || return 1
  done
}

a() {
  local category=""

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
    return $?
  fi

  if [ "${category}" = "all" ]; then
    _alias_show_all_categories
    return 0
  fi

  _alias_menu_category "${category}"
}

_alias_category_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local words="all"
  local category=""

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
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
