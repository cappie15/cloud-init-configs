#!/bin/bash

# Installeer Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Verbind met netwerk (vervang deze key!)
tailscale up --authkey=tskey-REPLACE_THIS --hostname=$(hostname)
