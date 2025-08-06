#!/bin/bash

# Fail fast
set -euo pipefail

# Vereist: TAILSCALE_AUTHKEY als env variabele
if [[ -z "${TAILSCALE_AUTHKEY:-}" ]]; then
  echo "ERROR: TAILSCALE_AUTHKEY is not set. Refusing to continue."
  exit 1
fi

# Installatie
curl -fsSL https://tailscale.com/install.sh | sh

# Connect
tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="$(hostname)"
