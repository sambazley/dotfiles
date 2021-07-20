# The following lines were added by compinstall
zstyle :compinstall filename '/home/user/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=5000000
SAVEHIST=5000000
setopt appendhistory nomatch notify
unsetopt autocd beep
bindkey -v
# End of lines configured by zsh-newuser-install

setopt AUTO_CONTINUE

#Case insensitive tab completion
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}'

zmodload zsh/complist
setopt menucomplete
zstyle ':completion:*' menu select=0 search
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:descriptions' format "$(print -P "%B%F{blue}")%d$(print -P "%f%b")"
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:commands' rehash 1

setopt inc_append_history
setopt share_history

setopt correct

autoload -Uz colors && colors

autoload zkbd
autoload history-search-end

zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

if [[ -f ~/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE} ]]; then
    source ~/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE}
    [[ -n ${key[Backspace]} ]] && bindkey "${key[Backspace]}" backward-delete-char
    [[ -n ${key[Insert]} ]] && bindkey "${key[Insert]}" overwrite-mode
    [[ -n ${key[Home]} ]] && bindkey "${key[Home]}" beginning-of-line
    [[ -n ${key[PageUp]} ]] && bindkey "${key[PageUp]}" up-line-or-history
    [[ -n ${key[Delete]} ]] && bindkey "${key[Delete]}" delete-char
    [[ -n ${key[End]} ]] && bindkey "${key[End]}" end-of-line
    [[ -n ${key[PageDown]} ]] && bindkey "${key[PageDown]}" down-line-or-history
    [[ -n ${key[Up]} ]] && bindkey "${key[Up]}" history-beginning-search-backward-end
    [[ -n ${key[Left]} ]] && bindkey "${key[Left]}" backward-char
    [[ -n ${key[Down]} ]] && bindkey "${key[Down]}" history-beginning-search-forward-end
    [[ -n ${key[Right]} ]] && bindkey "${key[Right]}" forward-char
fi

source ~/.profile

alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias clipc="xclip -i -sel clipboard -f | xclip -i -sel primary"
alias clipp="xclip -o -sel clipboard"
alias ssh="TERM=xterm ssh"
alias less="less -R"

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240"

ZSH_HIGHLIGHT_STYLES[command]="fg=white,bold"
ZSH_HIGHLIGHT_STYLES[alias]="fg=white,bold"

local STATUS_FIFO="/tmp/zsh_git_status"
git_get_status() {
    local STATUS="$(git status --porcelain)"

    (
    echo -n "\uf067"
    echo -n " $(echo "$STATUS" | grep '^[A-Z]' | wc -l) " #Staged
    echo -n "\uf00e"
    echo -n " $(echo "$STATUS" | grep '^\s' | wc -l) " #Unstaged
    echo -n "\uf128"
    echo -n " $(echo "$STATUS" | grep -E '^\?\?' | wc -l) " #Untracked
    ) >> "$STATUS_FIFO"
}

gitstuff() {
    [ ! -p "$STATUS_FIFO" ] && mkfifo "$STATUS_FIFO"
    (git_get_status &)

    echo -n "[ "

    local BRANCH="$(git describe --all --always 2>/dev/null)"

    if [[ "$BRANCH" != "" ]]; then
        if [[ "$BRANCH" =~ "^heads/.*" ]]; then
            echo -n "%{$fg_bold[green]%}$(echo $BRANCH | cut -c 7-)%{$reset_color%}"
        else
            echo -n "%{$fg[green]%}$BRANCH%{$reset_color%}"
        fi
        echo -n " | "
    fi

    cat "$STATUS_FIFO"

    echo -n "] "
}

function zle-line-init zle-keymap-select {
    precmd

    zle reset-prompt
}

precmd() {
    PROMPT="[%{$fg_bold[red]%}%n%{$reset_color%}@%{$fg_bold[blue]%}%m %{$fg[green]%}%1~%{$reset_color%}]%{$fg_bold[magenta]%}$%{$reset_color%} "

    local VIM="${${KEYMAP/vicmd/N}/(main|viins)/I}"

    local ERR="%{$fg_bold[red]%}%?%{$reset_color%}"
    local S=":)"
    local F="[$ERR] :("
    local SF="%(?.$S.$F)"
    RPROMPT="$VIM $([[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] && gitstuff)$SF"
}

zle -N zle-line-init
zle -N zle-keymap-select

true
