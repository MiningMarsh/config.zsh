########
# Path #
########

export PATH="$HOME/.bin:$PATH"

###########
# History #
###########

# Save timestamps and runtimes to the history file.
setopt extendedhistory

# All shells immediatly see new history from other shells.
setopt sharehistory

# Setup zsh to save history from previous sessions.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=SAVEHIST=10000

########
# Wine #
########

export WINEBASE="$HOME/.local/share/wineprefixes"
export WINEPREfix="$WINEBASE/default"

##########
# Editor #
##########

export EDITOR="vim"
