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
setup
mysql
help
EOF
}

alias_category_sort_key() {
  case "$1" in
    core) printf '1000' ;;
    navigation) printf '2000' ;;
    files) printf '3000' ;;
    process) printf '4000' ;;
    git) printf '5000' ;;
    network) printf '6000' ;;
    journald) printf '7000' ;;
    apt) printf '8000' ;;
    systemd) printf '9000' ;;
    setup) printf '10000' ;;
    _own) printf '99999998' ;;
    mysql) printf '11000' ;;
    help) printf '12000' ;;
    misc) printf '90000' ;;
    _setup) printf '99999999' ;;
    *) printf '50000' ;;
  esac
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
    80-repo-update.sh) printf 'setup' ;;
    81-setup.sh) printf 'setup' ;;
    90-overrides.sh) printf 'setup' ;;
    85-mysql.sh) printf 'mysql' ;;
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
    setup) printf '80-repo-update.sh 81-setup.sh 90-overrides.sh' ;;
    _own) printf '90-overrides.sh' ;;
    mysql) printf '85-mysql.sh' ;;
    help) printf '99-help.sh' ;;
    *) printf '' ;;
  esac
}
