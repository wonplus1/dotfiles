#!/usr/bin/env bash

show_script_info() { # {{{
  echo "basename: $(basename "$0")"
  echo "dirname : $(dirname "$0")"
  echo "pwd     : $(pwd)"
  echo ""
} # }}}

initialize_variables() { # {{{
  is_linux=$([[ "$(uname -a)" =~ "Linux" ]] && echo 1 || echo 0)
  is_wsl=$([ -d "/mnt/c/Windows/System32" ] && echo 1 || echo 0)
  is_mac=$([ "$(uname)" = "Darwin" ] && echo 1 || echo 0)
} # }}}

detect_package_manager() { # {{{
  PM=""
  if [ "${is_mac:-0}" -eq 1 ]; then
    if command -v brew &>/dev/null; then
      PM="brew"
    else
      xcode-select --install || true
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
      PM="brew"
    fi
  fi
  if [ "${is_linux:-0}" -eq 1 ]; then
    if command -v apt-get &>/dev/null; then PM="apt"; fi
  fi
  if [ -z "$PM" ]; then
    echo "지원하는 패키지 매니저(apt, brew)를 찾을 수 없습니다."
    exit 1
  fi
  msg "$([ "$PM" = "brew" ] && echo "macOS (Homebrew)" || echo "Ubuntu (APT)") 환경 감지됨"
} # }}}

prelude() { # {{{
  show_script_info
  initialize_variables
  detect_package_manager
} # }}}

install_packages() { # {{{
  if [ "$PM" = "apt" ]; then
    sudo apt install --ignore-missing --fix-missing --yes "$@"
  fi
} # }}}

msg() { # {{{
  echo -e "\n\n--- $1 ---"
} # }}}

ubuntu_update_system() { # {{{
  if [ "$PM" = "apt" ]; then
    sudo apt update -y && sudo apt upgrade -y
    sudo ubuntu-drivers autoinstall
  fi
} # }}}

ubuntu_setup_locale() { # {{{
  if [ "$PM" = "apt" ]; then
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8
  fi
} # }}}

ubuntu_install_zsh_plugins() { # {{{
  if [ "$PM" = "apt" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-completions ~/.zsh/zsh-completions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
  fi
} # }}}

ubuntu_install_basic_packages() { # {{{
  if [ "$PM" = "apt" ]; then
    install_packages \
      language-pack-ko ibus-hangul \
      build-essential coreutils util-linux \
      curl wget gdebi \
      git bash zsh tmux vim-gtk3 \
      clang lldb clang-format clangd universal-ctags \
      python3-full python3-pip python3-venv pipx \
      zip unzip 7zip-standalone \
      wl-clipboard xclip x11-apps \
      ripgrep fd-find tree htop entr jq ffmpeg

    sudo update-alternatives --set cc /usr/bin/clang
    sudo update-alternatives --set c++ /usr/bin/clang++

    if [ "${is_wsl:-0}" -ne 1 ]; then
      install_packages \
        smplayer alsa-utils alacritty
    fi

    ubuntu_install_zsh_plugins

    :
  fi
} # }}}

ubuntu_install_docker() { # {{{
  if [ "$PM" = "apt" ]; then
    if command -v docker &>/dev/null; then
      return 0
    fi

    install_packages ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
  fi
} # }}}

ubuntu_install_nerd_font() { # {{{
  if [ "$PM" = "apt" ]; then
    declare -A FONTS
    if ! fc-list | grep -i "JetBrainsMono Nerd Font"; then
      FONTS["JetBrainsMono"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
    fi

    if [ ${#FONTS[@]} -eq 0 ]; then
      return 0
    fi

    if ! command -v unzip &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y unzip
    fi

    BASE_FONT_DIR="$HOME/.local/share/fonts"

    for FONT_NAME in "${!FONTS[@]}"; do
      FONT_URL="${FONTS[$FONT_NAME]}"
      FONT_DIR="$BASE_FONT_DIR/$FONT_NAME"

      mkdir -pv "$FONT_DIR"

      if command -v curl &>/dev/null; then
        curl -L "$FONT_URL" -o "/tmp/$FONT_NAME.zip"
      elif command -v wget &>/dev/null; then
        wget -O "/tmp/$FONT_NAME.zip" "$FONT_URL"
      else
        continue
      fi

      if [ ! -f "/tmp/$FONT_NAME.zip" ]; then
        continue
      fi

      unzip -o "/tmp/$FONT_NAME.zip" -d "$FONT_DIR"

      find "$FONT_DIR" -type f ! -name "*.ttf" ! -name "*.otf" -delete

      rm "/tmp/$FONT_NAME.zip"
    done

    sudo fc-cache -fv
  fi
} # }}}

macOS_run_Brewfile() { # {{{
  if [ "$PM" = "brew" ]; then
    brew bundle --file=~/.dotfiles/Brewfile
  fi
} # }}}

install_node() { # {{{
  if command -v nvm &>/dev/null; then
    if nvm ls | grep -q "lts/*"; then
      return 0
    fi
  fi

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

  nvm install --lts
  nvm use --lts
  npm install -g npm@latest
} # }}}

install_global_packages() { # {{{
  corepack enable
  pipx ensurepath
  source ~/.zshrc

  npm install -g \
    @biomejs/biome \
    eslint \
    prettier

  if [ "$PM" = "apt" ]; then
    pipx install ruff pre-commit --force
  fi
} # }}}

ubuntu_update_snapd_packages() { # {{{
  if [ "$PM" = "apt" ]; then
    install_packages snapd
    sudo snap install snap-store
    sudo snap refresh snap-store
    sudo snap refresh --list
    sudo snap refresh
  fi
} # }}}

upgrade_packages() { # {{{
  if [ "$PM" = "apt" ]; then
    sudo apt full-upgrade -y
    sudo apt autoremove -y
  else
    brew update && brew outdated
    brew upgrade && brew cleanup
  fi
} # }}}

make_default_directories() { # {{{
  mkdir -pv ~/Downloads
  mkdir -pv ~/Documents
} # }}}

ubuntu_make_RALT_to_HNGL() { # {{{
  if [ "${is_linux}" -eq 1 ] && [ "${is_wsl}" -ne 1 ]; then
    if [ -f /etc/os-release ] && grep -qi '^ID=ubuntu' /etc/os-release; then
      TARGET_FILE="/usr/share/X11/xkb/keycodes/evdev"

      if ! [ -f "$TARGET_FILE" ]; then
        exit 0
      fi
      if grep -q "^[[:space:]]*<HNGL>[[:space:]]*=[[:space:]]*108;" "$TARGET_FILE"; then
        exit 0
      fi

      sudo bash <<SUDO_SCRIPT
  cp "${TARGET_FILE}" "${TARGET_FILE}.$(date +%Y%m%d-%H%M%S).bak"
  # 1. <RALT> = 108; 줄을 주석 처리하고 바로 아래 <HNGL> = 108; 추가
  sed -i '/^[[:space:]]*<RALT>[[:space:]]*=[[:space:]]*108;/c\// <RALT> = 108;\n<HNGL> = 108;' "${TARGET_FILE}"
  # 2. 기존 <HNGL> = 130; 줄을 주석 처리
  sed -i 's/^[[:space:]]*<HNGL>[[:space:]]*=[[:space:]]*130;/ \/\/ <HNGL> = 130;/g' "${TARGET_FILE}"
SUDO_SCRIPT
    fi
  fi
} # }}}

macOS_setup_user_key_mapping() { # {{{
  if [ "${is_mac}" -eq 1 ]; then
    if sudo launchctl list | grep -q "userkeymapping"; then
      sudo launchctl unload /Library/LaunchDaemons/userkeymapping.plist 2>/dev/null || true
    fi
    if [ -f "/Library/LaunchDaemons/userkeymapping.plist" ]; then
      sudo mv -fv "/Library/LaunchDaemons/userkeymapping.plist" "${backup_dir}/userkeymapping.plist.$(date +"%Y%m%d_%H%M%S").bak"
    fi
    if [ -f "/Users/Shared/bin/userkeymapping" ]; then
      mv -fv "/Users/Shared/bin/userkeymapping" "${backup_dir}/userkeymapping.$(date +"%Y%m%d_%H%M%S").bak"
    fi

    # Make right-command key to F18 {{{

    # How to delete previous setup
    # sudo rm /Library/LaunchDaemons/userkeymapping.plist
    # sudo rm /Users/Shared/bin/userkeymapping
    # sudo launchctl unload /Library/LaunchDaemons/userkeymapping.plist 2>/dev/null || true

    mkdir -pv /Users/Shared/bin
    printf '%s\n' '#!/bin/sh' \ 'hidutil property --set '"'"'{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000e7,"HIDKeyboardModifierMappingDst":0x70000006d},{"HIDKeyboardModifierMappingSrc":0x700000090,"HIDKeyboardModifierMappingDst":0x70000006d}]}'"'" \  >/Users/Shared/bin/userkeymapping
    chmod 755 /Users/Shared/bin/userkeymapping

    printf '%s\n' \
      '<?xml version="1.0" encoding="UTF-8"?>' \
      '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
      '<plist version="1.0">' \
      '  <dict>' \
      '    <key>Label</key>' \
      '    <string>userkeymapping</string>' \
      '    <key>ProgramArguments</key>' \
      '    <array>' \
      '      <string>/Users/Shared/bin/userkeymapping</string>' \
      '    </array>' \
      '    <key>RunAtLoad</key>' \
      '    <true/>' \
      '  </dict>' \
      '</plist>' |
      sudo tee /Users/Shared/bin/userkeymapping.plist >/dev/null

    sudo mv /Users/Shared/bin/userkeymapping.plist /Library/LaunchDaemons/userkeymapping.plist
    sudo chown root /Library/LaunchDaemons/userkeymapping.plist
    sudo launchctl load /Library/LaunchDaemons/userkeymapping.plist
    # }}}
  fi
} # }}}

configure_git() { # {{{
  if command -v git &>/dev/null; then
    if [ -f ~/.gitignore_global ]; then
      git config --global core.excludesfile ~/.gitignore_global
    fi

    git config --global core.eol native
    git config --global core.autocrlf input
  fi
} # }}}

change_shell_to_zsh() { # {{{
  ZSH_PATH=$(command -v zsh)
  if [ -n "${ZSH_PATH}" ]; then
    chsh -s "${ZSH_PATH}"
  fi
} # }}}

perform_reboot() { # {{{
  while true; do
    read -rp "Do you want to reboot (y/n)? " answer
    case "$answer" in
    [Yy]*)
      if [ "${is_wsl}" -eq 1 ]; then
        wsl.exe --shutdown

      elif [ "${is_linux}" -eq 1 ]; then
        systemctl reboot

      elif [ "${is_mac}" -eq 1 ]; then
        sudo shutdown -r now
      fi
      break
      ;;
    [Nn]*)
      echo "Reboot skipped."
      break
      ;;
    *)
      echo "Invalid input. Please enter 'y' or 'n'."
      ;;
    esac
  done
} # }}}

main() { # {{{
  prelude

  local -a tasks=(
    ubuntu_update_system
    ubuntu_setup_locale
    ubuntu_install_basic_packages
    ubuntu_install_docker
    ubuntu_install_nerd_font
    macOS_run_Brewfile
  )

  tasks+=(
    install_node
    install_global_packages
  )

  if [ "${is_wsl:-0}" -ne 1 ]; then
    tasks+=(ubuntu_update_snapd_packages)
  fi

  tasks+=(
    upgrade_packages
    make_default_directories
    ubuntu_make_RALT_to_HNGL
    macOS_setup_user_key_mapping
    configure_git
    change_shell_to_zsh
    perform_reboot
  )

  for task in "${tasks[@]}"; do
    if declare -f "$task" >/dev/null; then
      msg "$task"
      "$task"
    else
      echo "Warning: Function '$task' not found."
    fi
  done
} # }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
