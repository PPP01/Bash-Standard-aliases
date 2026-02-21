show_aliases_functions() {
  echo ""
  echo "==== Verfuegbare Aliase ===="
  alias
}

_alias_sorted_names() {
  alias | sed -E "s/^alias[[:space:]]+--[[:space:]]+([^=]+)=.*/\1/; t; s/^alias[[:space:]]+([^=]+)=.*/\1/" | LC_ALL=C sort -u
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
  local first_word="${cmd%%[[:space:]]*}"

  case "${name}" in
    psg) printf 'Prozesse per Suchbegriff filtern.' ;;
    psmem) printf 'Top-20 Prozesse nach RAM-Verbrauch.' ;;
    pscpu) printf 'Top-20 Prozesse nach CPU-Verbrauch.' ;;
    log) printf 'journalctl: letzte 50 Zeilen (Standard).' ;;
    logs) printf 'journalctl: Service-Logs, Standard 50 Zeilen.' ;;
    log_min) printf 'journalctl: seit X Minuten (Standard 10).' ;;
    log_hour) printf 'journalctl: seit X Stunden (Standard 1).' ;;
    log_clean) printf 'journalctl bereinigen (Standard 2d / 100M).' ;;
    aua) printf 'APT-Update mit Upgrade + Autoremove (optional -y).' ;;
    _self_update) printf 'Repository aktualisieren und Aliase neu laden.' ;;
    _self_setup) printf 'Interaktives Kategorie-Setup starten.' ;;
    _self_reload) printf 'Alias-Module in aktueller Shell neu laden.' ;;
    _self_edit) printf 'Alias-Datei bearbeiten und ~/.bashrc neu laden.' ;;
    _self_test_reload) printf 'Reload-Konsistenztest fuer Alias-Kategorien.' ;;
    *)
      if [[ "${cmd}" == *"|"* || "${cmd}" == *"&&"* || "${cmd}" == *";"* ]] || declare -F "${first_word}" >/dev/null 2>&1; then
        printf "$(_alias_text short_internal)" "${cmd}"
      else
        printf '%s' "${cmd}"
      fi
      ;;
  esac
}

_alias_description_for_name() {
  local name="$1"
  local cmd="$2"
  local locale="${BASH_ALIAS_LOCALE:-de}"

  case "${locale}" in
    de*)
      case "${name}" in
        ls) printf 'Listet Dateien im aktuellen Verzeichnis farbig auf.' ;;
        la|ll) printf 'Zeigt Dateien inkl. versteckter Dateien im langen Format.' ;;
        grep) printf 'Sucht Textmuster farbig hervorgehoben.' ;;
        rm) printf 'Loescht interaktiv mit Rueckfrage.' ;;
        ..|...|....|.....|.2|.3|.4|.5) printf 'Wechselt schnell in uebergeordnete Verzeichnisse.' ;;
        '~') printf 'Wechselt ins Home-Verzeichnis.' ;;
        -|+1|+2|+3|+4|-1|-2|-3|-4|p|o|cdl) printf 'Hilft beim Navigieren im Verzeichnis-Stack (pushd/popd/dirs).' ;;
        h) printf 'Zeigt die Shell-History.' ;;
        dfh) printf 'Zeigt Dateisystem-Auslastung in menschenlesbarer Form.' ;;
        duh) printf 'Zeigt Speicherverbrauch pro Unterordner bis Tiefe 1.' ;;
        freeh) printf 'Zeigt RAM- und Swap-Auslastung in menschenlesbarer Form.' ;;
        psg) printf 'Sucht Prozesse per grep in der Prozessliste.' ;;
        psmem) printf 'Zeigt Top-Prozesse nach RAM-Verbrauch.' ;;
        pscpu) printf 'Zeigt Top-Prozesse nach CPU-Verbrauch.' ;;
        g) printf 'Kurzform fuer git.' ;;
        gs|gst) printf 'Zeigt den Git-Status (kurz).' ;;
        ga) printf 'Fuegt Dateien zur Git-Staging-Area hinzu.' ;;
        gaa) printf 'Fuegt alle Aenderungen zur Git-Staging-Area hinzu.' ;;
        gb|gba|gbd) printf 'Arbeitet mit Git-Branches (anzeigen/alle/loeschen).' ;;
        gco|gcb) printf 'Checkout eines Branches bzw. neuen Branch erstellen.' ;;
        gc|gcm|gca|gcan) printf 'Erstellt/veraendert Git-Commits.' ;;
        gd|gds) printf 'Zeigt Git-Diffs (normal bzw. staged).' ;;
        gl) printf 'Zeigt kompakten Git-Graph-Log.' ;;
        gf) printf 'Holt alle Remotes und bereinigt veraltete Referenzen.' ;;
        gpl) printf 'Fuehrt git pull mit --ff-only aus.' ;;
        gp|gpf) printf 'Fuehrt git push aus (normal bzw. force-with-lease).' ;;
        gr|grs) printf 'Stellt Dateien aus Git wieder her (working tree/staged).' ;;
        gstp) printf 'Spielt den letzten Git-Stash wieder ein.' ;;
        ports) printf 'Zeigt offene Ports und zugehoerige Prozesse.' ;;
        myip) printf 'Zeigt lokale IP-Adressen kompakt an.' ;;
        pingg) printf 'Testet Netzwerkverbindung zu google.com.' ;;
        log|logs|log_min|log_hour|log_clean) printf 'Zeigt/bereinigt Journal-Logs (root-Funktionen).' ;;
        agi|agr|acs|agu|agg|aga|agl|aua) printf 'APT-Shortcuts fuer Paketverwaltung und Updates (root).' ;;
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
  local idx=1
  local category=""
  local state=""

  echo "" >&2
  echo "$(_alias_text categories_title)" >&2
  printf ' %2d) %-12s\n' 0 "$(_alias_text categories_back)" >&2

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    state="off"
    if [ "${BASH_ALIAS_CATEGORY_ENABLED[${category}]:-0}" -eq 1 ]; then
      state="on"
    fi
    printf ' %2d) %-12s [%s]\n' "${idx}" "${category}" "${state}" >&2
    idx=$((idx + 1))
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

_alias_show_alias_details() {
  local name="$1"
  local cmd=""
  local desc=""

  cmd="$(_alias_value_for_name "${name}")"
  desc="$(_alias_description_for_name "${name}" "${cmd}")"

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
  local idx=1
  local category=""

  while true; do
    echo ""
    echo "=== $(_alias_text all_categories_title) ==="
    printf ' %2d) %s\n' 0 "$(_alias_text all_categories_back)"

    idx=1
    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      printf ' %2d) %s\n' "${idx}" "${category}"
      idx=$((idx + 1))
    done

    read -r -p "$(_alias_text all_categories_prompt)" choice
    if ! [[ "${choice}" =~ ${number_re} ]]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    if [ "${choice}" -eq 0 ]; then
      return 0
    fi

    idx=1
    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      if [ "${idx}" -eq "${choice}" ]; then
        _alias_menu_category "${category}" || return 1
        break
      fi
      idx=$((idx + 1))
    done

    if [ "${idx}" -le "${#BASH_ALIAS_CATEGORY_ORDER[@]}" ]; then
      continue
    fi

    echo "$(_alias_text alias_invalid)"
    return 1
  done
}

_alias_pick_category_interactive() {
  local choice=""
  local number_re='^[0-9]+$'
  local idx=1
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

      idx=1
      for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
        if [ "${idx}" -eq "${choice}" ]; then
          _alias_menu_category "${category}" || return 1
          break
        fi
        idx=$((idx + 1))
      done

      if [ "${idx}" -le "${#BASH_ALIAS_CATEGORY_ORDER[@]}" ]; then
        continue
      fi

      echo "$(_alias_text categories_invalid)"
      return 1
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
