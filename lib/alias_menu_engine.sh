# shellcheck shell=bash

# Shared interactive menu engine used by help and setup menus.

declare -g BASH_ALIAS_MENU_LAST_RENDER_LINES="${BASH_ALIAS_MENU_LAST_RENDER_LINES:-0}"
declare -g BASH_ALIAS_MENU_RENDER_ACTIVE="${BASH_ALIAS_MENU_RENDER_ACTIVE:-0}"
declare -g BASH_ALIAS_MENU_CURSOR_HIDDEN="${BASH_ALIAS_MENU_CURSOR_HIDDEN:-0}"
declare -g BASH_ALIAS_MENU_TTY_MODE_ACTIVE="${BASH_ALIAS_MENU_TTY_MODE_ACTIVE:-0}"
declare -g BASH_ALIAS_MENU_TTY_MODE_SAVED="${BASH_ALIAS_MENU_TTY_MODE_SAVED:-}"
declare -g BASH_ALIAS_MENU_SAVED_TRAP_INT="${BASH_ALIAS_MENU_SAVED_TRAP_INT:-}"
declare -g BASH_ALIAS_MENU_SAVED_TRAP_TERM="${BASH_ALIAS_MENU_SAVED_TRAP_TERM:-}"
declare -g BASH_ALIAS_MENU_INTERRUPTED="${BASH_ALIAS_MENU_INTERRUPTED:-0}"

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

_alias_menu_tty_raw_enabled() {
  case "${BASH_ALIAS_MENU_TTY_RAW:-1}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_menu_session_begin() {
  BASH_ALIAS_MENU_INTERRUPTED=0
  BASH_ALIAS_MENU_SAVED_TRAP_INT="$(trap -p INT || true)"
  BASH_ALIAS_MENU_SAVED_TRAP_TERM="$(trap -p TERM || true)"
  trap '_alias_menu_handle_interrupt' INT TERM
  _alias_menu_tty_raw_enter
}

_alias_menu_handle_interrupt() {
  BASH_ALIAS_MENU_INTERRUPTED=1
}

_alias_menu_session_end() {
  _alias_menu_tty_raw_leave
  _alias_menu_redraw_reset
  if [ -n "${BASH_ALIAS_MENU_SAVED_TRAP_INT}" ]; then
    eval "${BASH_ALIAS_MENU_SAVED_TRAP_INT}"
  else
    trap - INT
  fi
  if [ -n "${BASH_ALIAS_MENU_SAVED_TRAP_TERM}" ]; then
    eval "${BASH_ALIAS_MENU_SAVED_TRAP_TERM}"
  else
    trap - TERM
  fi
  BASH_ALIAS_MENU_SAVED_TRAP_INT=""
  BASH_ALIAS_MENU_SAVED_TRAP_TERM=""
}

_alias_menu_tty_raw_enter() {
  local mode=""
  _alias_menu_tty_raw_enabled || return 0
  [ -t 0 ] || return 0
  command -v stty >/dev/null 2>&1 || return 0
  [ "${BASH_ALIAS_MENU_TTY_MODE_ACTIVE}" -eq 0 ] || return 0

  mode="$(stty -g 2>/dev/null || true)"
  [ -n "${mode}" ] || return 0
  BASH_ALIAS_MENU_TTY_MODE_SAVED="${mode}"
  if stty -echo -icanon min 1 time 0 2>/dev/null; then
    BASH_ALIAS_MENU_TTY_MODE_ACTIVE=1
  fi
}

_alias_menu_tty_raw_leave() {
  _alias_menu_tty_raw_enabled || return 0
  if [ "${BASH_ALIAS_MENU_TTY_MODE_ACTIVE}" -ne 1 ] && [ -z "${BASH_ALIAS_MENU_TTY_MODE_SAVED}" ]; then
    return 0
  fi
  command -v stty >/dev/null 2>&1 || return 0

  if [ -n "${BASH_ALIAS_MENU_TTY_MODE_SAVED}" ]; then
    stty "${BASH_ALIAS_MENU_TTY_MODE_SAVED}" 2>/dev/null || true
  else
    stty sane 2>/dev/null || true
  fi
  BASH_ALIAS_MENU_TTY_MODE_ACTIVE=0
  BASH_ALIAS_MENU_TTY_MODE_SAVED=""
}

_alias_menu_coalesce_arrow_input() {
  local last_direction="$1"
  local key=""
  local seq=""
  local csi=""
  local max_drain=256
  local drained=0
  local next_direction=""

  while [ "${drained}" -lt "${max_drain}" ]; do
    if ! IFS= read -r -s -n 1 -t 0.002 key; then
      break
    fi
    drained=$((drained + 1))

    if [ "${key}" != $'\e' ]; then
      continue
    fi
    if ! IFS= read -r -s -n 1 -t 0.002 seq; then
      continue
    fi
    drained=$((drained + 1))
    if [ "${seq}" != "[" ]; then
      continue
    fi

    csi=""
    while IFS= read -r -s -n 1 -t 0.002 seq; do
      drained=$((drained + 1))
      csi+="${seq}"
      case "${seq}" in
        [[:alpha:]~]) break ;;
      esac
      [ "${drained}" -lt "${max_drain}" ] || break
    done

    next_direction=""
    case "${csi}" in
      A) next_direction="up" ;;
      B) next_direction="down" ;;
      C) next_direction="right" ;;
      D) next_direction="left" ;;
    esac
    if [ -n "${next_direction}" ]; then
      last_direction="${next_direction}"
    fi
  done

  REPLY="${last_direction}"
}

_alias_menu_read_input() {
  local prompt="$1"
  local key=""
  local seq=""
  local csi=""
  local value=""
  local read_rc=0

  printf '%s' "${prompt}"
  while true; do
    if _alias_menu_was_interrupted; then
      echo ""
      return 130
    fi
    if ! IFS= read -r -s -n 1 -t 0.1 key; then
      read_rc=$?
      if [ "${read_rc}" -eq 130 ]; then
        echo ""
        return 130
      fi
      case "${read_rc}" in
        142) continue ;;
        1) break ;;
        *) continue ;;
      esac
    fi
    read_rc=0
    case "${key}" in
      $'\x03')
        echo ""
        return 130
        ;;
      '')
        break
        ;;
      $'\e')
        if IFS= read -r -s -n 1 -t 0.05 seq; then
          if [ "${seq}" = "[" ]; then
            csi=""
            while IFS= read -r -s -n 1 -t 0.02 seq; do
              csi+="${seq}"
              case "${seq}" in
                [[:alpha:]~]) break ;;
              esac
            done
            case "${csi}" in
              A)
                echo ""
                _alias_menu_coalesce_arrow_input "up"
                return 0
                ;;
              B)
                echo ""
                _alias_menu_coalesce_arrow_input "down"
                return 0
                ;;
              C)
                echo ""
                _alias_menu_coalesce_arrow_input "right"
                return 0
                ;;
              D)
                echo ""
                _alias_menu_coalesce_arrow_input "left"
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

  if [ "${BASH_ALIAS_MENU_INTERRUPTED}" -eq 1 ] || [ "${read_rc}" -eq 130 ]; then
    BASH_ALIAS_MENU_INTERRUPTED=0
    echo ""
    return 130
  fi

  echo ""
  REPLY="${value}"
}

_alias_menu_was_interrupted() {
  [ "${BASH_ALIAS_MENU_INTERRUPTED}" -eq 1 ] || return 1
  BASH_ALIAS_MENU_INTERRUPTED=0
  return 0
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
    if _alias_menu_hide_cursor_enabled; then
      if command -v tput >/dev/null 2>&1; then
        tput civis 2>/dev/null || printf '\033[?25l'
      else
        printf '\033[?25l'
      fi
      BASH_ALIAS_MENU_CURSOR_HIDDEN=1
    fi
    BASH_ALIAS_MENU_RENDER_ACTIVE=1
  fi
  if [ "${BASH_ALIAS_MENU_LAST_RENDER_LINES}" -gt 0 ]; then
    printf '\033[%sA' "${BASH_ALIAS_MENU_LAST_RENDER_LINES}"
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
