#!/usr/bin/env bash

show_script_info() { # {{{
  echo "basename: $(basename "$0")"
  echo "dirname : $(dirname "$0")"
  echo "pwd     : $(pwd)"
  echo ""
} # }}}

initialize_variables() { # {{{
  is_linux=$([[ "$(uname -a)" =~ "Linux" ]] && echo 1 || echo 0)
  is_wsl=$(grep -qiE "microsoft|wsl" /proc/version && echo 1 || echo 0)
  is_mac=$([ "$(uname)" = "Darwin" ] && echo 1 || echo 0)

  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m' # No Color
}              # }}}

detect_package_manager() { # {{{
  PM=""
  if [ "${is_linux:-0}" -eq 1 ]; then
    if command -v apt-get &>/dev/null; then PM="apt"; fi
  fi
  if [ -z "$PM" ]; then
    echo "${RED}지원하는 패키지 매니저(apt)를 찾을 수 없습니다.${NC}"
    exit 1
  fi
  msg "$([ "$PM" = "apt" ] && warn "Ubuntu (APT)") 환경 감지됨"
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
  echo -e "\n\n${GREEN}--- $1 ---${NC}"
} # }}}

warn() { # {{{
  echo -e "${YELLOW}Warning: $1${NC}"
} # }}}

ubuntu_update_system() { # {{{
  if [ "$PM" = "apt" ]; then
    sudo apt update -y && sudo apt upgrade -y

    if [ "${is_wsl:-0}" -ne 1 ]; then
      if command -v ubuntu-drivers &>/dev/null; then
        sudo ubuntu-drivers autoinstall
      fi
    fi
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
      systemd-resolved ufw sudo \
      language-pack-ko ibus-hangul \
      build-essential coreutils util-linux \
      curl wget gdebi \
      git bash zsh tmux vim-gtk3 \
      clang lldb clang-format clangd universal-ctags \
      python3-full python3-pip python3-venv pipx \
      zip unzip 7zip-standalone \
      wl-clipboard xclip x11-apps \
      ripgrep fd-find tree htop entr jq ffmpeg mat2 \
      exfatprogs ntfs-3g btrfs-progs

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

install_javascript_runtime() { # {{{
  install_node() {
    if command -v nvm &>/dev/null; then
      if nvm ls | grep -q "lts/*"; then
        return 0
      fi
    fi

    # Install nvm without modifying the profile file (prevent auto-appending to .zshrc)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash

    # Manually load nvm to use it immediately within this script
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install --lts
    nvm use --lts
    npm install -g npm@latest
  }

  install_deno() {
    curl -fsSL https://deno.land/install.sh | sh
  }

  install_node
  install_deno
} # }}}

install_global_packages() { # {{{
  # Manually load nvm to use it immediately within this script
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  if command -v npm &>/dev/null; then
    corepack enable

    npm install -g \
      @biomejs/biome \
      eslint \
      prettier

  else
    warn "npm not found. Skipping JavaScript-based tools."
  fi

  if command -v pipx &>/dev/null; then
    pipx ensurepath

    local python_apps=(ruff pre-commit "yt-dlp[default]" "python-lsp-server[all]")
    for app in "${python_apps[@]}"; do
      pipx install "$app" --force
    done
  else
    warn "pipx not found. Skipping Python-based tools."
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

configure_git() { # {{{
  if command -v git &>/dev/null; then
    if [ -f ~/.gitignore_global ]; then
      git config --global core.excludesfile ~/.gitignore_global
    fi

    git config --global core.eol native
    git config --global core.autocrlf input
  fi
} # }}}

ubuntu_setup_secure_dns() { # {{{
  if [ "$PM" = "apt" ]; then
    CONF_FILE="/etc/systemd/resolved.conf"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)

    if grep -q "DNSOverTLS=yes" "$CONF_FILE"; then
      return 0
    fi

    sudo cp -fv "$CONF_FILE" "${CONF_FILE}.${TIMESTAMP}.bak"

    RESOLVED_CONFIG="[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
DNSOverTLS=yes
DNSSEC=yes
FallbackDNS=
Domains=~.
Cache=yes
MulticastDNS=no
LLMNR=no"

    echo "$RESOLVED_CONFIG" | sudo tee "$CONF_FILE" >/dev/null

    sudo systemctl restart systemd-resolved

    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    sudo ufw default allow outgoing

    sudo ufw deny out 53/udp
    sudo ufw deny out 53/tcp
    sudo ufw deny out 53/udp6
    sudo ufw deny out 53/tcp6

    echo "y" | sudo ufw enable
    sudo ufw reload
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
      warn "Reboot skipped."
      break
      ;;
    *)
      warn "Invalid input. Please enter 'y' or 'n'."
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
  )

  tasks+=(
    install_javascript_runtime
    install_global_packages
  )

  if [ "${is_wsl:-0}" -ne 1 ]; then
    tasks+=(ubuntu_update_snapd_packages)
  fi

  tasks+=(
    upgrade_packages
    make_default_directories
    ubuntu_make_RALT_to_HNGL
    configure_git
  )

  if [ "${is_wsl:-0}" -ne 1 ]; then
    tasks+=(ubuntu_setup_secure_dns)
  fi

  tasks+=(
    change_shell_to_zsh
    perform_reboot
  )

  for task in "${tasks[@]}"; do
    if declare -f "$task" >/dev/null; then
      msg "$task"
      "$task"
    else
      warn "Warning: Function '$task' not found."
    fi
  done
} # }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
