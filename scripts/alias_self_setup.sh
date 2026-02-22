#!/usr/bin/env bash
# shellcheck shell=bash

set -u

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo_dir="$(cd "${_script_dir}/.." && pwd)"
_loader_path="${_repo_dir}/bash_alias_std.sh"
_category_setup_script="${_repo_dir}/scripts/alias_category_setup.sh"
# shellcheck disable=SC1090
source "${_repo_dir}/lib/alias_i18n.sh"
_alias_setup_marker_start="# >>> bash_alias_std setup >>>"
_alias_setup_marker_end="# <<< bash_alias_std setup <<<"

_text() {
  local key="$1"
  case "${key}" in
    err_no_target) _alias_i18n_pick "Fehler: Keine Zieldatei angegeben." "Error: No target file specified." ;;
    err_not_writable) _alias_i18n_pick "Fehler: Datei ist nicht schreibbar: %s" "Error: File is not writable: %s" ;;
    already_marker) _alias_i18n_pick "Bereits eingerichtet in %s (Marker gefunden)." "Already configured in %s (marker found)." ;;
    already_loader) _alias_i18n_pick "Bereits eingerichtet in %s (Loader-Pfad gefunden)." "Already configured in %s (loader path found)." ;;
    entry_added) _alias_i18n_pick "Eintrag hinzugefügt: %s" "Entry added: %s" ;;
    prompt_yes_no_suffix) _alias_i18n_pick " [y/N]: " " [y/N]: " ;;
    root_choose_target) _alias_i18n_pick "Root-Setup Ziel wählen:" "Choose root setup target:" ;;
    root_skip) _alias_i18n_pick "  3) überspringen" "  3) skip" ;;
    prompt_choice_123) _alias_i18n_pick "Auswahl [1/2/3]: " "Choice [1/2/3]: " ;;
    err_loader_missing) _alias_i18n_pick "Fehler: Loader nicht gefunden: %s" "Error: Loader not found: %s" ;;
    prompt_user_setup) _alias_i18n_pick "Setup in %s eintragen?" "Write setup to %s?" ;;
    root_skipped) _alias_i18n_pick "Root-Setup übersprungen." "Root setup skipped." ;;
    user_skipped) _alias_i18n_pick "User-Setup übersprungen." "User setup skipped." ;;
    setup_done) _alias_i18n_pick "Setup abgeschlossen." "Setup completed." ;;
    err_file_missing) _alias_i18n_pick "Fehler: Datei nicht gefunden: %s" "Error: File not found: %s" ;;
    warn_mode_restore) _alias_i18n_pick "Warnung: Konnte Dateirechte nicht wiederherstellen: %s" "Warning: Could not restore file permissions: %s" ;;
    marker_removed) _alias_i18n_pick "Marker-Block entfernt: %s" "Marker block removed: %s" ;;
    err_marker_unfinished) _alias_i18n_pick "Fehler: Marker-Block unvollständig in %s (End-Marker fehlt)." "Error: Marker block incomplete in %s (missing end marker)." ;;
    no_marker_in_file) _alias_i18n_pick "Kein Marker-Block gefunden in %s." "No marker block found in %s." ;;
    err_marker_remove) _alias_i18n_pick "Fehler: Marker konnte nicht entfernt werden aus %s." "Error: Could not remove marker from %s." ;;
    no_marker_found) _alias_i18n_pick "Kein Marker gefunden." "No marker found." ;;
    choose_remove_target) _alias_i18n_pick "Entfernung aus Datei wählen:" "Choose file for removal:" ;;
    remove_cancel) _alias_i18n_pick "  3) Abbrechen" "  3) cancel" ;;
    canceled) _alias_i18n_pick "Abgebrochen." "Canceled." ;;
    err_category_script_missing) _alias_i18n_pick "Fehler: scripts/alias_category_setup.sh nicht gefunden." "Error: scripts/alias_category_setup.sh not found." ;;
    start_category_selection) _alias_i18n_pick "Starte Kategorie-Auswahl." "Starting category selection." ;;
    usage) _alias_i18n_pick "Verwendung: %s [run|category|init|setup|install|remove]" "Usage: %s [run|category|init|setup|install|remove]" ;;
    *) printf '%s' "${key}" ;;
  esac
}

_alias_setup_block() {
  local loader_path="$1"
  cat <<EOF
${_alias_setup_marker_start}
if [ -f "${loader_path}" ]; then
  source "${loader_path}"
fi
${_alias_setup_marker_end}
EOF
}

_alias_setup_add_to_file() {
  local target_file="$1"
  local loader_path="$2"

  if [ -z "${target_file}" ]; then
    echo "$(_text err_no_target)"
    return 1
  fi

  if [ -e "${target_file}" ] && ! [ -w "${target_file}" ]; then
    printf "$(_text err_not_writable)\n" "${target_file}"
    return 1
  fi

  if [ -f "${target_file}" ] && grep -Fq "${_alias_setup_marker_start}" "${target_file}"; then
    printf "$(_text already_marker)\n" "${target_file}"
    return 0
  fi

  if [ -f "${target_file}" ] && grep -Fq "${loader_path}" "${target_file}"; then
    printf "$(_text already_loader)\n" "${target_file}"
    return 0
  fi

  {
    echo ""
    _alias_setup_block "${loader_path}"
  } >> "${target_file}"

  printf "$(_text entry_added)\n" "${target_file}"
}

_alias_setup_has_marker() {
  local target_file="$1"
  [ -f "${target_file}" ] || return 1
  grep -Fq "${_alias_setup_marker_start}" "${target_file}"
}

_alias_setup_detect_alias_file_from_bashrc() {
  local rc_file="$1"
  local match=""

  if [ ! -f "${rc_file}" ]; then
    return 0
  fi

  while IFS= read -r line; do
    case "${line}" in
      \#*|"") continue ;;
    esac

    if [[ "${line}" =~ ^[[:space:]]*(source|\.)[[:space:]]+([^[:space:];]+) ]]; then
      match="${BASH_REMATCH[2]}"
      match="${match/#\~/$HOME}"
      match="${match/#\$HOME/$HOME}"

      case "${match}" in
        */.bash_aliases|*/bash_aliases|*.aliases.sh|*/aliases.sh)
          printf "%s" "${match}"
          return 0
          ;;
      esac
    fi
  done < "${rc_file}"
}

_alias_setup_resolve_user_target() {
  local user_rc="${HOME}/.bashrc"
  local detected_alias_file=""

  detected_alias_file="$(_alias_setup_detect_alias_file_from_bashrc "${user_rc}")"
  if [ -n "${detected_alias_file}" ] && [ "${detected_alias_file}" != "${user_rc}" ]; then
    printf "%s" "${detected_alias_file}"
    return 0
  fi

  printf "%s" "${user_rc}"
}

_alias_setup_find_marker_target() {
  local user_target=""

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ] && _alias_setup_has_marker "/etc/bash.bashrc"; then
    REPLY="/etc/bash.bashrc"
    return 0
  fi

  user_target="$(_alias_setup_resolve_user_target)"
  if [ -n "${user_target}" ] && _alias_setup_has_marker "${user_target}"; then
    REPLY="${user_target}"
    return 0
  fi

  REPLY=""
  return 1
}

_alias_setup_prompt_yes_no() {
  local question="$1"
  local answer=""
  read -r -p "${question}$(_text prompt_yes_no_suffix)" answer
  case "${answer}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

_alias_setup_prompt_choice_root_target() {
  local user_target="$1"
  local answer=""

  echo "$(_text root_choose_target)" >&2
  echo "  1) ${user_target}" >&2
  echo "  2) /etc/bash.bashrc" >&2
  echo "$(_text root_skip)" >&2
  read -r -p "$(_text prompt_choice_123)" answer

  case "${answer}" in
    1) printf "%s" "${user_target}" ;;
    2) printf "/etc/bash.bashrc" ;;
    *) printf "" ;;
  esac
}

alias_setup() {
  local user_rc="${HOME}/.bashrc"
  local user_target=""
  local final_target=""

  if [ ! -f "${_loader_path}" ]; then
    printf "$(_text err_loader_missing)\n" "${_loader_path}"
    return 1
  fi

  user_target="$(_alias_setup_resolve_user_target)"
  if [ -z "${user_target}" ]; then
    user_target="${user_rc}"
  fi

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ]; then
    final_target="$(_alias_setup_prompt_choice_root_target "${user_target}")"
    if [ -n "${final_target}" ]; then
      _alias_setup_add_to_file "${final_target}" "${_loader_path}" || return 1
    else
      echo "$(_text root_skipped)"
    fi
  elif _alias_setup_prompt_yes_no "$(printf "$(_text prompt_user_setup)" "${user_target}")"; then
    _alias_setup_add_to_file "${user_target}" "${_loader_path}" || return 1
  else
    echo "$(_text user_skipped)"
  fi

  echo "$(_text setup_done)"
}

_alias_setup_remove_from_file() {
  local target_file="$1"
  local tmp_file=""
  local awk_rc=0
  local stat_out=""
  local orig_mode=""
  local orig_uid=""
  local orig_gid=""

  if [ -z "${target_file}" ] || [ ! -f "${target_file}" ]; then
    printf "$(_text err_file_missing)\n" "${target_file}"
    return 1
  fi

  if [ ! -w "${target_file}" ]; then
    printf "$(_text err_not_writable)\n" "${target_file}"
    return 1
  fi

  # Preserve ownership and permissions because mktemp creates 0600 files.
  stat_out="$(stat -c '%a %u %g' "${target_file}" 2>/dev/null || true)"
  if [ -n "${stat_out}" ]; then
    read -r orig_mode orig_uid orig_gid <<< "${stat_out}"
  fi

  tmp_file="$(mktemp)" || return 1

  awk -v start="${_alias_setup_marker_start}" -v stop="${_alias_setup_marker_end}" '
    BEGIN { in_block=0; removed=0 }
    index($0, start) > 0 { in_block=1; removed=1; next }
    in_block == 1 {
      if (index($0, stop) > 0) {
        in_block=0
      }
      next
    }
    { print }
    END {
      if (in_block == 1) {
        exit 2
      }
      if (removed == 0) {
        exit 3
      }
    }
  ' "${target_file}" > "${tmp_file}" || awk_rc=$?

  case "${awk_rc}" in
    0)
      mv "${tmp_file}" "${target_file}" || {
        rm -f "${tmp_file}"
        return 1
      }
      if [ -n "${orig_mode}" ]; then
        chmod "${orig_mode}" "${target_file}" || {
          printf "$(_text warn_mode_restore)\n" "${target_file}"
        }
      fi
      if [ -n "${orig_uid}" ] && [ -n "${orig_gid}" ]; then
        chown "${orig_uid}:${orig_gid}" "${target_file}" 2>/dev/null || true
      fi
      printf "$(_text marker_removed)\n" "${target_file}"
      ;;
    2)
      rm -f "${tmp_file}"
      printf "$(_text err_marker_unfinished)\n" "${target_file}"
      return 1
      ;;
    3)
      rm -f "${tmp_file}"
      printf "$(_text no_marker_in_file)\n" "${target_file}"
      return 1
      ;;
    *)
      rm -f "${tmp_file}"
      printf "$(_text err_marker_remove)\n" "${target_file}"
      return 1
      ;;
  esac
}

alias_setup_remove() {
  local target_file=""
  local user_target=""
  local answer=""

  if _alias_setup_find_marker_target; then
    target_file="${REPLY}"
    _alias_setup_remove_from_file "${target_file}"
    return $?
  fi

  user_target="$(_alias_setup_resolve_user_target)"
  if [ -z "${user_target}" ]; then
    user_target="${HOME}/.bashrc"
  fi

  if [ "${EUID}" -eq 0 ] && [ -f /etc/bash.bashrc ]; then
    echo "$(_text no_marker_found)"
    echo "$(_text choose_remove_target)"
    echo "  1) /etc/bash.bashrc"
    echo "  2) ${user_target}"
    echo "$(_text remove_cancel)"
    read -r -p "$(_text prompt_choice_123)" answer
    case "${answer}" in
      1) _alias_setup_remove_from_file "/etc/bash.bashrc" ;;
      2) _alias_setup_remove_from_file "${user_target}" ;;
      *) echo "$(_text canceled)"; return 1 ;;
    esac
  else
    _alias_setup_remove_from_file "${user_target}"
  fi
}

_alias_setup_run_category_setup() {
  if [ -f "${_category_setup_script}" ]; then
    bash "${_category_setup_script}"
  else
    echo "$(_text err_category_script_missing)"
    return 1
  fi
}

alias_self_setup() {
  echo "$(_text start_category_selection)"
  _alias_setup_run_category_setup
}

alias_init() {
  alias_setup
}

_main() {
  case "${1:-}" in
    --remove|remove|rm)
      alias_setup_remove
      ;;
    --setup|setup|install|--init|init)
      alias_init
      ;;
    --category|category)
      alias_self_setup
      ;;
    ""|--run|run)
      alias_self_setup
      ;;
    *)
      printf "$(_text usage)\n" "$0"
      return 1
      ;;
  esac
}

_main "${1:-}"
