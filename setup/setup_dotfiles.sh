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
  is_wsl=$(grep -qiE "microsoft|wsl" /proc/version && echo 1 || echo 0)
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

  if [ -f "${dotfiles_base}/.vimrc" ]; then
    nvim_config_dir="${HOME}/.config/nvim"
    create_dir "${nvim_config_dir}"
    create_symlink "${dotfiles_base}/.vimrc" "${nvim_config_dir}/init.vim"

    if [ -d "${dotfiles_base}/.vim/colors" ]; then
      create_symlink "${dotfiles_base}/.vim/colors" "${nvim_config_dir}/colors"
    fi
  fi

  if [ ! -d "${HOME}/.config" ]; then
    create_dir "${HOME}/.config"
  fi

  if [ -d "${dotfiles_base}/.config" ]; then
    shopt -s dotglob nullglob

    for config_dir in "${dotfiles_base}/.config"/*; do
      target_config_name=$(basename "${config_dir}")
      create_symlink "${config_dir}" "${HOME}/.config/${target_config_name}"
    done

    shopt -u dotglob nullglob
  fi

  vscode_settings_src="${dotfiles_base}/.config/Code/User/settings.json"

  if [ -f "${vscode_settings_src}" ]; then
    target_dir=""

    if [ "${is_mac}" -eq 1 ]; then
      target_dir="${HOME}/Library/Application Support/Code/User"
    fi

    if [ -n "${target_dir}" ]; then
      if [ ! -d "${target_dir}" ]; then
        create_dir "${target_dir}"
      fi
      create_symlink "${vscode_settings_src}" "${target_dir}/settings.json"
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

  echo ""
  printf "%0.s-" {1..60}
  printf "\nSetup dotfiles done!\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
