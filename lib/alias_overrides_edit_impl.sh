# shellcheck shell=bash

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/alias_i18n.sh"

_alias_self_edit_text() {
  _alias_i18n_text "overrides_edit.$1"
}

_alias_self_edit_target_help_file() {
  local target_file="$1"
  REPLY="${target_file}.md"
}

_alias_self_edit_ensure_help_file() {
  local help_file="$1"

  [ -f "${help_file}" ] && return 0

  {
    printf '# %s\n' "$(_alias_self_edit_text own_help_title)"
    printf '\n'
    printf '%s\n' "$(_alias_self_edit_text own_help_header)"
    printf '| alias | %s | %s | %s |\n' "$(_alias_self_edit_text own_help_table_short)" "$(_alias_self_edit_text own_help_table_desc)" "$(_alias_self_edit_text own_help_table_cmd)"
    printf '|---|---|---|---|\n'
  } >> "${help_file}" || return 1
}

_alias_self_edit_append_help_entry() {
  local help_file="$1"
  local alias_name="$2"
  local alias_desc="$3"
  local alias_cmd="$4"
  local short_text=""
  local desc_text=""
  local cmd_text=""

  short_text="${alias_desc//|/\\|}"
  desc_text="${alias_desc//|/\\|}"
  cmd_text="${alias_cmd//|/\\|}"

  if grep -Eq "^[[:space:]]*\\|[[:space:]]*${alias_name}[[:space:]]*\\|" "${help_file}"; then
    printf "$(_alias_self_edit_text err_help_exists)\n" "${alias_name}" "${help_file}"
    echo "$(_alias_self_edit_text err_help_exists_hint)"
    return 1
  fi

  printf '| %s | %s | %s | %s |\n' "${alias_name}" "${short_text}" "${desc_text}" "${cmd_text}" >> "${help_file}" || return 1
}

_alias_self_edit_resolve_target_file() {
  local home_file="${HOME}/.bash_aliases_specific"
  local repo_file=""
  local choice=""

  if [ "$(id -u)" -ne 0 ]; then
    REPLY="${home_file}"
    return 0
  fi

  if [ -z "${BASH_ALIAS_REPO_DIR:-}" ]; then
    echo "$(_alias_self_edit_text err_repo_dir_unset)"
    return 1
  fi
  repo_file="${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific"

  echo ""
  echo "$(_alias_self_edit_text choose_target_title)"
  printf "$(_alias_self_edit_text choose_target_home)\n" "${home_file}"
  printf "$(_alias_self_edit_text choose_target_repo)\n" "${repo_file}"
  printf '%s' "$(_alias_self_edit_text choose_target_prompt)"
  IFS= read -r choice

  case "${choice}" in
    ""|1) REPLY="${home_file}" ;;
    2) REPLY="${repo_file}" ;;
    *)
      echo "$(_alias_self_edit_text err_invalid_choice)"
      return 1
      ;;
  esac
}

alias_self_edit() {
  local target_file=""
  local help_file=""
  local alias_name=""
  local alias_desc=""
  local alias_cmd=""
  local escaped_cmd=""

  _alias_self_edit_resolve_target_file || return 1
  target_file="${REPLY}"

  echo ""
  echo "$(_alias_self_edit_text wizard_title)"

  while true; do
    printf '%s' "$(_alias_self_edit_text prompt_alias_name)"
    IFS= read -r alias_name
    if [ -z "${alias_name}" ]; then
      echo "$(_alias_self_edit_text err_alias_empty)"
      continue
    fi
    if [[ ! "${alias_name}" =~ ^[^[:space:]=]+$ ]]; then
      echo "$(_alias_self_edit_text err_alias_invalid)"
      continue
    fi
    break
  done

  printf '%s' "$(_alias_self_edit_text prompt_desc)"
  IFS= read -r alias_desc
  [ -z "${alias_desc}" ] && alias_desc="$(_alias_self_edit_text default_desc)"

  while true; do
    printf "$(_alias_self_edit_text prompt_cmd_for)" "${alias_name}"
    IFS= read -r alias_cmd
    if [ -z "${alias_cmd}" ]; then
      echo "$(_alias_self_edit_text err_cmd_empty)"
      continue
    fi
    break
  done

  if [ -f "${target_file}" ] && grep -Eq "^alias[[:space:]]+${alias_name}=" "${target_file}"; then
    printf "$(_alias_self_edit_text err_alias_exists)\n" "${alias_name}" "${target_file}"
    echo "$(_alias_self_edit_text err_alias_exists_hint)"
    return 1
  fi

  _alias_self_edit_target_help_file "${target_file}"
  help_file="${REPLY}"

  _alias_self_edit_ensure_help_file "${help_file}" || {
    printf "$(_alias_self_edit_text err_help_create)\n" "${help_file}"
    return 1
  }

  escaped_cmd="$(printf '%q' "${alias_cmd}")"
  {
    printf '\n# Alias: %s\n' "${alias_name}"
    printf '# Beschreibung: %s\n' "${alias_desc}"
    printf 'alias %s=%s\n' "${alias_name}" "${escaped_cmd}"
  } >> "${target_file}" || {
    printf "$(_alias_self_edit_text err_target_write)\n" "${target_file}"
    return 1
  }

  _alias_self_edit_append_help_entry "${help_file}" "${alias_name}" "${alias_desc}" "${alias_cmd}" || return 1

  printf "$(_alias_self_edit_text msg_alias_saved)\n" "${alias_name}" "${target_file}"
  printf "$(_alias_self_edit_text msg_help_saved)\n" "${help_file}"

  if declare -F alias_repo_reload >/dev/null 2>&1; then
    alias_repo_reload || return 1
  elif [ -f "${HOME}/.bashrc" ]; then
    # shellcheck disable=SC1090
    source "${HOME}/.bashrc" || return 1
  fi

  echo "$(_alias_self_edit_text msg_reload_done)"
}

alias _alias_edit='alias_self_edit'
