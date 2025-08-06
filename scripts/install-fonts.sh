#!/bin/bash

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Download Meslo Nerd Font (gebruik bijvoorbeeld 2 varianten)
curl -fsSL -o "$FONT_DIR/MesloLGS-NF-Regular.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGS%20NF%20Regular.ttf
curl -fsSL -o "$FONT_DIR/MesloLGS-NF-Bold.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Bold/MesloLGS%20NF%20Bold.ttf

# Herbouw font-cache
fc-cache -fv "$FONT_DIR"
