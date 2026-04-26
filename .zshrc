export ZSH=~/.oh-my-zsh

ZSH_THEME=""  # disabled — using starship

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  colored-man-pages
  history-substring-search
  yarn
  web-search
  jsontools
  node
  macos
  sudo
  docker
  fzf
)

source $ZSH/oh-my-zsh.sh

# --- Aliases ---
alias ll="ls -lAh"
alias la="ls -A"
alias ..="cd .."
alias ...="cd ../.."
alias gs="git status"
alias gd="git diff"
alias glog="git log --oneline --graph --decorate --all"
alias brewup="brew update && brew upgrade && brew cleanup"

# --- History substring search keybindings ---
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# --- fzf ---
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]   && source /opt/homebrew/opt/fzf/shell/completion.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=bg+:#1e2030,bg:#0d1117,spinner:#80aaff,hl:#80aaff,fg:#c0caf5,header:#80aaff,info:#7aa2f7,pointer:#ff9e64,marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#80aaff"

# --- iTerm2 shell integration ---
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# --- iTerm2 tab color: deep indigo ---
echo -e "\033]6;1;bg;red;brightness;30\a"
echo -e "\033]6;1;bg;green;brightness;30\a"
echo -e "\033]6;1;bg;blue;brightness;60\a"

# --- Starship prompt ---
export STARSHIP_CONFIG=~/.config/starship.toml
eval "$(starship init zsh)"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/umeshravuru/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

export NEXUS_PROXY_URL=https://artifact.intuit.com/artifactory/maven-proxy
