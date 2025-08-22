# ~/.zshrc
# ----------------------------------------------------------
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export LC_ALL="en_US.UTF-8"
setopt NO_BEEP

if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]] && \
  [[ "$TERM" != "screen" ]] && \
  [[ "$TERM" != "tmux" ]] && \
  [[ "$TERM" != "linux" ]]; then
  export COLORTERM="truecolor"
fi

export VISUAL="vim"
export EDITOR="${VISUAL}"
export GIT_EDITOR="${VISUAL}"
export FCEDIT="${VISUAL}"
alias vi="${VISUAL}"
alias vim="${VISUAL}"
alias vimdiff="${VISUAL} -d"

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=$HISTSIZE

export PATH="$HOME/.local/bin":$PATH
export UNZIP="-O cp949"
export ZIPINFO="-O cp949"

setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
zstyle ':vcs_info:git:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr ' +'
zstyle ':vcs_info:git:*' unstagedstr ' *'
zstyle ':vcs_info:git:*' untrackedstr ' ?'
zstyle ':vcs_info:git:*' formats ' (%b%m%u%c)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'

autoload -U colors && colors
# PROMPT='%F{blue}%B%5~%b%f${vcs_info_msg_0_}%# '
local prompt_string=""
if [[ -n "$SSH_CONNECTION" ]]; then
  prompt_string+='%F{yellow}%n@%m%f '
fi
prompt_string+='%(?..%F{red}[%?]%f )'
prompt_string+='%F{blue}%B%5~%b%f'
prompt_string+='${vcs_info_msg_0_}%# '

PROMPT="$prompt_string"
RPROMPT=' %*'

if [[ "$(uname)" = "Linux" ]]; then
  zshAutoDir=~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  zshHighDir=~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  [ -f $zshAutoDir ] && source $zshAutoDir
  fpath=(~/.zsh/zsh-completions/src $fpath)
  rm -f ~/.zcompdump; compinit
  [ -f $zshHighDir ] && source $zshHighDir
  fpath=($HOME/.local/bin $fpath)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244,bold'
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
  export PATH=$PATH:/usr/local/go/bin

elif [ "$(uname)" = "Darwin" ];then
  if type brew &>/dev/null; then
    zshAutoDir="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    zshHighDir="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    [ -f $zshAutoDir ] && source $zshAutoDir
    [ -f $zshHighDir ] && source $zshHighDir
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
    autoload -Uz compinit
    compinit
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244,bold'
  fi

  export PATH="/opt/homebrew/bin":$PATH
  export PATH="/usr/local/bin":$PATH

  export CLICOLOR=1
  export LSCOLORS="gxfxcxdxbxegedabagacad"
fi

ajrtm () {
  if command -v tmux &> /dev/null && \
    [ -n "$PS1" ] && [ -z "$TMUX" ] && \
    [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && \
    [[ ! "$TERM_PROGRAM" =~ vscode ]]; then
      tmux -L main -f ~/.config/tmux/tmux.conf new-session -AD -s main
  fi
}

if [ -d "$HOME/.config/zsh" ]; then
  for config_file in "$HOME/.config/zsh"/*.zsh; do
    if [ -f "$config_file" ]; then
      source "$config_file"
    fi
  done
fi
zstyle -d ':completion:*' list-colors

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# if typeset -f ajrtm > /dev/null; then
# ajrtm
# fi
