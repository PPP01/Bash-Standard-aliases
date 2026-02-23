_alias_help_impl_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "${_alias_help_impl_dir}/alias_i18n.sh"

show_aliases_functions() {
  echo ""
  echo "$(_alias_i18n_text "help.available_aliases_header")"
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
declare -gA BASH_ALIAS_MENU_SHORT_DESC=()
declare -g BASH_ALIAS_MENU_CACHE_READY=0
declare -g BASH_ALIAS_MENU_DISK_CACHE_TRIED=0
declare -g BASH_ALIAS_MENU_LAST_RENDER_LINES=0
declare -g BASH_ALIAS_MENU_RENDER_ACTIVE=0
declare -g BASH_ALIAS_MENU_CURSOR_HIDDEN=0

: "${BASH_ALIAS_HELP_COLOR_DETAIL_LABEL:=\033[0;32m}"
: "${BASH_ALIAS_HELP_COLOR_MENU_TITLE:=\033[0;32m}"
: "${BASH_ALIAS_HELP_COLOR_MENU_META:=\033[0;36m}"
: "${BASH_ALIAS_HELP_COLOR_MENU_HEADER:=\033[1;36m}"
: "${BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP:=\033[38;5;247m}"
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
            case "${seq}" in
              A)
                echo ""
                REPLY="up"
                return 0
                ;;
              B)
                echo ""
                REPLY="down"
                return 0
                ;;
              C)
                echo ""
                REPLY="right"
                return 0
                ;;
              D)
                echo ""
                REPLY="left"
                return 0
                ;;
            esac
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

_alias_menu_cache_reset() {
  BASH_ALIAS_MENU_SHORT_DESC=()
  BASH_ALIAS_MENU_CACHE_READY=0
  BASH_ALIAS_MENU_DISK_CACHE_TRIED=0
}

_alias_menu_cache_enabled() {
  case "${BASH_ALIAS_MENU_DISK_CACHE:-1}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_menu_inplace_redraw_enabled() {
  case "${BASH_ALIAS_MENU_INPLACE_REDRAW:-1}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_menu_hide_cursor_enabled() {
  case "${BASH_ALIAS_MENU_HIDE_CURSOR:-1}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_menu_clear_enabled() {
  case "${BASH_ALIAS_MENU_CLEAR_SCREEN:-0}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_menu_redraw_reset() {
  _alias_menu_render_end
  BASH_ALIAS_MENU_LAST_RENDER_LINES=0
}

_alias_menu_redraw_set_lines() {
  local lines="${1:-0}"
  BASH_ALIAS_MENU_LAST_RENDER_LINES="${lines}"
}

_alias_menu_inplace_refresh_begin() {
  _alias_menu_inplace_redraw_enabled || return 1
  [ -t 1 ] || return 1
  if [ "${BASH_ALIAS_MENU_RENDER_ACTIVE}" -eq 0 ]; then
    if command -v tput >/dev/null 2>&1; then
      tput sc 2>/dev/null || printf '\0337'
      if _alias_menu_hide_cursor_enabled; then
        tput civis 2>/dev/null || printf '\033[?25l'
        BASH_ALIAS_MENU_CURSOR_HIDDEN=1
      fi
    else
      printf '\0337'
      if _alias_menu_hide_cursor_enabled; then
        printf '\033[?25l'
        BASH_ALIAS_MENU_CURSOR_HIDDEN=1
      fi
    fi
    BASH_ALIAS_MENU_RENDER_ACTIVE=1
  fi
  if command -v tput >/dev/null 2>&1; then
    tput rc 2>/dev/null || printf '\0338'
  else
    printf '\0338'
  fi
  printf '\033[J'
  return 0
}

_alias_menu_render_end() {
  if [ "${BASH_ALIAS_MENU_CURSOR_HIDDEN}" -eq 1 ]; then
    if command -v tput >/dev/null 2>&1; then
      tput cnorm 2>/dev/null || printf '\033[?25h'
    else
      printf '\033[?25h'
    fi
    BASH_ALIAS_MENU_CURSOR_HIDDEN=0
  fi
  BASH_ALIAS_MENU_RENDER_ACTIVE=0
}

_alias_menu_clear_screen() {
  _alias_menu_clear_enabled || return 0
  [ -t 1 ] || return 0

  if command -v tput >/dev/null 2>&1; then
    tput clear 2>/dev/null || printf '\033[H\033[2J'
    return 0
  fi

  printf '\033[H\033[2J'
}

_alias_menu_refresh_begin() {
  _alias_menu_inplace_refresh_begin && return 0
  _alias_menu_clear_screen
}

_alias_menu_cache_dir() {
  printf '%s/bash-standard-aliases' "${XDG_CACHE_HOME:-${HOME}/.cache}"
}

_alias_menu_cache_repo_dir() {
  if [ -n "${BASH_ALIAS_REPO_DIR:-}" ]; then
    printf '%s' "${BASH_ALIAS_REPO_DIR}"
    return 0
  fi
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

_alias_menu_cache_repo_version() {
  local repo_dir="$1"
  local rev=""
  local cksum_line=""

  if command -v git >/dev/null 2>&1 && [ -d "${repo_dir}/.git" ]; then
    rev="$(git -C "${repo_dir}" rev-parse --verify --short=12 HEAD 2>/dev/null || true)"
    if [ -n "${rev}" ]; then
      if ! git -C "${repo_dir}" diff --quiet --no-ext-diff --ignore-submodules -- 2>/dev/null || ! git -C "${repo_dir}" diff --cached --quiet --no-ext-diff --ignore-submodules -- 2>/dev/null; then
        rev="${rev}-dirty"
      fi
      printf '%s' "${rev}"
      return 0
    fi
  fi

  if [ -f "${repo_dir}/bash_alias_std.sh" ]; then
    cksum_line="$(cksum < "${repo_dir}/bash_alias_std.sh" 2>/dev/null || true)"
    cksum_line="${cksum_line%% *}"
    if [ -n "${cksum_line}" ]; then
      printf 'cksum-%s' "${cksum_line}"
      return 0
    fi
  fi

  printf 'unknown'
}

_alias_menu_cache_user_salt() {
  local file=""
  local cksum_line=""

  for file in "${HOME}/.bash_aliases_specific" "${HOME}/.bash_aliases_specific.md"; do
    [ -f "${file}" ] || continue
    cksum_line="$(cksum < "${file}" 2>/dev/null || true)"
    cksum_line="${cksum_line%% *}"
    printf '%s:%s;' "${file}" "${cksum_line}"
  done
}

_alias_menu_cache_key() {
  local repo_dir=""
  local repo_version=""
  local locale="${BASH_ALIAS_LOCALE:-de}"
  local user_salt=""
  local key_line=""
  local key=""

  repo_dir="$(_alias_menu_cache_repo_dir)" || return 1
  repo_version="$(_alias_menu_cache_repo_version "${repo_dir}")"
  user_salt="$(_alias_menu_cache_user_salt)"
  key_line="$(printf '%s|%s|%s' "${repo_version}" "${locale}" "${user_salt}" | cksum 2>/dev/null || true)"
  key="${key_line%% *}"
  [ -n "${key}" ] || return 1
  printf '%s' "${key}"
}

_alias_menu_cache_file() {
  local cache_dir=""
  local cache_key=""

  cache_dir="$(_alias_menu_cache_dir)"
  cache_key="$(_alias_menu_cache_key)" || return 1
  printf '%s/menu-cache-%s.sh' "${cache_dir}" "${cache_key}"
}

_alias_menu_cache_emit_global_declare() {
  local var_name="$1"
  local decl=""

  decl="$(declare -p "${var_name}" 2>/dev/null || true)"
  [ -n "${decl}" ] || return 1
  decl="${decl/declare -A /declare -gA }"
  decl="${decl/declare -a /declare -ga }"
  decl="${decl/declare -- /declare -g }"
  printf '%s\n' "${decl}"
}

_alias_menu_cache_try_load() {
  local cache_file=""

  _alias_menu_cache_enabled || return 1
  [ "${BASH_ALIAS_MENU_DISK_CACHE_TRIED}" -eq 0 ] || return 1
  BASH_ALIAS_MENU_DISK_CACHE_TRIED=1

  cache_file="$(_alias_menu_cache_file)" || return 1
  [ -f "${cache_file}" ] || return 1

  # shellcheck disable=SC1090
  source "${cache_file}" || return 1
  if [ "${BASH_ALIAS_RUNTIME_CACHE_READY}" -eq 1 ] && [ "${BASH_ALIAS_MENU_CACHE_READY}" -eq 1 ]; then
    return 0
  fi
  return 1
}

_alias_menu_cache_save() {
  local cache_dir=""
  local cache_file=""
  local tmp_file=""

  _alias_menu_cache_enabled || return 0

  cache_dir="$(_alias_menu_cache_dir)"
  cache_file="$(_alias_menu_cache_file)" || return 0
  tmp_file="${cache_file}.tmp.$$"

  mkdir -p "${cache_dir}" 2>/dev/null || return 0

  {
    printf '# shellcheck shell=bash\n'
    printf '# generated automatically by alias help cache\n'
    _alias_menu_cache_emit_global_declare "BASH_ALIAS_RUNTIME_VALUE"
    _alias_menu_cache_emit_global_declare "BASH_ALIAS_RUNTIME_SORTED_NAMES"
    _alias_menu_cache_emit_global_declare "BASH_ALIAS_RUNTIME_CATEGORY_NAMES"
    _alias_menu_cache_emit_global_declare "BASH_ALIAS_MENU_SHORT_DESC"
    printf 'declare -g BASH_ALIAS_RUNTIME_CACHE_READY=1\n'
    printf 'declare -g BASH_ALIAS_MENU_CACHE_READY=1\n'
  } > "${tmp_file}" 2>/dev/null || {
    rm -f "${tmp_file}" 2>/dev/null || true
    return 0
  }

  mv -f "${tmp_file}" "${cache_file}" 2>/dev/null || {
    rm -f "${tmp_file}" 2>/dev/null || true
    return 0
  }
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

_alias_menu_cache_build() {
  local name=""
  local raw_cmd=""

  if [ "${BASH_ALIAS_MENU_CACHE_READY}" -eq 1 ]; then
    return 0
  fi

  if _alias_menu_cache_try_load; then
    return 0
  fi

  _alias_runtime_cache_build || return 1
  _alias_help_load_data || true

  BASH_ALIAS_MENU_SHORT_DESC=()
  for name in "${BASH_ALIAS_RUNTIME_SORTED_NAMES[@]}"; do
    raw_cmd="${BASH_ALIAS_RUNTIME_VALUE[${name}]:-}"
    _alias_short_description_for_name "${name}" "${raw_cmd}"
    BASH_ALIAS_MENU_SHORT_DESC["${name}"]="${REPLY:-}"
  done

  BASH_ALIAS_MENU_CACHE_READY=1
  _alias_menu_cache_save
}

_alias_menu_short_description_for_name() {
  local name="$1"
  local raw_cmd="$2"

  if [ "${BASH_ALIAS_MENU_CACHE_READY}" -eq 1 ] && [ -n "${BASH_ALIAS_MENU_SHORT_DESC[${name}]+_}" ]; then
    REPLY="${BASH_ALIAS_MENU_SHORT_DESC[${name}]}"
    return 0
  fi

  _alias_short_description_for_name "${name}" "${raw_cmd}"
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

  case "${lang}" in
    de|'')
      printf '%s' "${base_file}"
      ;;
    *)
      # For non-default locales, skip base (German) docs if no localized variant exists.
      printf ''
      ;;
  esac
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
    [ -n "${selected_file}" ] && files+=( "${selected_file}" )
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
      if [[ "${line}" =~ ^##[[:space:]]+Alias[[:space:]]+Help ]]; then
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
  _alias_i18n_text "help.$1"
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
  local key=""

  _alias_help_get short "${name}"
  from_docs="${REPLY:-}"
  if [ -n "${from_docs}" ]; then
    REPLY="${from_docs}"
    return 0
  fi

  key="help.short.alias.${name}"
  if _alias_i18n_has_key "${key}"; then
    REPLY="$(_alias_i18n_text "${key}")"
    return 0
  fi

  REPLY="${cmd}"
}

_alias_description_for_name() {
  local name="$1"
  local cmd="$2"
  local from_docs=""
  local key=""

  _alias_help_get desc "${name}"
  from_docs="${REPLY:-}"
  if [ -n "${from_docs}" ]; then
    REPLY="${from_docs}"
    return 0
  fi

  key="help.desc.alias.${name}"
  if _alias_i18n_has_key "${key}"; then
    REPLY="$(_alias_i18n_text "${key}")"
    return 0
  fi

  REPLY="$(printf "$(_alias_text desc_fallback)" "${cmd}")"
}

_alias_detail_command_for_name() {
  local name="$1"
  local cmd="$2"
  local from_docs=""
  local key=""

  _alias_help_get cmd "${name}"
  from_docs="${REPLY:-}"
  if [ -n "${from_docs}" ]; then
    REPLY="${from_docs}"
    return 0
  fi

  key="help.cmd.alias.${name}"
  if _alias_i18n_has_key "${key}"; then
    REPLY="$(_alias_i18n_text "${key}")"
    return 0
  fi

  REPLY="${cmd}"
}

_alias_resolve_category_input() {
  local raw="$1"
  local lowered=""
  local category=""
  local display=""
  local found=""
  local count=0

  lowered="$(printf '%s' "${raw}" | tr '[:upper:]' '[:lower:]')"

  [ "${lowered}" = "all" ] && {
    printf 'all'
    return 0
  }

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    display="$(_alias_category_display_name "${category}")"
    if [ "${category}" = "${lowered}" ] || [ "${display}" = "${lowered}" ]; then
      printf '%s' "${category}"
      return 0
    fi
  done

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    display="$(_alias_category_display_name "${category}")"
    case "${category}:${display}" in
      "${lowered}"*:*|*:"${lowered}"*)
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

_alias_category_display_name() {
  local category="$1"

  case "${category}" in
    _setup) printf 'setup' ;;
    _own) printf 'own' ;;
    *) printf '%s' "${category}" ;;
  esac
}

_alias_category_color_for_menu() {
  local category="$1"
  local scheme="${BASH_ALIAS_COLOR_SCHEME:-dark}"
  if _alias_is_setup_category "${category}"; then
    # Rueckwaertskompatibel: fruehere bright-Defaults nutzten schwarz (0;30),
    # was auf hellen Hintergruenden wie Standardtext wirkte.
    if [ "${scheme}" = "bright" ] || [ "${scheme}" = "light" ]; then
      if [ "${BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP}" = '\033[0;30m' ]; then
        printf '\033[0;90m'
        return 0
      fi
    elif [ "${scheme}" = "dark" ]; then
      # Rueckwaertskompatibel: alte dark-Werte koennen wie Standardtext wirken.
      if [ "${BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP}" = '\033[0;37m' ] || [ "${BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP}" = '\033[0;90m' ]; then
        printf '\033[38;5;247m'
        return 0
      fi
    fi
    printf '%s' "${BASH_ALIAS_HELP_COLOR_MENU_CATEGORY_SETUP}"
    return 0
  fi
  # Kategorien in Auswahllisten in Terminal-Standardfarbe halten.
  printf '%s' "${BASH_ALIAS_HELP_COLOR_RESET}"
}

_alias_category_header_color_for_menu() {
  local category="$1"
  local scheme="${BASH_ALIAS_COLOR_SCHEME:-dark}"
  # Kategorie-Ueberschriften: immer fett, mit Gruenton je nach Schema.
  # bright: dunkleres Gruen, dark: klassisches Gruen.
  case "${scheme}" in
    bright|light)
      printf '\033[1;38;5;22m'
      ;;
    *)
      printf '\033[1;32m'
      ;;
  esac
}

_alias_menu_highlight_line_color() {
  local scheme="${BASH_ALIAS_COLOR_SCHEME:-dark}"
  case "${scheme}" in
    bright|light)
      # Bright terminals: dark text on light background.
      printf '\033[1;30;47m'
      ;;
    *)
      # Dark terminals: bright text on blue background.
      printf '\033[1;97;44m'
      ;;
  esac
}

_alias_menu_highlight_marker_color() {
  local scheme="${BASH_ALIAS_COLOR_SCHEME:-dark}"
  case "${scheme}" in
    bright|light)
      printf '\033[1;34m'
      ;;
    *)
      printf '\033[1;96m'
      ;;
  esac
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
  local category="$1"

  case "${category}" in
    _own) printf '98' ;;
    setup|_setup) _alias_setup_reserved_number ;;
    *) return 1 ;;
  esac
}

_alias_is_setup_category() {
  case "$1" in
    setup|_setup) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_setup_reserved_number() {
  local category=""
  local visible_count=0

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    [ "${category}" = "_own" ] && continue
    _alias_is_setup_category "${category}" && continue
    _alias_category_is_visible "${category}" || continue
    visible_count=$((visible_count + 1))
  done

  if [ "${visible_count}" -ge 99 ]; then
    printf '999'
  else
    printf '99'
  fi
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

  reserved_setup="$(_alias_setup_reserved_number)"

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    [ "${category}" = "_own" ] && continue
    _alias_is_setup_category "${category}" && continue
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

  reserved_setup="$(_alias_setup_reserved_number)"

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
      if _alias_is_setup_category "${category}"; then
        _alias_category_is_visible "${category}" || return 1
        printf '%s' "${category}"
        return 0
      fi
    done
    return 1
  fi

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    [ "${category}" = "_own" ] && continue
    _alias_is_setup_category "${category}" && continue
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
  printf '%b=== %s: %s ===%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_TITLE}" "$(_alias_text alias_detail_title)" "${name}" "${BASH_ALIAS_HELP_COLOR_RESET}"
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

  _alias_menu_refresh_begin
  _alias_show_alias_details "${name}" || return 1
  _alias_menu_redraw_set_lines 5
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

_alias_menu_category_title_line() {
  local category="$1"
  local display=""
  local header_line=""
  local title_line=""
  local pad_len=0
  local pad=""

  display="$(_alias_category_display_name "${category}")"
  printf -v header_line '   %4s | %-18s | %s' "$(_alias_text table_col_no)" "$(_alias_text table_col_alias)" "$(_alias_text table_col_short)"
  title_line="=== ${display} ==="
  pad_len=$((${#header_line} - ${#title_line}))
  if [ "${pad_len}" -gt 0 ]; then
    printf -v pad '%*s' "${pad_len}" ''
    pad="${pad// /=}"
    title_line+="${pad}"
  fi

  printf '%s' "${title_line}"
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
  local selected=1
  local selected_number=0
  local selected_name=""
  local marker=""
  local line_color=""
  local total=0
  local render_lines=0
  local -a names=()

  while true; do
    _alias_menu_refresh_begin
    names=()
    while IFS= read -r name; do
      [ -z "${name}" ] && continue
      names+=("${name}")
    done < <(_alias_names_for_category "${category}")

    echo ""
    printf '%b%s%b\n' "$(_alias_category_header_color_for_menu "${category}")" "$(_alias_menu_category_title_line "${category}")" "${BASH_ALIAS_HELP_COLOR_RESET}"
    total="${#names[@]}"
    if [ "${show_back_entry}" -eq 1 ]; then
      total=$((total + 1))
    fi
    if [ "${total}" -le 0 ]; then
      selected=0
    elif [ "${selected}" -lt 1 ] || [ "${selected}" -gt "${total}" ]; then
      selected=1
    fi
    if [ "${show_back_entry}" -eq 1 ]; then
      marker=" "
      line_color=""
      if [ "${selected}" -eq 1 ]; then
        marker=">"
        line_color="$(_alias_menu_highlight_line_color)"
      fi
      printf ' %b%s%b %b %3d) %s%b\n' \
        "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
        "${line_color}" 0 "$(_alias_text category_back)" "${BASH_ALIAS_HELP_COLOR_RESET}"
    fi
    printf '%b   %4s | %-18s | %s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_HEADER}" "$(_alias_text table_col_no)" "$(_alias_text table_col_alias)" "$(_alias_text table_col_short)" "${BASH_ALIAS_HELP_COLOR_RESET}"

    if [ "${#names[@]}" -eq 0 ]; then
      echo "$(_alias_text category_empty)"
    else
      idx=1
      for name in "${names[@]}"; do
        _alias_value_for_name "${name}" || raw_cmd=""
        raw_cmd="${REPLY:-}"
        _alias_menu_short_description_for_name "${name}" "${raw_cmd}"
        short_desc="${REPLY:-}"
        selected_number="${idx}"
        if [ "${show_back_entry}" -eq 1 ]; then
          selected_number=$((idx + 1))
        fi
        marker=" "
        line_color=""
        if [ "${selected}" -eq "${selected_number}" ]; then
          marker=">"
          line_color="$(_alias_menu_highlight_line_color)"
        fi
        printf ' %b%s%b %b %3d) | %-18s | %s%b\n' \
          "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
          "${line_color}" "${idx}" "${name}" "${short_desc}" "${BASH_ALIAS_HELP_COLOR_RESET}"
        idx=$((idx + 1))
      done
    fi
    render_lines=4
    if [ "${show_back_entry}" -eq 0 ]; then
      render_lines=3
    fi
    if [ "${#names[@]}" -eq 0 ]; then
      render_lines=$((render_lines + 1))
    else
      render_lines=$((render_lines + ${#names[@]}))
    fi
    # Prompt line is rendered by _alias_menu_read_input.
    _alias_menu_redraw_set_lines $((render_lines + 1))

    _alias_menu_read_input "$(_alias_text category_prompt)"
    choice="${REPLY:-}"
    if _alias_menu_is_quit_input "${choice}"; then
      return 130
    fi
    if _alias_menu_is_back_input "${choice}"; then
      return 0
    fi
    case "${choice}" in
      up)
        if [ "${total}" -gt 0 ]; then
          if [ "${selected}" -le 1 ]; then
            selected="${total}"
          else
            selected=$((selected - 1))
          fi
        fi
        continue
        ;;
      down)
        if [ "${total}" -gt 0 ]; then
          if [ "${selected}" -ge "${total}" ]; then
            selected=1
          else
            selected=$((selected + 1))
          fi
        fi
        continue
        ;;
      right|'')
        if [ "${total}" -le 0 ]; then
          echo "$(_alias_text alias_invalid)"
          return 1
        fi
        if [ "${show_back_entry}" -eq 1 ] && [ "${selected}" -eq 1 ]; then
          return 0
        fi
        if [ "${show_back_entry}" -eq 1 ]; then
          selected_name="${names[$((selected - 2))]}"
        else
          selected_name="${names[$((selected - 1))]}"
        fi
        _alias_menu_alias_details "${selected_name}"
        case "$?" in
          0) ;;
          130) return 130 ;;
          *) return 1 ;;
        esac
        continue
        ;;
    esac
    if ! [[ "${choice}" =~ ${number_re} ]]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    if [ "${choice}" -lt 1 ] || [ "${choice}" -gt "${#names[@]}" ]; then
      echo "$(_alias_text alias_invalid)"
      return 1
    fi

    _alias_menu_alias_details "${names[$((choice - 1))]}"
    if [ "${show_back_entry}" -eq 1 ]; then
      selected=$((choice + 1))
    else
      selected="${choice}"
    fi
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
    printf '%b%s%b\n' "$(_alias_category_header_color_for_menu "${category}")" "$(_alias_menu_category_title_line "${category}")" "${BASH_ALIAS_HELP_COLOR_RESET}"
    printf '%b   %4s | %-18s | %s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_HEADER}" "$(_alias_text table_col_no)" "$(_alias_text table_col_alias)" "$(_alias_text table_col_short)" "${BASH_ALIAS_HELP_COLOR_RESET}"
    found=0
    idx=1
    while IFS= read -r name; do
      [ -z "${name}" ] && continue
      _alias_value_for_name "${name}" || raw_cmd=""
      raw_cmd="${REPLY:-}"
      _alias_menu_short_description_for_name "${name}" "${raw_cmd}"
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
  local selected=1
  local selected_number=0
  local marker=""
  local line_color=""
  local rendered_entries=0
  local render_lines=0
  local -a menu_categories=()

  while true; do
    _alias_menu_refresh_begin
    menu_categories=()
    rendered_entries=0
    echo ""
    printf '%b=== %s ===%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_TITLE}" "$(_alias_text all_categories_title)" "${BASH_ALIAS_HELP_COLOR_RESET}"
    marker=" "
    line_color=""
    if [ "${selected}" -eq 1 ]; then
      marker=">"
      line_color="$(_alias_menu_highlight_line_color)"
    fi
    printf ' %b%s%b %b %3d) %s%b\n' \
      "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
      "${line_color}" 0 "$(_alias_text all_categories_back)" "${BASH_ALIAS_HELP_COLOR_RESET}"

    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      _alias_is_setup_category "${category}" && continue
      _alias_category_is_visible "${category}" || continue
      menu_categories+=("${category}")
      number="$(_alias_category_number_for_name "${category}")" || continue
      selected_number="${#menu_categories[@]}"
      selected_number=$((selected_number + 1))
      marker=" "
      line_color=""
      if [ "${selected}" -eq "${selected_number}" ]; then
        marker=">"
        line_color="$(_alias_menu_highlight_line_color)"
      fi
      printf ' %b%s%b %b %3d) %b%s%b%b\n' \
        "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
        "${line_color}" "${number}" "$(_alias_category_color_for_menu "${category}")" "$(_alias_category_display_name "${category}")" "${BASH_ALIAS_HELP_COLOR_RESET}" "${BASH_ALIAS_HELP_COLOR_RESET}"
      rendered_entries=$((rendered_entries + 1))
    done

    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      _alias_is_setup_category "${category}" || continue
      _alias_category_is_visible "${category}" || continue
      menu_categories+=("${category}")
      number="$(_alias_category_number_for_name "${category}")" || continue
      selected_number="${#menu_categories[@]}"
      selected_number=$((selected_number + 1))
      marker=" "
      line_color=""
      if [ "${selected}" -eq "${selected_number}" ]; then
        marker=">"
        line_color="$(_alias_menu_highlight_line_color)"
      fi
      printf ' %b%s%b %b %3d) %b%s%b%b\n' \
        "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
        "${line_color}" "${number}" "$(_alias_category_color_for_menu "${category}")" "$(_alias_category_display_name "${category}")" "${BASH_ALIAS_HELP_COLOR_RESET}" "${BASH_ALIAS_HELP_COLOR_RESET}"
      rendered_entries=$((rendered_entries + 1))
    done
    if [ "${selected}" -lt 1 ] || [ "${selected}" -gt "$((1 + ${#menu_categories[@]}))" ]; then
      selected=1
    fi
    render_lines=$((1 + 1 + 1 + rendered_entries))
    _alias_menu_redraw_set_lines $((render_lines + 1))

    _alias_menu_read_input "$(_alias_text all_categories_prompt)"
    choice="${REPLY:-}"
    if _alias_menu_is_quit_input "${choice}"; then
      return 130
    fi
    if _alias_menu_is_back_input "${choice}"; then
      return 0
    fi
    case "${choice}" in
      up)
        if [ "${#menu_categories[@]}" -gt 0 ]; then
          if [ "${selected}" -le 1 ]; then
            selected=$((1 + ${#menu_categories[@]}))
          else
            selected=$((selected - 1))
          fi
        fi
        continue
        ;;
      down)
        if [ "${#menu_categories[@]}" -gt 0 ]; then
          if [ "${selected}" -ge "$((1 + ${#menu_categories[@]}))" ]; then
            selected=1
          else
            selected=$((selected + 1))
          fi
        fi
        continue
        ;;
      right|'')
        if [ "${selected}" -eq 1 ]; then
          return 0
        fi
        category="${menu_categories[$((selected - 2))]}"
        _alias_menu_category "${category}"
        case "$?" in
          0) ;;
          130) return 130 ;;
          *) return 1 ;;
        esac
        continue
        ;;
    esac
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
  local number=""
  local marker=""
  local line_color=""
  local selected=1
  local selected_number=0
  local display=""
  local state=""
  local color=""
  local rendered_entries=0
  local render_lines=0
  local -a menu_categories=()

  while true; do
    _alias_menu_refresh_begin
    menu_categories=()
    rendered_entries=0
    echo "" >&2
    printf '%b%s%b\n' "${BASH_ALIAS_HELP_COLOR_MENU_TITLE}" "$(_alias_text categories_title)" "${BASH_ALIAS_HELP_COLOR_RESET}" >&2
    marker=" "
    line_color=""
    if [ "${selected}" -eq 1 ]; then
      marker=">"
      line_color="$(_alias_menu_highlight_line_color)"
    fi
    printf ' %b%s%b %b%3d) %-12s%b\n' \
      "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
      "${line_color}" 0 "$(_alias_text categories_back)" "${BASH_ALIAS_HELP_COLOR_RESET}" >&2

    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      _alias_is_setup_category "${category}" && continue
      _alias_category_is_visible "${category}" || continue
      menu_categories+=("${category}")
      state="off"
      if [ "${BASH_ALIAS_CATEGORY_ENABLED[${category}]:-0}" -eq 1 ]; then
        state="on"
      fi
      number="$(_alias_category_number_for_name "${category}")" || continue
      display="$(_alias_category_display_name "${category}")"
      color="$(_alias_category_color_for_menu "${category}")"
      selected_number="${#menu_categories[@]}"
      selected_number=$((selected_number + 1))
      marker=" "
      line_color=""
      if [ "${selected}" -eq "${selected_number}" ]; then
        marker=">"
        line_color="$(_alias_menu_highlight_line_color)"
      fi
      printf ' %b%s%b %b%b%3d) %-12s%b [%s]%b\n' \
        "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
        "${line_color}" "${color}" "${number}" "${display}" "${BASH_ALIAS_HELP_COLOR_RESET}" "${state}" "${BASH_ALIAS_HELP_COLOR_RESET}" >&2
      rendered_entries=$((rendered_entries + 1))
    done

    for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
      _alias_is_setup_category "${category}" || continue
      _alias_category_is_visible "${category}" || continue
      menu_categories+=("${category}")
      state="off"
      if [ "${BASH_ALIAS_CATEGORY_ENABLED[${category}]:-0}" -eq 1 ]; then
        state="on"
      fi
      number="$(_alias_category_number_for_name "${category}")" || continue
      display="$(_alias_category_display_name "${category}")"
      color="$(_alias_category_color_for_menu "${category}")"
      selected_number="${#menu_categories[@]}"
      selected_number=$((selected_number + 1))
      marker=" "
      line_color=""
      if [ "${selected}" -eq "${selected_number}" ]; then
        marker=">"
        line_color="$(_alias_menu_highlight_line_color)"
      fi
      printf ' %b%s%b %b%b%3d) %-12s%b [%s]%b\n' \
        "$(_alias_menu_highlight_marker_color)" "${marker}" "${BASH_ALIAS_HELP_COLOR_RESET}" \
        "${line_color}" "${color}" "${number}" "${display}" "${BASH_ALIAS_HELP_COLOR_RESET}" "${state}" "${BASH_ALIAS_HELP_COLOR_RESET}" >&2
      rendered_entries=$((rendered_entries + 1))
    done
    if [ "${selected}" -lt 1 ] || [ "${selected}" -gt "$((1 + ${#menu_categories[@]}))" ]; then
      selected=1
    fi
    render_lines=$((1 + 1 + 1 + rendered_entries))
    _alias_menu_redraw_set_lines $((render_lines + 1))

    _alias_menu_read_input "$(_alias_text categories_prompt)"
    choice="${REPLY:-}"
    if _alias_menu_is_quit_input "${choice}"; then
      return 0
    fi
    if _alias_menu_is_back_input "${choice}" && [ "${choice}" != "0" ]; then
      return 0
    fi
    case "${choice}" in
      up)
        if [ "${#menu_categories[@]}" -gt 0 ]; then
          if [ "${selected}" -le 1 ]; then
            selected=$((1 + ${#menu_categories[@]}))
          else
            selected=$((selected - 1))
          fi
        fi
        continue
        ;;
      down)
        if [ "${#menu_categories[@]}" -gt 0 ]; then
          if [ "${selected}" -ge "$((1 + ${#menu_categories[@]}))" ]; then
            selected=1
          else
            selected=$((selected + 1))
          fi
        fi
        continue
        ;;
      right|'')
        if [ "${selected}" -eq 1 ]; then
          _alias_show_all_categories
          continue
        fi
        category="${menu_categories[$((selected - 2))]}"
        _alias_menu_category "${category}"
        case "$?" in
          0) ;;
          130) return 0 ;;
          *) return 1 ;;
        esac
        continue
        ;;
    esac
    [ -z "${choice}" ] && {
      echo "$(_alias_text categories_invalid)"
      return 1
    }

    if [[ "${choice}" =~ ${number_re} ]]; then
      if [ "${choice}" -eq 0 ]; then
        _alias_show_all_categories
        continue
      fi

      category="$(_alias_category_name_for_number "${choice}")" || {
        echo "$(_alias_text categories_invalid)"
        return 1
      }
      selected=1
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
    selected=1
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
  _alias_menu_redraw_reset
  _alias_menu_cache_build || return 1

  if [ -n "${1:-}" ]; then
    if builtin alias -- "$1" >/dev/null 2>&1; then
      _alias_show_alias_details "$1"
      _alias_menu_redraw_reset
      return $?
    fi

    category="$(_alias_resolve_category_input "$1")" || {
      printf '%s\n' "$(_alias_i18n_text "help.unknown_alias_or_category" "$1")"
      echo "$(_alias_i18n_text "help.use_a_for_selection")"
      _alias_menu_redraw_reset
      return 1
    }
  else
    _alias_pick_category_interactive
    rc=$?
    _alias_menu_redraw_reset
    case "${rc}" in
      130) return 0 ;;
      *) return "${rc}" ;;
    esac
  fi

  if [ "${category}" = "all" ]; then
    _alias_show_all_categories
    _alias_menu_redraw_reset
    return 0
  fi

  _alias_menu_category "${category}" 0
  rc=$?
  _alias_menu_redraw_reset
  case "${rc}" in
    130) return 0 ;;
    *) return "${rc}" ;;
  esac
}

alias_menu_cache_warmup() {
  _alias_runtime_cache_reset
  _alias_menu_cache_reset
  _alias_menu_cache_build
}

_alias_category_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local words="all"
  local category=""
  local display=""
  local -A seen=()

  for category in "${BASH_ALIAS_CATEGORY_ORDER[@]}"; do
    _alias_category_is_visible "${category}" || continue
    display="$(_alias_category_display_name "${category}")"
    if [ -z "${seen[${display}]:-}" ]; then
      words+=" ${display}"
      seen["${display}"]=1
    fi
    if [ -z "${seen[${category}]:-}" ]; then
      words+=" ${category}"
      seen["${category}"]=1
    fi
  done

  COMPREPLY=( $(compgen -W "${words}" -- "${cur}") )
}

complete -F _alias_category_completion a

alias_self_test_reload() {
  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "$(_alias_i18n_text "help.err_repo_dir_unset")"
    return 1
  fi

  bash "${BASH_ALIAS_REPO_DIR}/scripts/test_reload_category_mapping.sh"
}

if [ -n "${BASH_ALIAS_REPO_DIR:-}" ] && [ -w "${BASH_ALIAS_REPO_DIR}" ]; then
  alias _alias_test_reload='alias_self_test_reload'
else
  unalias _alias_test_reload 2>/dev/null || true
fi
