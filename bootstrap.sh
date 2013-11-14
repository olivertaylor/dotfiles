#!/bin/zsh

# Use this script to setup a new mac with your dot-files
# ensure you run it from $HOME, and be very careful with your data

# Ask for the administrator password upfront
sudo -v

ln -s ~/code/dotfiles/git/gitconfig .gitconfig
ln -s ~/code/dotfiles/git/gitignore_global .gitignore_global

ln -s ~/code/dotfiles/zsh .zsh
ln -s ~/.zsh/zshrc .zshrc

ln -s ~/code/dotfiles/vim .vim
ln -s ~/.vim/vimrc .vimrc

ln -s ~/code/dotfiles/slate .slate
ln -s ~/code/dotfiles/KeyRemap4MacBook ~/Library/Application\ Support/KeyRemap4MacBook



# A few personal preferences...
# Stolen from: https://github.com/mathiasbynens/dotfiles

# set default shell
chsh -s /opt/local/bin/zsh

# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
