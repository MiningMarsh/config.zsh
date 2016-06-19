#!/bin/zsh
source ~/.zsh/zgen/zgen.zsh
if ! zgen saved; then

	# Fish-like autosuggestions.
	zgen load zsh-users/zsh-syntax-highlighting
	zgen load tarruda/zsh-autosuggestions

	# Save loaded plugins.
	zgen save
fi
