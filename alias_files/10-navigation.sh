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

cd_prev2() {
  local target
  target="$(dirs +1 2>/dev/null)"
  if [ -z "${target}" ]; then
    echo "Kein zweitletztes Verzeichnis im Stack. Erst mit 'p' (pushd) arbeiten."
    return 1
  fi
  cd "${target}" || return 1
}

alias -- -2='cd_prev2'
