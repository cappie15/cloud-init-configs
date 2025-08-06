#!/bin/bash
set -euo pipefail

# ========== VARIABELEN ==========
HOME_DIR="/home/ben"
FONT_DIR="$HOME_DIR/.local/share/fonts"
LOG_FILE="$HOME_DIR/bootstrap.log"
REPO_USER="cappie15"
REPO_DOTFILES="dotfiles"
WORDS=(atlas echo pixel vortex zephyr shadow tango nova)

# ========== ROOT CHECK ==========
if [[ $EUID -ne 0 ]]; then
  echo "[FOUT] Dit script werkt enkel als root. Gebruik: sudo ./bootstrap.sh"
  exit 1
fi

# ========== SUCCESVOLLE EXIT => LOG VERWIJDEREN ==========
trap '[ "$?" -eq 0 ] && rm -f "$LOG_FILE"' EXIT

# ========== LOGGING ==========
exec > >(tee "$LOG_FILE") 2>&1
echo ""
echo ""
echo ""
echo "[BOOTSTRAP] Script gestart om $(date)"
echo "[BOOTSTRAP] Logging naar: $LOG_FILE"
echo "--------------------------------------------------------------------------------"

# ========== INSTALLATIE VAN PAKKETTEN ==========
echo ""
echo "[BOOTSTRAP] Installatie van qemu-guest-agent"
echo "--------------------------------------------------------------------------------"
apt-get update -qq
apt install -y qemu-guest-agent 
systemctl enable qemu-guest-agent 
systemctl start qemu-guest-agent 
systemctl status qemu-guest-agent || echo "[INFO] qemu-guest-agent status niet beschikbaar"
if [ ! -S /dev/virtio-ports/org.qemu.guest_agent.0 ]; then
  echo "[WAARSCHUWING] virtio socket mist, reboot noodzakelijk" | tee -a "$LOG_FILE"
fi

echo ""
echo "[BOOTSTRAP] Installatie van tailscale"
echo "--------------------------------------------------------------------------------"
curl -fsSL https://tailscale.com/install.sh | sh 
systemctl status tailscaled || echo "[INFO] Tailscale status niet beschikbaar (nog niet geactiveerd)"

echo ""
echo "[BOOTSTRAP] Installatie van overige pakketten..."
echo "--------------------------------------------------------------------------------"
apt-get install -y zsh nano btop tmux fonts-powerline 

# ========== SSH SLEUTELS IMPORTEREN ==========
echo ""
echo "[BOOTSTRAP] Importeren van publieke sleutels van GitHub gebruiker: $REPO_USER"
echo "--------------------------------------------------------------------------------"
mkdir -p "$HOME_DIR/.ssh"
curl -fsSL "https://github.com/${REPO_USER}.keys" -o "$HOME_DIR/.ssh/authorized_keys"
chown -R ben:ben "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"
chmod 600 "$HOME_DIR/.ssh/authorized_keys"

# ========== RANDOM HOSTNAME INSTELLEN ==========
echo ""
echo "[BOOTSTRAP] Instellen van willekeurige hostname..."
echo "--------------------------------------------------------------------------------"
RANDOM_NAME=${WORDS[$RANDOM % ${#WORDS[@]}]}
hostnamectl set-hostname "$RANDOM_NAME"
echo "$RANDOM_NAME" > /etc/machine-id-name
echo "$RANDOM_NAME" > /etc/hostname
echo "Hostname ingesteld op: $RANDOM_NAME" 

# ========== INSTALLATIE VAN FONTS ==========
echo ""
echo "[BOOTSTRAP] Installatie van Meslo Nerd Fonts..."
echo "--------------------------------------------------------------------------------"
mkdir -p "$FONT_DIR"
# MesloLGL Nerd Font Mono (Regular & Bold)
curl -fsSL -o "$FONT_DIR/MesloLGLNerdFontMono-Regular.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGLNerdFontMono-Regular.ttf
curl -fsSL -o "$FONT_DIR/MesloLGLNerdFontMono-Bold.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Bold/MesloLGLNerdFontMono-Bold.ttf
# MesloLGL Nerd Font Propo (Regular & Bold)
curl -fsSL -o "$FONT_DIR/MesloLGLNerdFontPropo-Regular.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGLNerdFontPropo-Regular.ttf
curl -fsSL -o "$FONT_DIR/MesloLGLNerdFontPropo-Bold.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Bold/MesloLGLNerdFontPropo-Bold.ttf
# Cache opnieuw opbouwen
fc-cache -fv "$FONT_DIR"

# ========== POWERLEVEL10K INSTALLEREN ==========
echo ""
echo "[BOOTSTRAP] Installatie van Powerlevel10K"
echo "--------------------------------------------------------------------------------"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME_DIR/powerlevel10k"
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$HOME_DIR/.zshrc"
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME_DIR/.zshrc"
chown -R ben:ben "$HOME_DIR"

# ========== DOTFILES INSTALLEREN ==========
echo ""
echo "[BOOTSTRAP] Installatie van dotfiles..."
echo "--------------------------------------------------------------------------------"
curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/heads/master/.p10k.zsh" \
  -o "$HOME_DIR/.p10k.zsh"
curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/heads/master/.tmux.conf" \
  -o "$HOME_DIR/.tmux.conf"
  curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/heads/master/.zshrc" \
  -o "$HOME_DIR/.zshrc"

# ========== EINDE EN IP-WEERGAVE ==========
INTERNAL_IP=$(hostname -I | awk '{print $1}')
echo ""
echo ""
echo ""
echo ""
echo "[BOOTSTRAP] ✅ Voltooid. SSH beschikbaar op IP: $INTERNAL_IP"
