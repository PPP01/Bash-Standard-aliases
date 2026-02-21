show_aliases_functions() {
  echo ""
  echo "==== Verfuegbare Aliase ===="
  alias
}

_alias_sorted_names() {
  alias | sed -E "s/^alias[[:space:]]+--[[:space:]]+([^=]+)=.*/\1/; t; s/^alias[[:space:]]+([^=]+)=.*/\1/" | LC_ALL=C sort -u
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
  echo "Alias-Kategorien:" >&2
  printf ' %2d) %-12s\n' 0 "all" >&2

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    state="off"
    if [ "${BASH_ALIAS_CATEGORY_ENABLED[${category}]:-0}" -eq 1 ]; then
      state="on"
    fi
    printf ' %2d) %-12s [%s]\n' "${idx}" "${category}" "${state}" >&2
    idx=$((idx + 1))
  done
}

_alias_show_one_category() {
  local category="$1"
  local name=""
  local found=0

  echo ""
  echo "=== ${category} ==="

  while IFS= read -r name; do
    [ -z "${name}" ] && continue
    if [ "${BASH_ALIAS_ALIAS_CATEGORY[${name}]:-}" = "${category}" ]; then
      builtin alias -- "${name}"
      found=1
    fi
  done < <(_alias_sorted_names)

  if [ "${found}" -eq 0 ]; then
    echo "(keine geladenen Aliase)"
  fi
}

_alias_show_all_categories() {
  local category=""

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_show_one_category "${category}"
  done
}

_alias_pick_category_interactive() {
  local choice=""
  local number_re='^[0-9]+$'
  local idx=1
  local category=""

  _alias_print_category_list
  read -r -p "Kategorie (Name oder Nummer): " choice

  [ -z "${choice}" ] && return 1

  if [[ "${choice}" =~ ${number_re} ]]; then
    if [ "${choice}" -eq 0 ]; then
      printf 'all'
      return 0
    fi

    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      if [ "${idx}" -eq "${choice}" ]; then
        printf '%s' "${category}"
        return 0
      fi
      idx=$((idx + 1))
    done

    return 1
  fi

  _alias_resolve_category_input "${choice}"
}

a() {
  local category=""

  if [ -n "${1:-}" ]; then
    category="$(_alias_resolve_category_input "$1")" || {
      echo "Unbekannte Kategorie: $1"
      echo "Nutze 'a' fuer Auswahl oder 'a all'."
      return 1
    }
  else
    category="$(_alias_pick_category_interactive)" || return 1
  fi

  if [ "${category}" = "all" ]; then
    _alias_show_all_categories
  else
    _alias_show_one_category "${category}"
  fi
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
