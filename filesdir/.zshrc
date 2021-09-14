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

autoload -Uz zkbd
autoload -Uz history-search-end

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

_git_desc() {
    local BRANCH="$(git describe --all --always 2>/dev/null)"

    if [[ "$BRANCH" != "" ]]; then
        echo -n "on "
        if [[ "$BRANCH" =~ "^heads/.*" ]]; then
            echo -n "%{$fg_bold[green]%}\uf126 $(echo $BRANCH | cut -c 7-)%{$reset_color%}"
        else
            echo -n "%{$fg[green]%}$BRANCH%{$reset_color%}"
        fi
    fi
}

_git_prompt_status() {
    echo -n '[ '
    echo -n "\uf067 $(git diff --staged --name-only | wc -l) "
    echo -n "\uf0ad $(git diff --name-only | wc -l) "
    echo -n "\uf128 $(git ls-files --others --exclude-standard | wc -l) "
    echo -n ']'
}

setopt prompt_subst

PROMPT='%{$fg_bold[red]%}%n%{$reset_color%}@%{$fg_bold[blue]%}%m %{$reset_color%}in %{$fg_bold[yellow]%}%3~%{$reset_color%}$GIT_DESC'$'\n'' %B$%b '
RPROMPT='$VIM$GIT_STATUS%(?.. [%{$fg_bold[red]%}%?%{$reset_color%}])'

function zle-line-init zle-keymap-select {
    VIM="${${KEYMAP/vicmd/n}/(main|viins)/i}"
    zle reset-prompt
}

precmd() {
    if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]]; then
        GIT_DESC=" $(_git_desc)"
        GIT_STATUS=" $(_git_prompt_status)"
    else
        GIT_DESC=""
        GIT_STATUS=""
    fi
}

zle -N zle-line-init
zle -N zle-keymap-select

true
