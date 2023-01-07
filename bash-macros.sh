#!/usr/bin/env bash

# Macros
alias ma="bash_macro_add"
alias mh="bash_macros_help"
alias ml="bash_macros_list"
alias ms="bash_macros_save"
alias md="bash_macro_delete"
alias mm="bash_macro_move"
alias mc="bash_macros_clear"
alias mr="bash_macros_reload"

function bash_macros_aliases() {
  echo "ma mh ml ms md mm mc mr"
}

function bash_macros_help() {
  bash_macros_init
  echo "Bash Macros Help:"
  echo
  echo " - mh — Show (this) Bash Macros help"
  echo " - ml — List macros"
  echo " - mc — Clear macros"
  echo " - ms — Save macros to ~/$(bash_macros_rel_file)"
  echo " - mr — Reload macros from ~/$(bash_macros_rel_file)"
  echo " - ma — Add macro from history"
  echo "        Syntax:  ma <macro#> <command>"
  echo "          Example: ma 3 'git clone $(bash_macros_repo_url)'"
  echo "        Syntax:  ma <macro#> <history#>"
  echo "          Example: ma 7 531"
  echo " - mm — Move macro"
  echo "        Syntax:  mm <oldMacro#> <newMacro#>"
  echo "          Example: mm 6 9"
  echo " - md — Delete macro"
  echo "        Syntax:  md <macro#>"
  echo "          Example: md 7"
  echo
  echo "See: $(bash_macros_repo_url)"
  echo
}

function bash_macros_on_error() {
  local msg="${1:-}"
  echo
  echo "${msg}; cannot continue."
  echo
  bash_macros_wait
  exit 1
}

function bash_macros_wait() {
  echo "Press Ctrl-C to exit..."
  read -t 10 -n 1
}

function bash_macros_repo_url() {
  echo "https://github.com/mikeschinkel/bash-macros"
}

function bash_macros_filepath() {
  echo "$(bash_macros_dirpath)/$(bash_macros_file)"
}

function bash_macros_dir() {
  echo ".config/bash-macros"
}

function bash_macros_dirpath() {
  echo "${HOME}/$(bash_macros_dir)"
}

function bash_macros_rel_file() {
  echo "$(bash_macros_dir)/$(bash_macros_file)"
}

function bash_macros_file() {
  echo "macros.sh"
}

# Adds a numbered macro — m1..m9 — from a numbered line in history
# e.g. mha 3 123 # Adds m3 alias to actual command from history !123
function bash_macro_add() {
  local macro_num="${1:-}"
  local command="${2:-}"

  if [ "" == "${macro_num}" ] ; then
    bash_macros_on_error "You must specify either a macro number from 1 to 9 as a 1st parameter"
  fi
  if [ "" == "${command}" ] ; then
    bash_macros_on_error "You must specify either a command or a history number as a 2nd parameter"
  fi
  if [[ "${command}" =~ [0-9]+ ]] ; then
    command="$(history | grep "^ ${command} " | cut -f 2- -d ' ')"
  fi
  echo "m${macro_num}=\"${command}\""
  # shellcheck disable=SC2139
  # shellcheck disable=SC2086
  alias m${macro_num}="${command}"
}

function bash_macros_list_raw() {
  alias | grep -E 'alias m[1-9]='
}

function bash_macros_list() {
  local heading="${1:-}"
  if [ "" != "${heading}" ] ; then
    echo "${heading}"
  fi
  echo
  if [ "" == "$(bash_macros_list_raw)" ] ; then
    echo "No macros to list"
  else
    bash_macros_list_raw | cut -f 2- -d ' '
  fi
}

function bash_macro_move() {
  local from="${1:-}"
  local to="${2:-}"

  if [ "" == "${from}" ] ; then
    bash_macros_on_error "You must specify either a macro number from 1 to 9 as a 1st parameter to move from"
  fi
  if [ "" == "${to}" ] ; then
    bash_macros_on_error "You must specify either a macro number from 1 to 9 as a 2nd parameter to move to"
  fi
  if ! bash_macro_exists "${from}" ; then
    echo "Macro m${from} does not exist thus not moved."
    return
  fi

  # shellcheck disable=SC2139
  # shellcheck disable=SC2086
  alias ${to}="$(alias "m${from}" | cut -f 2 -d "=" | sed "s/^'\(.*\)'$/\1/")"
  unalias "m${from}"
}

function bash_macros_init() {
  mkdir -p "$(bash_macros_dir)"
  if [ ! -f "$(bash_macros_filepath)" ] ; then
    touch "$(bash_macros_filepath)"
  fi
}

function bash_macros_clear() {
  bash_macros_list "Bash macros to be cleared:"
  echo
  for macro_num in 1 2 3 4 5 6 7 8 9 ; do
    if ! bash_macro_exists ${macro_num}; then
      continue
    fi
    bash_macro_delete ${macro_num}
  done
  echo "Bash macros cleared."
}

function bash_macros_reload() {
  local task="${1:-}"

  if [ "" == "${task}" ] ; then
    task="reloaded"
  fi
  bash_macros_init
  bash_macros_clear >/dev/null
  # shellcheck disable=SC1090
  source "$(bash_macros_filepath)"
  bash_macros_list "Bash macros ${task}:"
  echo
  if [ "reloaded" == "${task}" ] ; then
    echo "Macros loaded."
    echo
  fi
}

function bash_macro_delete() {
  unalias "m$1" 2>/dev/null
}

function bash_macros_aliases_clear() {
  for alias in $(bash_macros_aliases) ; do
    if ! bash_macros_alias_exists "${alias}" ; then
      continue
    fi
    unalias "${alias}"
  done
}

function bash_macros_functions_clear() {
  while read -r func ; do
    unset -f "${func}"
  done < <(declare -F | awk '{print $3}' | grep -E '^bash_macros?_')
}

function bash_macros_uninstall() {
  local bakfile
  local tmpfile
  local bashrc="${HOME}/.bashrc"
  local repo_url

  if [ ! -d "$(bash_macros_dir)" ] ; then
    echo "Bash Macros not installed. No need to uninstall."
  fi

  echo "Uninstalling Bash Macros..."
  rm -rf "$(bash_macros_dir)"
  if [ -f "${bashrc}" ] ; then
    bakfile="$(mktemp "${HOME}/.bashrc.bak.XXX")"
    tmpfile="$(mktemp "/tmp/.bashrc.XXX")"
    cp ~/.bashrc "${bakfile}"
    echo
    echo "NOTE: A backup of your ~/.bashrc was saved to ${bakfile}."
    echo
    grep -Ev "^source $(bash_macros_dirpath)" "${bashrc}" > "${tmpfile}" \
      && mv "${tmpfile}" "${bashrc}"
  fi
  bash_macros_clear >/dev/null
  bash_macros_aliases_clear
  repo_url="$(bash_macros_repo_url)"
  bash_macros_functions_clear
  echo "Bash Macros uninstalled.  To reinstall, see ${repo_url}#installing"
  echo
}

function bash_macros_alias_exists() {
  test "" != "$(alias "$1" 2>/dev/null)"
}

function bash_macro_exists() {
  bash_macros_alias_exists "m$1"
}

function bash_macros_save() {
  bash_macros_list "Saving macros:"
  echo
  (
    echo '#!/usr/bin/env bash'
    while read -r alias ; do
      if [ "" == "${alias}" ] ; then
         continue
      fi
      printf "alias %s\n" "${alias}"
    done < <(ml)
  ) > "$(bash_macros_filepath)"
  chmod +x "$(bash_macros_filepath)"
  echo "Bash macros saved to ~/$(bash_macros_rel_file)"
}

bash_macros_reload assigned
