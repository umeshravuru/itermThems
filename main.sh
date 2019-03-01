#!/bin/bash

unset isFound

echo "Starting the script"

echo "Checking if brew is installed?"

isFound=`which brew`

if [ ${#isFound} -gt 2 ]; then
	echo "Brew already installed, skipping instalation......"
else 
	echo "Brew not installed. Insatlling brew....."
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	echo "Done installing brew"
fi


echo "Checking if iterm2 is installed?"

isItemInstalle=`echo $TERM_PROGRAM`


if [ ${#isItemInstalle} -gt 2 ]; then
	echo "iterm2 already installed, skipping instalation......"
else 
	echo "iterm2 not installed. Insatlling iterm2....."
	brew cask install iterm2
	echo "Done installing iterm2"
fi

ehco "Installing ZSH.."
brew install zsh zsh-completions
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
ehco "Done Installing ZSH."

cp com.googlecode.iterm2.plist ~/Library/Preferences/


