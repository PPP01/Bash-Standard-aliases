# Lokale Overrides
alias _self_reload='alias_repo_reload'
alias _self_edit='nano ~/.bash_aliases && source ~/.bashrc'

if [ -f /opt/scripts/bash_aliases_specific ]; then
  source /opt/scripts/bash_aliases_specific
fi

if [ -f ~/.bash_aliases_specific ]; then
  source ~/.bash_aliases_specific
fi
