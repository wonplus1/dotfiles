#!/usr/bin/env bash

show_script_info() {
  echo "basename: $(basename "$0")"
  echo "dirname : $(dirname "$0")"
  echo "pwd     : $(pwd)"
  echo ""
}

initialize_variables() {
  dotfiles_base="${HOME}/.dotfiles"
  backup_dir="${HOME}/.local/share/backups"
  is_linux=$([[ "$(uname -a)" =~ "Linux" ]] && echo 1 || echo 0)
  is_wsl=$([ -d "/mnt/c/Windows/System32" ] && echo 1 || echo 0)
  is_mac=$([ "$(uname)" = "Darwin" ] && echo 1 || echo 0)

  mkdir -pv "${backup_dir}"
}

find_and_move_to_dotfiles_root() {
  local target_file="install.sh"
  local curr_dir
  curr_dir="$(cd "$(dirname "$0")" && pwd)"

  while [ "${curr_dir}" != "/" ]; do
    if [ -f "${curr_dir}/${target_file}" ]; then
      echo "Found '${target_file}' in: ${curr_dir}"
      cd "${curr_dir}" || {
        echo "Error: Unable to move to directory '${curr_dir}'."
        return 1
      }
      dotfiles_root="${curr_dir}"
      return 0
    fi
    curr_dir="$(dirname "${curr_dir}")"
  done

  echo "Error: '${target_file}' not found in any parent directories."
  return 1
}

create_dir() {
  mkdir -pv "$1"
}

backup_if_exists() {
  local target_path="$1"
  if [ -e "${target_path}" ] && [ ! -L "${target_path}" ]; then
    echo "Backing up existing file/directory: ${target_path}"
    mv -fv "${target_path}" "${backup_dir}/$(basename "${target_path}").$(date +"%Y%m%d_%H%M%S").bak"
  fi
}

create_symlink() {
  local source_path="$1"
  local target_path="$2"

  if [ ! -e "${source_path}" ]; then
    echo "❗️ Error: Source file/directory not found: ${source_path}"
    return 1
  fi

  if [ -L "${target_path}" ] && [ "$(readlink "${target_path}")" = "${source_path}" ]; then
    echo "✅ Symlink already exists and is correct: ${target_path}"
    return 0
  fi

  backup_if_exists "${target_path}"

  if [ "${is_linux}" -eq 1 ]; then
    ln --force --symbolic --verbose "${source_path}" "${target_path}"
  elif [ "${is_mac}" -eq 1 ]; then
    ln -fsv "${source_path}" "${target_path}"
  fi
}

copy_files() {
  local srcs=("${@:1:$#-1}")
  local dest="${@: -1}"

  if [ "${is_linux}" -eq 1 ]; then
    cp --force --no-preserve=all --recursive --verbose "${srcs[@]}" "${dest}"

  elif [ "${is_mac}" -eq 1 ]; then
    cp -RXv "${srcs[@]}" "${dest}"
  fi
}

backup_and_copy_dotfiles() {
  if [ "${dotfiles_root}" != "${dotfiles_base}" ]; then
    if [ -d "${dotfiles_base}" ]; then
      create_dir "${backup_dir}"
      mv -fv "${dotfiles_base}" "${backup_dir}/dotfiles_old_$(date +"%Y%m%d_%H%M%S")"
    fi

    if command -v rsync &>/dev/null; then
      rsync -av --exclude='.git' --exclude='.github' "${dotfiles_root}/" "${dotfiles_base}/"
    else
      create_dir "${dotfiles_base}"
      copy_files "${dotfiles_root}"/* "${dotfiles_base}"
      for item in "${dotfiles_root}"/.*; do
        if [[ "$(basename "${item}")" != ".git" && "$(basename "${item}")" != ".github" ]]; then
          copy_files "${item}" "${dotfiles_base}"
        fi
      done
    fi

    cd "${dotfiles_base}"
  fi
}

symlink_dotfiles() {
  if [ -f "${dotfiles_base}/.zshrc" ]; then
    create_symlink "${dotfiles_base}/.zshrc" "${HOME}/.zshrc"
  fi

  if [ -f "${dotfiles_base}/.vimrc" ]; then
    create_symlink "${dotfiles_base}/.vimrc" "${HOME}/.vimrc"
  fi

  if [ -d "${dotfiles_base}/.vim" ]; then
    create_symlink "${dotfiles_base}/.vim" "${HOME}/.vim"
  fi

  if [ -d "${dotfiles_base}/.config" ]; then
    create_symlink "${dotfiles_base}/.config" "${HOME}/.config"
  fi

  if [ -f "${dotfiles_base}/.gitignore_global" ]; then
    create_symlink "${dotfiles_base}/.gitignore_global" "${HOME}/.gitignore_global"
  fi

  if [ -f "${dotfiles_base}/.ideavimrc" ]; then
    create_symlink "${dotfiles_base}/.ideavimrc" "${HOME}/.ideavimrc"
  fi
}

setup_IDE_config_files() {
  echo ""
  echo "Setting up IDE Vim configurations"
  local vscode_user_settings="${dotfiles_base}/.config/Code"

  if [ "${is_wsl}" -ne 1 ]; then
    if [ -d "${vscode_user_settings}" ]; then
      if [ "${is_mac}" -eq 1 ]; then
        local vscode_macOS="${HOME}/Library/Application Support/Code"
        create_dir "${vscode_macOS}"
        create_symlink "${vscode_user_settings}" "${vscode_macOS}"
      fi
    fi
    return
  else
    echo -e "\n[WSL] Configuring for Windows host tools\n"
    local windows_home=$(wslpath "$(powershell.exe '(Get-Item ENV:USERPROFILE).Value' | tr -d '[:space:]')")

    if [ -f "${dotfiles_base}/.ideavimrc" ]; then
      cd "${windows_home}"
      # For windows host, we copy instead of symlinking
      backup_if_exists "${windows_home}/.ideavimrc"
      copy_files "${dotfiles_base}/.ideavimrc" "${windows_home}/.ideavimrc"
      cd "${dotfiles_base}"
    fi

    if [ -d "${vscode_user_settings}" ]; then
      local vscode_Windows="${windows_home}/AppData/Roaming/Code/User"
      create_dir "${vscode_Windows}"

      cd "${vscode_Windows}"
      if [ -f "${vscode_user_settings}/User/settings.json" ]; then
        # For windows host, we copy instead of symlinking
        backup_if_exists "${vscode_Windows}/settings.json"
        copy_files "${vscode_user_settings}/User/settings.json" "${vscode_Windows}/settings.json"
      fi
      if [ -f "${vscode_user_settings}/User/keybindings.json" ]; then
        # For windows host, we copy instead of symlinking
        backup_if_exists "${vscode_Windows}/keybindings.json"
        copy_files "${vscode_user_settings}/User/keybindings.json" "${vscode_Windows}/keybindings.json"
      fi
      cd "${dotfiles_base}"
    fi
  fi
}

main() {
  show_script_info
  initialize_variables
  find_and_move_to_dotfiles_root

  echo ""
  echo "Setup dotfiles start"
  printf "%0.s-" {1..60}
  echo ""

  backup_and_copy_dotfiles
  symlink_dotfiles
  setup_IDE_config_files

  echo ""
  printf "%0.s-" {1..60}
  printf "\nSetup dotfiles done!\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
