# shellcheck shell=bash

alias_categories_list() {
  cat <<'EOF'
core
navigation
files
process
git
network
journald
apt
systemd
repo
setup
_setup
mysql
overrides
help
EOF
}

alias_category_for_module() {
  case "$1" in
    00-core.sh) printf 'core' ;;
    10-navigation.sh) printf 'navigation' ;;
    20-files.sh) printf 'files' ;;
    30-process.sh) printf 'process' ;;
    35-git.sh) printf 'git' ;;
    40-network.sh) printf 'network' ;;
    50-root-journal.sh) printf 'journald' ;;
    60-root-apt.sh) printf 'apt' ;;
    70-root-systemd.sh) printf 'systemd' ;;
    80-repo-update.sh) printf 'repo' ;;
    81-setup.sh) printf 'setup' ;;
    85-mysql.sh) printf 'mysql' ;;
    90-overrides.sh) printf 'overrides' ;;
    99-help.sh) printf 'help' ;;
    *) printf 'misc' ;;
  esac
}

alias_modules_for_category() {
  case "$1" in
    core) printf '00-core.sh' ;;
    navigation) printf '10-navigation.sh' ;;
    files) printf '20-files.sh' ;;
    process) printf '30-process.sh' ;;
    git) printf '35-git.sh' ;;
    network) printf '40-network.sh' ;;
    journald) printf '50-root-journal.sh' ;;
    apt) printf '60-root-apt.sh' ;;
    systemd) printf '70-root-systemd.sh' ;;
    repo) printf '80-repo-update.sh' ;;
    setup) printf '81-setup.sh' ;;
    _setup) printf '80-repo-update.sh 81-setup.sh 90-overrides.sh 99-help.sh' ;;
    mysql) printf '85-mysql.sh' ;;
    overrides) printf '90-overrides.sh' ;;
    help) printf '99-help.sh' ;;
    *) printf '' ;;
  esac
}
