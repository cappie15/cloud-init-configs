#!/bin/bash
set -euo pipefail

# ========== VARIABELEN ==========
HOME_DIR="/home/ben"
LOG_FILE="$HOME_DIR/bootstrap.log"
REPO_USER="cappie15"
REPO_DOTFILES="dotfiles"
WORDS=(atlas echo pixel vortex zephyr shadow tango nova)

# ========== ROOT CHECK ==========
if [[ $EUID -ne 0 ]]; then
  echo "[FOUT] Dit script werkt enkel als root. Gebruik: sudo ./bootstrap.sh"
  exit 1
fi

# ========== LOG FUNCTIE & DEBUG TRAP ==========
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}
trap 'log "[FOUT] Script afgebroken op regel $LINENO met exitcode $?"' ERR
log "[BOOTSTRAP] Script gestart — volledige output zichtbaar op console"

# ========== INSTALLATIE VAN QEMU GUEST AGENT ==========
log "Installatie van qemu-guest-agent"
apt-get update -qq || log "⚠️ apt-get update faalde"
apt-get install -y qemu-guest-agent || log "⚠️ Installatie qemu-guest-agent faalde"
if [ -S /dev/virtio-ports/org.qemu.guest_agent.0 ]; then
  log "virtio socket aanwezig, qemu-guest-agent wordt gestart"
  systemctl start qemu-guest-agent || log "⚠️ Start qemu-guest-agent faalde"
  log "qemu-guest-agent gestart"
else
  log "⚠️ virtio socket ontbreekt, agent niet gestart (reboot mogelijk nodig)"
fi

# ========== INSTALLATIE VAN TAILSCALE ==========
log "Installatie van Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh || log "⚠️ Installatie Tailscale faalde"
systemctl status tailscaled && log "Tailscale draait" || log "⚠️ Tailscale startstatus niet beschikbaar"

# ========== INSTALLATIE VAN OVERIGE PAKKETTEN ==========
log "Installatie van overige pakketten: zsh, nano, btop, tmux, fonts-powerline"
apt-get install -y zsh nano btop tmux fonts-powerline || log "⚠️ Installatie andere pakketten faalde"

# ========== SSH SLEUTELS IMPORTEREN ==========
log "Importeren van publieke SSH-sleutels van GitHub gebruiker: $REPO_USER"
mkdir -p "$HOME_DIR/.ssh"
curl -fsSL "https://github.com/${REPO_USER}.keys" -o "$HOME_DIR/.ssh/authorized_keys" || log "⚠️ Ophalen SSH keys faalde"
chown -R ben:ben "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"
chmod 600 "$HOME_DIR/.ssh/authorized_keys"

# ========== RANDOM HOSTNAME INSTELLEN ==========
log "Instellen van willekeurige hostname"
RANDOM_NAME=${WORDS[$RANDOM % ${#WORDS[@]}]}
hostnamectl set-hostname "$RANDOM_NAME"
echo "$RANDOM_NAME" > /etc/machine-id-name
echo "$RANDOM_NAME" > /etc/hostname
log "Hostname ingesteld op: $RANDOM_NAME"

# ========== INSTALLATIE VAN FONTS ==========
log "Installatie van Meslo Nerd Fonts"
FONT_DIR="$HOME_DIR/.local/share/fonts"
mkdir -p "$FONT_DIR"
curl -fsSL -o "$FONT_DIR/MesloLGLNerdFontMono-Regular.ttf" \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/MesloLGLNerdFontMono-Regular.ttf || log "⚠️ Font download faalde"
# (herhaal voor de bold overige fonts)
fc-cache -fv "$FONT_DIR"

# ========== INSTALLATIE VAN OH MY ZSH ==========
echo ""
echo "[BOOTSTRAP] Installatie van Oh My Zsh..."
echo "--------------------------------------------------------------------------------"
log "Installatie van Oh My Zsh (forced reinstall)"
rm -rf "$HOME_DIR/.oh-my-zsh"
export RUNZSH=no CHSH=no
su - ben -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' || log "⚠️  Oh My Zsh installatie faalde"

# ========== INSTALLATIE VAN POWERLEVEL10K & ZSH PLUGINS ==========
echo ""
echo "[BOOTSTRAP] Installatie van Powerlevel10K & zsh-plugins..."
echo "--------------------------------------------------------------------------------"

ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"

# Powerlevel10k als thema voor Oh My Zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/MohamedElashri/you-should-use "$ZSH_CUSTOM/plugins/you-should-use"

# Eigendom goed zetten
chown -R ben:ben "$ZSH_CUSTOM"

# ========== DOTFILES INSTALLEREN ==========
log "Installatie van dotfiles"
curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/refs/heads/master/.p10k.zsh" -o "$HOME_DIR/.p10k.zsh" || log "⚠️ download .p10k.zsh faalde"
curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/refs/heads/master/.tmux.conf" -o "$HOME_DIR/.tmux.conf" || log "⚠️ download .tmux.conf faalde"
curl -fsSL "https://raw.githubusercontent.com/${REPO_USER}/${REPO_DOTFILES}/refs/heads/master/.zshrc" -o "$HOME_DIR/.zshrc" || log "⚠️ download .zshrc faalde"

# ========== ZSH ALS STANDAARD SHELL INSTELLEN ==========
log "Instellen van zsh als standaard shell voor gebruiker ben"
chsh -s "$(which zsh)" ben || log "⚠️ Wijzigen standaard shell faalde"

# ========== EINDE ==========
log "✅ Bootstrapping voltooid. SSH beschikbaar op IP: $(hostname -I | awk '{print $1}')"
