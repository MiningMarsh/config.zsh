#!/bin/zsh
source ~/.zsh/zgen/zgen.zsh
if ! zgen saved; then

	# Enable this because why not?
	zsh oh-my-zsh

   # Fish-like autosuggestions.
   zgen load zsh-users/zsh-syntax-highlighting
   zgen load tarruda/zsh-autosuggestions

   # Save loaded plugins.
   zgen save
fi
