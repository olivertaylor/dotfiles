# OPTIONS
# ----------------------------------------------------------------------------

setopt HIST_IGNORE_DUPS           # Ignore duplication command history list
setopt SHARE_HISTORY              # Share history data between sessions
setopt APPEND_HISTORY             # New sessions append history data rather than overwrite
setopt EXTENDED_HISTORY           # save each command’s beginning timestamp
setopt NOCLOBBER                  # Disallow overwriting of files using >
setopt complete_aliases           # Don't expand aliases _before_ completion has finished
set    completion-ignore-case on  # Ignore case for tab completion
set    show-all-if-ambiguous on   # Show all suggestions after pressing tab once instead of twice

HISTFILE=~/.zsh_history
SAVEHIST=10000
HISTSIZE=10000

export PATH=$PATH:~/code/dotfiles/bin:~/code/text-utilities:~/code/other-repos/fzf-fs:/Applications/Racket\ v6.7/bin
export EDITOR=vim
export DOT=~/code/dotfiles

# encoding
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# enable completion
autoload -U compinit
compinit -C

# Arrow driven menu for complete
zstyle ':completion:*' menu select

## case-insensitive (all),partial-word and then substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

# PROMPT
# ----------------------------------------------------------------------------

setopt prompt_subst

# Setup the variables used in the prompt
# color start = %F{1}
# color end   = %f
if [ -n "$SSH_CLIENT" ]; then
    local myUsermachine='%F{3}%n@%m:%f'
fi
myDir='%F{4}%~%f'
myBackgroundjobs='%F{1}%(1j. (%j jobs).)%f'
myPrompt='%F{5}❯ %f'
italics=%{$'\e[3m'%}
italicsoff=%{$'\e[23m'%}

# The Prompt
PROMPT='${myUsermachine}${myDir}${myBackgroundjobs} ${myPrompt}'

# ALIASES
# ----------------------------------------------------------------------------

alias evrc="vim $DOT/vim/vimrc"
alias ezrc="vim $DOT/zshrc && source $DOT/zshrc"

bindkey "^K" history-beginning-search-backward
bindkey "^J" history-beginning-search-forward

alias rm="rm -i"
alias mv="mv -i"
alias l='ls -1p'
alias la="ls -AohGp"
alias ..="cd .."
alias ax="chmod a+x"
alias cpwd='pwd|tr -d "\n"|pbcopy'
alias cdf='cd $(osascript -e "tell application \"Finder\" to POSIX path of (target of window 1 as alias)")'
alias batt="pmset -g batt"
alias server='python -m SimpleHTTPServer 8000'
alias unquarantine='xattr -d com.apple.quarantine'
alias pbp="pbpaste"
alias pbc="pbcopy"
alias gs='git status -sb'
alias gl='git lg'

alias tmn='tmux new -s `basename $PWD`'
alias tma='tmux attach -t '
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t '

tmh() {
echo "
    tmn - New tmux session
    tma - Attach tmux session
    tml - List tmux sessions
    tmk - Kill tmux session
" }

# FUNCTIONS
# ----------------------------------------------------------------------------

myip() { (awk '{print $2}' <(ifconfig en0 | grep 'inet ')); }

size(){
    if test -z $1; then
        echo "File size. USAGE: size file" >&2
        return 1
    else
        du -sh "$1"
        return 0
    fi
}

rt(){
    if test -z $1; then
        echo "Move file to trash. USAGE: rt file" >&2
        return 1
    else
        mv $1 ~/.Trash;
        return 0
    fi
}

cfp(){
    if test -z $1; then
        echo "Copy file path. USAGE: cfp file" >&2
        return 1
    else
        echo "$PWD/$1" | pbcopy && echo "File-Path is on the clipboard"
        return 0
    fi
}

function makepdf(){
    if test -z $3; then
        echo "USAGE: makepdf format /source /destination" >&2
        return 1
    else
        pandoc --smart -f $1 -t html < $2 | prince -s ~/code/print_css/print.css - -o $3
        return 0
    fi
}

# Define a list of todo files
if [ "$HOST" = 'Oliver-Mini.local' ]; then
export TODOS="\
~/Dropbox/operations/ingenuity.text \
~/Dropbox/operations/grand_plan.txt \
~/Dropbox/operations/project_software.txt \
~/Dropbox/operations/producer_evaluations/evaluations.text"
else
export TODOS"\
~/Dropbox/life.text \
~/Documents/screenwriting/career/writing.txt \
~/code/notes/code.text \
~/Dropbox_Ingenuity/operations/ingenuity.text \
~/Dropbox_Ingenuity/operations/grand_plan.txt \
~/Dropbox_Ingenuity/operations/BAW_pilot_notes.txt \
~/Dropbox_Ingenuity/operations/project_software.txt"
fi


# Utility function for grep'ing files for TODO items
# This assumes they're formatting like this:
# - TODO this is the item
# I probably need to make it more robust
function td() {
    if test -z $1; then
        # if no arguments
        echo "ERROR: requires argument" >&2
        return 1
    elif test -z $2; then
        # if there's only one argument, this pattern
        grep TODO $1 | sed -E "s/(.+)(TODO +)(.+)/\3/g" | column -t -s :
        return 0
    else
        # if more than one argument, this pattern
        grep TODO $* | sed -E "s/(.+\/)(.+)(\..+)(TODO +)(.+)/\2: \5/g" | column -t -s :
        return 0
    fi
}

alias gtd="eval td $TODOS"

function etd() {
    vim $(eval find $TODOS | fzf)
}

function ltd() {
    td $(eval find $TODOS | fzf)
}


# FZF OPTIONS / FUNCTIONS
# ----------------------------------------------------------------------------

source /usr/local/opt/fzf/shell/completion.zsh
source /usr/local/opt/fzf/shell/key-bindings.zsh
source ~/code/other-repos/fzf-marks/fzf-marks.plugin.zsh

export FZF_DEFAULT_OPTS="--color dark --height 40% --preview 'cat {}'"
export FZF_FS_OPENER=vim
alias ffs='fzf-fs'

# fd - cd to selected directory
fd() {
  DIR=`find ${1:-*} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf-tmux` \
    && cd "$DIR"
}

# fshow - git commit browser
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  local files
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# v - open files in ~/.viminfo
v() {
  local files
  files=$(grep '^>' ~/.viminfo | cut -c3- |
          while read line; do
            [ -f "${line/\~/$HOME}" ] && echo "$line"
          done | fzf-tmux -d -m -q "$*" -1) && vim ${files//\~/$HOME}
}
