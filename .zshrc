# This file is sourced by non-interactive and interactive zsh login shells.
# In an interactive shell, this is sourced before .zlogin.

# Init plugins.
source ~/.zsh/init.zsh

# Stores the last PWD so that on PWD change we can LS new directory.
local zshrc_last_pwd="$PWD"

local function zshrc/status() {
	local msg="$@"
	if [[ -z "$EMACS" ]]; then
	    echo -e ' \e[32m*\e[0m '"$msg"
	fi
}

# Only setup terminal title hooks if we are actually running in an interactive
# session.
if ! {echo "$-" | grep "l" > /dev/null}; then

	# Function that prints something in the terminal title.
	local function zshrc/terminal-title-print() {
	    if [[ -z "$EMACS" ]]; then
		print -Pn "\e]2;$@\a"
		print -Pn "\033]0;$@\007"
	    fi
	}

	# Every time the prompt is rendered, diplsay user@directory in the terminal
	# title for terminals that obey the correct VT100 escape code.
	function precmd() {
		zshrc/terminal-title-print "$USER@%~"
	}

	# Every time a command is run, print that command in the terminal title for
	# terminals that obey the correct VT100 escape code.
	function preexec() {

		# The second argument zsh provides is a stripped down version of the full
		# command run.
		zshrc/terminal-title-print "$USER@%~: $2"
	}
fi

################
# Autocomplete #
################

# Setup autocomplete.
autoload -U compinit promptinit
compinit

# Autocomplete entry for killall.
zstyle ':completion:*:killall:*' command 'ps -u $USER -o cmd'

# Do completions of things like partial paths.
setopt completeinword

# Use an autocomplete cache to speed things up.
zstyle ':completion:*' use-cache on

##########
# Colors #
##########

# Load colors.
autoload colors && colors

# Load colors codes into environment variables.
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='%{$fg_no_bold[${(L)COLOR}]%}'
    eval BOLD_$COLOR='%{$fg_bold[${(L)COLOR}]%}'
done

# $RESET is used to reset colors to their normal value.
eval RESET='$reset_color'

# Ls colors.

eval `dircolors`
alias ls="ls --color=auto"

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
local function zshrc/git-branch() {
    git branch 1>/dev/null 2>&1
}

# Get the branch name of a path.
local function zshrc/git-branch-name() {
        local target="$PWD"
        if zshrc/git-branch "$target"
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

# Compile things automatically.
autoload -U zrecompile

# Automatically recompile the compdump, zshrc, and our zgen plugins file if
# needed. This also compiles zgen itself.
zrecompile -qp \
           -R ~/.zshrc -- \
           -R ~/.zsh/init.zsh -- \
           -R ~/.zsh/zgen/zgen.zsh -- \
           -M ~/.zcompdump --

# Recompile everything else if needed.
zrecompile -q

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
local zshrc_ps_open='%b%k%F{red}[%f'
local zshrc_ps_close='%b%k%F{red}]%f'

# The string we want printed for normal mode.
local zshrc_ps_vi_normal="${zshrc_ps_open}%B%F{yellow}NORMAL${zshrc_ps_close}"

# The string we want printed for insert mode.
local zshrc_ps_vi_insert=""

# Renders the prompt, gets called whenever the keymap changes (i.e. change from
# insert to normal mode, or vice versa), or when the prompt is asked to be
# re-rendered. This is also called when zle re-renders a line.
function prompt-init {

    # Immediatly grab the return status of the last program the user ran, so
    # that we don't clobber it later.
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
        tokens+=(yellow:"✗ $ret_status")
    fi

    # If we are in a git repo, have git branch token.
    if zshrc/git-branch "$PWD"; then
        tokens+=(white:"$(zshrc/git-branch-name $PWD)")
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
        local new_token="${zshrc_ps_open}%b%F{${token_color}}${content}${zshrc_ps_close} "

        # Count the width of the new token, ignoring non-rendered characters.
        local length=${#${(S%%)new_token//$~zero/}}

        # If the top-length has not been overrun, render the new token.
        if [[ $(( $running_length + $length )) -lt $top_length ]]; then
            PS1="$PS1$new_token"
            running_length=$(( $running_length + $length ))
        fi
    done

    # Export the new prompts.
	export PS1="$PS1%k%b%F{red}%#%f "
	export RPS1="${${KEYMAP/vicmd/$zshrc_ps_vi_normal}/(main|viins)/$zshrc_ps_vi_insert}"

    # Re-render the new prompt if zle is loaded.
	if zle; then
		zle reset-prompt
	fi
}

# Re-render the prompt everytime the line re-renders.
function zle-line-init {
	prompt-init
}

# Reset the prompt every time the keymap changes. This is needed so that
# the [NORMAL] mode prompt appears on normal mode.
function zle-keymap-select {
	prompt-init
}

# Setup the ZLE line rendering system.
zle -N zle-line-init

# Setup the ZLE keymap system.
zle -N zle-keymap-select

# Initialize the prompt on first run.
prompt-init

# Re-render the prompt half a second after the terminal is resized.
function TRAPWINCH() {

	# ZSH restarts the TRAPWINCH every time a restart occurs, so this is as easy
	# as just sticking the wait here.
	sleep 0.5

	# Restart zle rendering.
	zle-line-init
}

#########
# Alias #
#########

alias please='sudo $(fc -ln -1)'

#source ~/Sources/go/bin/activate
