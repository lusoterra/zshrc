# .zshrc - do not use this abomination!
# "Should" work on:
# - Arch Linux
# - Alpine Linux
# - Gentoo Linux
# - Debian GNU/Linux
# - OpenBSD
# - FreeBSD
# - macOS

source_first_available() { for f in "${@}"; do [[ -f "$f" ]] && source "$f" && return; done }

# source p10k if it exists, otherwise use my old ass prompt from like 2022
if [[ ( -f "/usr/share/zsh/plugins/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme" || \
    -f "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme" ) && \
    -f "${ZDOTDIR:-~}/.p10k.zsh" ]]
then
    # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
    # Initialization code that may require console input (password prompts, [y/n]
    # confirmations, etc.) must go above this block; everything else may go below.
    if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
      	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
    fi

    # source the theme
    source_first_available \
        /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme \
        /usr/share/zsh/plugins/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
    
    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    source "${ZDOTDIR:-~}/.p10k.zsh"

    # zmx
    prompt_my_zmx_session() {
        if [[ -n $ZMX_SESSION ]]; then
            p10k segment -b '%k' -f '%f' -t "[zmx: $ZMX_SESSION]"
        fi
    }
    POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS+=my_zmx_session
else
    if (( UID == 0 )); then
        if [[ $HOST = mars || $HOST = saturn ]]; then # gen2 inspired prompt on my root user on my PC
            PS1='%F{red}%m%f %F{blue}%~ %#%f '
        else # root user on servers
            PS1='%B%F{red}[%F{blue}%n%F{white}@%F{green}%M%F{red}]%F{white}:%F{magenta}%~%F{yellow}#%f%b '
        fi
    else # non root users on servers
        PS1='%B%F{red}[%F{blue}%n%F{white}@%F{green}%M%F{red}]%F{white}:%F{magenta}%~%F{yellow}%%%f%b '
    fi
    if [[ -n $ZMX_SESSION ]]; then # zmx
        export PS1="[zmx: $ZMX_SESSION] ${PS1}"
    fi
fi

# sudo/doas detection
if command -v sudo >/dev/null 2>&1; then
    SUDOBIN=sudo
elif command -v doas >/dev/null 2>&1; then
    SUDOBIN=doas
else
    SUDOBIN=
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
    git commit -m "${@}"
}

fzf-open-file() { # open file on default program using fzf
    local file
    file=$(fd --type f --hidden --exclude .git . | fzf) || return
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "./${file#./}" >/dev/null 2>&1
    else
        open "./${file#./}" >/dev/null 2>&1
    fi
}

REALRM="$(command -v rm)" # ass
rm() { # trash-cli only to be used on mars, not by root or sudo
    if [[ $HOST == mars && $EUID -ne 0 && -z $SUDO_USER ]]; then
        if command -v trash-put >/dev/null 2>&1; then
            trash-put "${@}"
        elif command -v trash >/dev/null 2>&1; then
            trash "${@}"
        else
            command rm "${@}"
        fi
    else
        command rm "${@}"
    fi
}

REALNIGHTCORE="$(command -v nightcore)" # ass 2
nightcore() {
    command nightcore \
        --autorename \
        --quiet \
        --cover "$HOME/Lossless Nightcore/oneone's High Quality Nightcore/cover.png" \
        --tag-template "$HOME/Lossless Nightcore/pack-template.txt" "$@"
}

gm++() {
    local last n
    last=$(git log -1 --pretty=%s 2>/dev/null)
    n=${last%%[!0-9]*}                # leading digits only
    n=$(( 10#${n:-0} + 1 ))
    git add -A && git commit -S -m "$n${1:+ $1}" && git push
}

lsd() { # for some reason lsd --icon=auto is retarded doesn't know what a tty is
    if [[ -n "$WAYLAND_DISPLAY" || -n "$DISPLAY" || -n "$SSH_TTY" ]]; then
        command lsd "${@}"
    else
        command lsd "${@}" --icon=never
    fi
}

command -v zoxide >/dev/null 2>&1 && alias cd="z"
command -v moor   >/dev/null 2>&1 && alias less="moor"
command -v advcp  >/dev/null 2>&1 && alias cp="advcp -gr" || alias cp="cp -r"
command -v advmv  >/dev/null 2>&1 && alias mv="advmv -g"
[[ -n "$SUDOBIN" ]] && alias sudo="$SUDOBIN " doas="$SUDOBIN "
[[ $(ip -V 2>&1) == "ip utility,"* ]] && alias ip='command ip -c'
alias \
    '\nightcore'="$REALNIGHTCORE" \
           '\rm'='[ -n "$SUDO_USER" ] && [ $EUID != 0 ] && command rm || "$REALRM"' \
              ls="lsd --group-directories-first --date=relative" \
              ll="lsd --group-directories-first --date=relative -lAFh" \
              la="lsd --group-directories-first --date=relative -laFh" \
               l="lsd --group-directories-first --date=relative -lFh" \
              l.="lsd --group-directories-first --date=relative -lhd .[^.]*" \
              LL="lsd --reverse --date=relative -lAFh --total-size --sort size" \
              ..="cd .." \
             YAY="yay -Syu --devel" \
            NCDU="$(command -v sudo || command -v doas) ncdu --exclude /mnt --exclude /proc --exclude /sys --exclude /dev --exclude /run --exclude /tmp /" \
           mkdir="mkdir -p" \
              dp="d dolphin ." \
              dk="d konsole" \
              cx="chmod +x" \
             bbl="bubbleload" \
             vim="micro" \
              vi="micro" \
            nano="micro" \
              ed="micro" \
            nvim="micro" \
           emacs="micro" \
             ytc="yt-dlp --write-thumbnail --skip-download" \
             yt3="yt-dlp -f 251 -x --audio-format opus --embed-metadata --embed-thumbnail" \
             gdl="gallery-dl" \
              ez="exec zsh" \
              gs="git status" \
              gd="git diff" \
              gp="git push" \
              ga="git add" \
              gl="git log" \
               h="history 0" \
             xxd="tinyxxd" \
          rclone="rclone --progress" \
           rsync="rsync -avzhP" \
             adb='HOME="$XDG_DATA_HOME"/android adb' \
             ufw="sudo ufw" \
            grep='grep --color=auto' \
            diff='diff --color=auto' \
           hugos="hugo server --noHTTPCache --gc --minify --disableFastRender --buildDrafts" \
              fd="$(command -v fd || command -v fdfind) --hidden --exclude .git" \
             cat="$(command -v bat || command -v batcat) --plain --theme TwoDark --paging never" \
             nyx='sudo -u $(for u in tor debian-tor _tor; do id -u "$u" &>/dev/null && { echo "$u"; break; }; done) nyx' \
            wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"' \
          ffmpeg="ffmpeg -hide_banner" \
         ffprobe="ffprobe -hide_banner" \
          ffplay="ffplay -hide_banner"

# xdg env
XDG_DATA_HOME=$HOME/.local/share
XDG_CONFIG_HOME=$HOME/.config
XDG_STATE_HOME=$HOME/.local/state
XDG_CACHE_HOME=$HOME/.cache

# wordchars
WORDCHARS="*[]~$^(){}<>" # separators: ? & % # = ; , + @ ! (removed from words)

# autoload hooks
autoload -Uz add-zsh-hook

# gnupg stuff
export GNUPGHOME="$XDG_DATA_HOME/gnupg" # ssh never sees /etc/environment.d, so set it here too
function my_gpg_init() {
    export GPG_TTY="/dev/$(ps -p $$ -o tty= | tr -d ' ')"
}
if [[ -z ${SSH_TTY:-} && ( -n ${WAYLAND_DISPLAY:-} || -n ${DISPLAY:-} ) ]]; then
    add-zsh-hook precmd my_gpg_init
fi
[ -n $SSH_TTY ] && export GPG_TTY=$SSH_TTY

# path
path+=(
    "$HOME/.local/bin"
    "$HOME/.local/share/npm/bin"
    "/opt/cuda/bin/"
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
setopt autocd

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
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
bindkey '^[[3;5~' kill-word        # ctrl delete
zle -N fzf-open-file                # custom function
bindkey '^O' fzf-open-file          # custom function
bindkey "^[[F" end-of-line
bindkey "^[[H" beginning-of-line
bindkey '^Z'   undo
bindkey '^Y'   redo
bindkey '^X'   push-line-or-edit

bindkey '^[[H'  beginning-of-line
bindkey '^[OH'  beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[OF'  end-of-line
bindkey '^[[4~' end-of-line

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[5~' up-line-or-beginning-search
bindkey '^[[6~' down-line-or-beginning-search

paste-from-clipboard() {
    local clip
    if command -v wl-paste >/dev/null 2>&1; then
        clip=$(wl-paste --no-newline 2>/dev/null)
    elif command -v pbpaste >/dev/null 2>&1; then
        clip=$(pbpaste 2>/dev/null)
    else
        clip=$(xclip -o -selection clipboard 2>/dev/null || xsel -ob 2>/dev/null)
    fi
    LBUFFER+="$clip"
}
zle -N paste-from-clipboard
bindkey '^[[2~' paste-from-clipboard

# LOAD PLUGINS
[ -f "$ZDOTDIR/_trash-put" ] && source "$ZDOTDIR/_trash-put"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
source_first_available \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source_first_available \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
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
ZSH_HIGHLIGHT_PATTERNS+=('\rm' 'fg=cyan') # fix \rm alias being detected as unknown token
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
