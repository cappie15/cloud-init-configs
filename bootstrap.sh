#!/bin/bash
set -euo pipefail

# ========== VARIABELEN ==========
HOME_DIR="/home/ben"
FONT_DIR="$HOME_DIR/.local/share/fonts"
LOG_FILE="$HOME_DIR/bootstrap.log"
REPO_USER="cappie15"
REPO_DOTFILES="dotfiles"
REPO_BRANCH="main"
WORDS=(atlas echo pixel vortex zephyr shadow tango nova)

# ========== ROOT CHECK ==========
if [[ $EUID -ne 0 ]]; then
  echo "[FOUT] Dit script werkt enkel als root. Gebruik: sudo ./bootstrap.sh"
  exit 1
fi

# ========== LOGGING ==========
exec > >(tee "$LOG_FILE") 2>&1

echo "[BOOTSTRAP] Script gestart om $(date)"
echo "[BOOTSTRAP] Logging naar: $LOG_FILE"

# ========== INSTALLATIE VAN PAKKETTEN ==========
echo "[BOOTSTRAP] Installatie van pakketten..."
apt-get update
apt-get install -y zsh nano btop fastfetch tmux fonts-powerline tailscale qemu-guest-agent

# ========== SSH SLEUTELS IMPORTEREN ==========
echo "[BOOTSTRAP] Importeren van publieke sleutels van GitHub gebruiker: $REPO_USER"
mkdir -p "$HOME_DIR/.ssh"
curl -fsSL "https://github.com/${REPO_USER}.keys" -o "$HOME_DIR/.ssh/authorized_keys"
chown -R ben:ben "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"
chmod 600 "$HOME_DIR/.ssh/authorized_keys"

# ========== RANDOM HOSTNAME INSTELLEN ==========
echo "[BOOTSTRAP] Instellen van willekeurige hostname..."
RANDOM_NAME=${WORDS[$RANDOM % ${#WORDS[@]}]}
hostnamectl set-hostname "$RANDOM_NAME"
echo "$RANDOM_NAME" > /etc/machine-id-name
echo "$RANDOM_NAME" > /etc/hostname

# ========== INSTALLATIE VAN FONTS ==========
echo "[BOOTSTRAP] Installatie van Meslo Nerd Fonts..."
mkdir -p "$FONT_DIR"
curl -fsSL -o "$FONT_DIR/MesloLGS-NF-Regular.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGS%20NF%20Regular.ttf
curl -fsSL -o "$FONT_DIR/MesloLGS-NF-Bold.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Bold/MesloLGS%20NF%20Bold.ttf
fc-cache -fv "$FONT_DIR"

# ========== DOTFILES INSTALLEREN ==========
echo "[BOOTSTRAP] Installatie van dotfiles..."
curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/${REPO_BRANCH}/.p10k.zsh" \
  -o "$HOME_DIR/.p10k.zsh"
curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/${REPO_BRANCH}/.tmux.conf" \
  -o "$HOME_DIR/.tmux.conf"

# Powerlevel10k installeren
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME_DIR/powerlevel10k"
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$HOME_DIR/.zshrc"
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME_DIR/.zshrc"

chown -R ben:ben "$HOME_DIR"

# ========== EINDE EN OPRUIMING ==========
INTERNAL_IP=$(hostname -I | awk '{print $1}')
echo ""
echo ""
echo ""
echo ""
echo "[BOOTSTRAP] ✅ Voltooid. SSH beschikbaar op IP: $INTERNAL_IP"

# Loggingbestand verwijderen bij succes
rm -f "$LOG_FILE"
