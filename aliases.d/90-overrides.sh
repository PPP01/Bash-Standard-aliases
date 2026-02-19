# Lokale Overrides
alias rload='source ~/.bashrc'
alias e_alias='nano ~/.bash_aliases && source ~/.bashrc'

if [ -f /opt/scripts/bash_aliases_specific ]; then
  source /opt/scripts/bash_aliases_specific
fi

if [ -f ~/.bash_aliases_specific ]; then
  source ~/.bash_aliases_specific
fi
