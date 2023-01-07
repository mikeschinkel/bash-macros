#!/usr/bin/env bash

set -eu pipefail

function bash_macros_latest_version() {
  curl -s https://api.github.com/repos/mikeschinkel/bash-macros/releases/latest | grep tag_name | awk -F'"' '{print $4}'
}

BASH_MACROS_VERSION="${BASH_MACROS_VERSION:-$(bash_macros_latest_version)}"

function bash_macros_on_error() {
  local msg="$1"
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
function bash_macros_install() {
  local config_dir="${HOME}/.config"
  local bashrc="${HOME}/.bashrc"
  local install_dir=".config/bash-macros"
  local install_dirpath="${HOME}/${install_dir}"
  local script="${install_dirpath}/bash-macros.sh"
  local pwd

  echo "Installing Bash Macros"
  echo

  pwd="$(pwd)"

  if [ "" == "${HOME}" ] ; then
    bash_macros_on_error "Your \$HOME variable is not set"
  fi

  if ! mkdir -p "${config_dir}" ; then
    bash_macros_on_error "Cannot create ${config_dir}"
  fi

  if ! cd "${config_dir}" ; then
    bash_macros_on_error "Cannot change directory to ${config_dir}"
  fi

  if [ -d "${install_dirpath}" ] ; then
    bash_macros_on_error "Bash Macro install directory ~/${install_dir} already exists"
  fi

  git clone --quiet https://github.com/mikeschinkel/bash-macros

  if ! cd "bash-macros" ; then
    bash_macros_on_error "Cannot change directory to $(pwd)/bash-macros"
  fi
  git checkout "${BASH_MACROS_VERSION}" 2>/dev/null

  printf "\nsource %s\n" "${script}" >> "${bashrc}"
  # shellcheck disable=SC1090
  source "${script}" >/dev/null
  alias m1="echo 'Hello Bash Macros'"
  bash_macros_save >/dev/null
  bash_macros_help

  # shellcheck disable=SC2164
  cd "${pwd}"

  echo "Installation complete."
  echo

}
bash_macros_install "$@"
