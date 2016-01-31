#!/bin/zsh
source ~/.zsh/zgen/zgen.zsh
if ! zgen saved; then

	# Fish-like autosuggestions.
	#zgen load zsh-users/zsh-syntax-highlighting
	#zgen load tarruda/zsh-autosuggestions

	# Use auto-fu	
	zgen load hchbaw/auto-fu.zsh

	# Save loaded plugins.
	zgen save
fi
