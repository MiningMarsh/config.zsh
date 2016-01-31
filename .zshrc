# This file is sourced by non-interactive and interactive zsh login shells.
# In an interactive shell, this is sourced before .zlogin.

# Init plugins.
source ~/.zsh/init.zsh

if echo "$-" | grep "l" > /dev/null; then
else
    function precmd() {
        print -Pn "\e]2;$USER@%~\a"
        print -Pn "\033]0;$USER@%~\007"
    }

    function preexec() {
        print -Pn "\e]2;$1\a"
        print -Pn "\033]0;$1\007"
    }
fi

################
# Autocomplete #
################

# Autocomplete.
autoload -U compinit promptinit
compinit

# Use an autocomplete cache to speed things up.
zstyle ':completion::completion:*' use-cache 1
zstyle ':completion::complete:*' use-cache 1

# Do completions of thins like partial paths.
setopt completeinword

# Autocomplete entry for killall.
zstyle ':completion:*:killall:*' command 'ps -u $USER -o cmd'

##########
# Colors #
##########

# Load colors.
autoload colors && colors

# Load colors into environment variables.
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='%{$fg_no_bold[${(L)COLOR}]%}'
    eval BOLD_$COLOR='%{$fg_bold[${(L)COLOR}]%}'
done

# $RESET is used to reset colors to their normal value.
eval RESET='$reset_color'

# Ls colors.

eval `dircolors`
alias ls="ls -F --color=auto"

############
# Globbing #
############

# Use extended (better) globbing.
setopt extendedglob

# Ignore case while globbing.
unsetopt caseglob

#######
# Git #
#######

# Git the branch of a path.
function git_branch() {
    git branch 1>/dev/null 2>&1
}

# Get the branch name of a path.
git_branch_name() {
        TARGET="$PWD"
        if git_branch "$TARGET"
        then
                echo "`git rev-parse --abbrev-ref HEAD 2>/dev/null`"
        else
                echo ""
        fi
}

############
# History #
###########

# Save timestamps and runtimes to the history file.
setopt extendedhistory

# All shells immediatly see new history from other shells.
setopt sharehistory

###############
# Compilation #
###############

autoload -U zrecompile

#################
# Word matching #
#################

# We use this to tell zsh what qualifies as a word.
autoload select-word-style

# Shell mode for word detection.
select-word-style shell

#######
# VIM #
#######

# Vim mode.
bindkey -v

##############
# Statistics #
##############

# Auto report program time statistics for programs that take longer than 10 seconds to run.
REPORTTIME=10

##########
# Prompt #
##########

# Setup prompt.
autoload -U promptinit
promptinit

# Extended PS1 and RPS1 substitution.
setopt promptsubst

# Prompt open and close brace.
export PS_OPEN='%b%f%k%B%F{red}['
export PS_CLOSE='%F{red}]%b%f%k'

# A few useful PS shortcuts.
export PS_PWD="$PS_OPEN%B%F{blue}%1~$PS_CLOSE"
export PS_TTY="$PS_OPEN%B%F{yellow}%l$PS_CLOSE"
export PS_USER="$PS_OPEN%B%F{green}%n$PS_CLOSE"
export PS_TIME="$PS_OPEN%B%F{yellow}%T$PS_CLOSE"
export PS_PROMPT="%b%f%B%F{red}%#%b%f%k"

# The string we want printed for normal mode.
export PS_VI_NORMAL="$PS_OPEN%B%F{yellow}NORMAL$PS_CLOSE"
# The string we want printed for insert mode.
export PS_VI_INSERT=""

# Renders the prompt, gets called whenever the keymap changes (i.e. change from
# insert to normal mode, or vice versa), or when the prompt is asked to be
# re-rendered.
function prompt-init {

    # Immediatly grab the return status of the last program the user ran, so
    # that we don't clober it later.
    local ret_status="$?"

    # Holds the tokens to eventually render.
    local tokens

    # Always have username token.
    tokens+=(green:'%n')

    # Always have tty path rendered.
    tokens+=(yellow:'%l')

    # Always render top-level directory.
    tokens+=(blue:'%1~')

    # If a program returned an error code, inform the user
    if [[ "$ret_status" -ne "0" ]]; then
        tokens+=(yellow:"✗: $ret_status")
    fi
    
    # If we are in a git repo, have git branch token.
    if git_branch "$PWD"; then
        tokens+=(white:"$(git_branch_name $PWD)")
    fi

    # If there is any news available, tell the user.
    local news_count="$(cat ~/RAM/.newsd)"
    if [[ "${news_count}" -ne 0 ]]; then
        tokens+=(yellow:"News: ${news_count}")
    fi

    # If dispatch-conf needs to be invoked, tell the user.
    local dispatch_count="$(cat ~/RAM/.dispatch-confd)"
    if [[ "${dispatch_count}" -ne 0 ]]; then
        tokens+=(yellow:"Cfg: ${dispatch_count}")
    fi
        
    # Reset prompt string.
    PS1=""

    # The length of the tokens rendered so far.
    local running_length=0

    # Never render more than 2/3 screen width.
    local top_length=$(( $COLUMNS * 200 / 3 / 100 ))

    # For every token, render the token.
    for i in $tokens; do

	# Extract the color of the token.
    local token_color=$(echo $i | cut -f1 -d:)

	# Extract the content of the token.
    local content=$(echo $i | cut -f2- -d:)

	# Strips color codes from the token content.
    local zero='%([BSUbfksu]|([FB]|){*})'

	# Construct the new token.
    local new_token="$PS_OPEN%B%F{$token_color}$content$PS_CLOSE "

	# Count the width of the new token, ignoring non-rendered characters.
        local length=${#${(S%%)new_token//$~zero/}}

	# If the top-length has not been overrun, render the new token.
        if [[ $(( $running_length + $length )) -lt $top_length ]]; then
            PS1="$PS1$new_token"
            running_length=$(( $running_length + $length ))
        fi
    done

    # Export the new prompts.
    export PS1="$PS1%B%F{red}%#%b%f%k "
    export RPS1="${${KEYMAP/vicmd/$PS_VI_NORMAL}/(main|viins)/$PS_VI_INSERT}"

    # Re-render the new prompt.
	if zle; then
		zle reset-prompt
	fi
}

function zle-line-init {
	auto-fu-init
	prompt-init
}

function zle-keymap-select {
	auto-fu-zle-keymap-select
	prompt-init
}

zstyle ':completion:*' completer _oldlist _complete

zle -N zle-line-init
zle -N zle-keymap-select
prompt-init

# If the window resizes, re-render the prompt.
function TRAPWINCH() {
    zle-line-init
}

#########
# Alias #
#########

alias please='sudo $(fc -ln -1)'

#############
# RAM Setup #
#############

mkdir -p ~/RAM/.desktop
mkdir -p ~/RAM/.downloads

###############
# Autosuggest #
###############

# Use right arrow to trigger autosuggest.
AUTOSUGGESTION_ACCEPT_RIGHT_ARROW=1
