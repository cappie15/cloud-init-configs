#!/bin/bash

# Fail fast
set -e

echo "[BOOTSTRAP] Start executing bootstrap.sh from GitHub..."

# Zet log op stdout
exec > >(tee /var/log/bootstrap.log) 2>&1

# Scripts ophalen en uitvoeren
for script in install-dotfiles.sh install-fonts.sh install-tailscale.sh random-hostname.sh; do
  echo "[BOOTSTRAP] Executing $script"
  curl -fsSL "https://raw.githubusercontent.com/cappie15/cloud-init-configs/main/scripts/$script" | bash
done
