########
# Path #
########

export PATH="$HOME/.bin:$PATH:$HOME/.bin"

###########
# History #
###########

# Setup zsh to save history from previous sessions.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=SAVEHIST=10000

########
# Wine #
########

export WINEBASE="$HOME/.local/share/wineprefixes"
export WINEPREFIX="$WINEBASE/default"

##########
# Editor #
##########

export EDITOR="emacs"
