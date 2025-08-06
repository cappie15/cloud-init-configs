#!/bin/bash

# Kies een willekeurig woord uit de lijst
WORDS=(atlas echo pixel vortex zephyr shadow tango nova)
RANDOM_NAME=${WORDS[$RANDOM % ${#WORDS[@]}]}

# Zet de hostname
hostnamectl set-hostname "$RANDOM_NAME"
echo "$RANDOM_NAME" > /etc/machine-id-name
echo "$RANDOM_NAME" > /etc/hostname
