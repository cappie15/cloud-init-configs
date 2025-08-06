#!/bin/bash

# Dotfiles downloaden van GitHub repo
REPO_USER="cappie15"
REPO_NAME="dotfiles"
BRANCH="main"
HOME_DIR="/home/ben"

# Config-bestanden ophalen
curl -fsSL https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH/.p10k.zsh -o $HOME_DIR/.p10k.zsh
curl -fsSL https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH/.tmux.conf -o $HOME_DIR/.tmux.conf

# Powerlevel10k installeren
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME_DIR/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> $HOME_DIR/.zshrc
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> $HOME_DIR/.zshrc

chown -R ben:ben $HOME_DIR
