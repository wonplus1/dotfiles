#!/usr/bin/env bash

show_script_info() {
  echo "basename: $(basename "$0")"
  echo "dirname : $(dirname "$0")"
  echo "pwd     : $(pwd)"
  echo ""
}

cd_to_script_dir() {
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  cd "${script_dir}" || exit 1
}

detect_os() {
  os_type="$(uname)"
  if [ "${os_type}" = "Linux" ] && [ -d "/mnt/c/Windows/System32" ]; then
    os_type="WSL"
  fi
}

run_setup() {
  case "${os_type}" in
  Linux | WSL)
    setup_dotfiles_script="setup_dotfiles.sh"

    if [ -f /etc/os-release ] && grep -qi '^ID=ubuntu' /etc/os-release; then
      setup_packages_script="setup_packages.sh"
    else
      echo "Linux system detected, but not Ubuntu."
      exit 1
    fi
    ;;
  Darwin)
    setup_dotfiles_script="setup_dotfiles.sh"
    setup_packages_script="setup_packages.sh"
    ;;
  *)
    echo "Error: Unsupported operating system: ${os_type}"
    exit 1
    ;;
  esac

  if [ -f "${script_dir}/setup/${setup_dotfiles_script}" ]; then
    echo "Running setup script for ${os_type}: ${setup_dotfiles_script}"
    bash "${script_dir}/setup/${setup_dotfiles_script}"
  else
    echo "Error: Setup script not found for ${os_type} (${setup_dotfiles_script}) in ${script_dir}"
    exit 1
  fi

  if [ -f "${script_dir}/setup/${setup_packages_script}" ]; then
    echo "Running setup script for ${os_type}: ${setup_packages_script}"
    bash "${script_dir}/setup/${setup_packages_script}"
  else
    echo "Error: Setup script not found for ${os_type} (${setup_packages_script}) in ${script_dir}"
    exit 1
  fi
}

main() {
  show_script_info
  cd_to_script_dir
  detect_os
  run_setup
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
