# source p10k if it exists, otherwise use my old ass prompt from like 2022
if [[ -f "/usr/share/zsh/plugins/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme" && -f "${ZDOTDIR:-~}/.p10k.zsh" ]]; then
    # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
    # Initialization code that may require console input (password prompts, [y/n]
    # confirmations, etc.) must go above this block; everything else may go below.
    if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
      	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
    fi

    # source the theme
    source /usr/share/zsh/plugins/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme # AUR: zsh-theme-powerlevel10k-git
    
    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    source "${ZDOTDIR:-~}/.p10k.zsh"
else
    if (( UID == 0 )); then
        if [[ $HOST = mars ]]; then # gen2 inspired prompt on my root user on my PC
            PS1='%F{red}%m%f %F{blue}%~ %#%f '
        else # root user on servers
            PS1='%B%F{red}[%F{blue}%n%F{white}@%F{green}%M%F{red}]%F{white}:%F{magenta}%~%F{yellow}#%f%b '
        fi
    else # non root users on servers
        PS1='%B%F{red}[%F{blue}%n%F{white}@%F{green}%M%F{red}]%F{white}:%F{magenta}%~%F{yellow}%%%f%b '
    fi
fi

# FUNCTIONS AND ALIASES
d() { # daemonize in the CLI
    nohup "${@}" >/dev/null 2>&1 </dev/null &
    disown
}

hh() { # history grep
    history 0 | grep "${@}"
}

gm() { # easy commit messages for simple stuff
    git commit -m "${*}"
}

fzf-open-file() { # open file on default program using fzf
    local file
    file=$(fd --type f --hidden --exclude .git . | fzf) || return
    xdg-open "./${file#./}" >/dev/null 2>&1
}

brave-me() { # messy way of doing split tunneling for brave
    mullvad-exclude brave-origin --user-data-dir="$(mktemp -d)" --incognito --new-window "${@}"
}

lsd() { # for some reason lsd --icon=auto is retarded doesn't know what a tty is
    if [[ -n "$WAYLAND_DISPLAY" || -n "$DISPLAY" || -n "$SSH_TTY" ]]; then
        command lsd "${@}"
    else
        command lsd "${@}" --icon=never
    fi
}

[[ $HOST == mars && $EUID -ne 0 ]] && alias rm="trash-put"
command -v zoxide >/dev/null 2>&1  && alias cd="z"
command -v advcp >/dev/null 2>&1   && alias cp="advcp -gr" || alias cp="cp -r"
command -v advmv >/dev/null 2>&1   && alias mv="advmv -g"
alias ls="lsd --group-directories-first --date=relative" \
      ll="lsd --group-directories-first --date=relative -lAFh" \
      la="lsd --group-directories-first --date=relative -laFh" \
       l="lsd --group-directories-first --date=relative -lFh" \
      LL="lsd --reverse --date=relative -lAFh --total-size --sort size" \
     YAY="yay -Syu --devel" \
   mkdir="mkdir -p" \
      cx="chmod +x" \
     vim="micro" \
     ytc="yt-dlp --write-thumbnail --skip-download" \
     yt3="yt-dlp -f 251 -x --audio-format opus --embed-metadata --embed-thumbnail" \
      ez="exec zsh" \
      gs="git status" \
      gd="git diff" \
      gp="git push" \
      ga="git add" \
      gl="git log" \
       h="history 0" \
  rclone="rclone --progress" \
     adb='HOME="$XDG_DATA_HOME"/android adb' \
     ufw="sudo ufw" \
      ip="ip -c" \
  pacman="sudo pacman" \
    grep='grep --color=auto' \
    diff='diff --color=auto' \
   hugos="hugo server --noHTTPCache --gc --minify --disableFastRender --buildDrafts" \
      fd="$(command -v fd || command -v fdfind) --hidden --exclude .git" \
     cat="$(command -v bat || command -v batcat) --plain --theme TwoDark --paging never" \
     nyx='sudo -u $(for u in tor debian-tor _tor; do id -u "$u" &>/dev/null && { echo "$u"; break; }; done) nyx' \
    wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"' \
  ffmpeg="ffmpeg -hide_banner" \
    sudo="sudo " \
    doas="doas "

# wordchars
WORDCHARS="*?[]~&!#$%^(){}<>" # WORDCHARS="*?_-[]~=&!#$%^(){}<>"

# editor
export EDITOR="micro"

# path
path+=(
    "$HOME/.local/bin"
    "$HOME/.local/share/npm/bin"
)

# history on cache
HISTSIZE=10000
SAVEHIST=10000
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/history"
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# other options
setopt interactive_comments

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/zcompdump-"$ZSH_VERSION"
_comp_options+=(globdots) # Include hidden files.
compdef _precommand mullvad-exclude # fix mullvad-exclude command tab complete

# fix pasting urls like youtube links when downloading with yt-dlp
autoload -Uz url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

# KEYBINDS
bindkey '^?' backward-delete-char   # IDK fix backspace ig
bindkey '^H' backward-kill-word     # ctrl backspace
bindkey '^[[1;5D' backward-word     # Ctrl + Left
bindkey '^[[1;5C' forward-word      # Ctrl + Right
bindkey '^[[3~' delete-char         # fix del key
zle -N fzf-open-file                # custom function
bindkey '^O' fzf-open-file          # custom function
bindkey "^[[F" end-of-line
bindkey "^[[H" beginning-of-line

# LOAD PLUGINS
[ -f "$ZDOTDIR/_trash-put" ] && source "$ZDOTDIR/_trash-put"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
source_first_available() { for f in "${@}"; do [[ -f "$f" ]] && source "$f" && return; done }
source_first_available \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source_first_available \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
z() { [[ -f "$1" || -L "$1" ]] && builtin cd -- "${1:h}" || __zoxide_z "${@}" }

# ZSH HIGHLIGHT COLOURS
# fix for sudo/doas aliased to "sudo " not being recognized as precommand (1st world problem)
# I gave up on underline and settled with bold because it adds an underline to the space after sudo
# if i try to fix this then the command 'sudoedit' or anythign beginning with sudo splits into two
# colours which looks even worse
ZSH_HIGHLIGHT_HIGHLIGHTERS+=(pattern)
ZSH_HIGHLIGHT_PATTERNS+=('(#s)sudo ' 'fg=magenta,bold')
ZSH_HIGHLIGHT_PATTERNS+=('(#s)doas ' 'fg=magenta,bold')
ZSH_HIGHLIGHT_PATTERNS+=('(#s)sudo(#e)' 'fg=magenta,bold')
ZSH_HIGHLIGHT_PATTERNS+=('(#s)doas(#e)' 'fg=magenta,bold')
# other colours
ZSH_HIGHLIGHT_STYLES[precommand]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[command]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=blue'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[function]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'

# fzf
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_DEFAULT_COMMAND='fd --hidden --exclude .git'

# pager
command -v moor >/dev/null 2>&1 && \
    export PAGER="moor" \
    export MANPAGER="moor"

# cool logo...
if [[ ( -z "$SKIP_FASTFETCH" && $UID != 0 ) || ( -z "$SKIP_FASTFETCH" && -n $SSH_TTY && $UID = 0 ) ]]; then
    fastfetch --config none -l small --structure title:os:kernel:uptime:packages:shell:memory --pipe false
    export SKIP_FASTFETCH=1
fi
