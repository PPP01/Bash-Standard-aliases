# Navigation und sichere Defaults
alias rm='rm -i'
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias ~='cd ~'
alias -- -='cd -'
alias cdl='dirs -v'
alias p='pushd'
alias o='popd'

cd_stack() {
  local idx="${1:-}"
  local target

  if ! [[ "${idx}" =~ ^[+-][0-9]+$ ]]; then
    echo "Usage: cd_stack [+N|-N]  (z. B. +1 oder -2)"
    return 1
  fi

  target="$(dirs "${idx}" 2>/dev/null)"
  if [ -z "${target}" ]; then
    echo "Kein Verzeichnis fuer ${idx} im Stack. Erst mit 'p' (pushd) arbeiten."
    return 1
  fi
  cd "${target}" || return 1
}

alias -- +1='cd_stack +1'
alias -- +2='cd_stack +2'
alias -- +3='cd_stack +3'
alias -- +4='cd_stack +4'
alias -- -1='cd_stack -1'
alias -- -2='cd_stack -2'
alias -- -3='cd_stack -3'
alias -- -4='cd_stack -4'
